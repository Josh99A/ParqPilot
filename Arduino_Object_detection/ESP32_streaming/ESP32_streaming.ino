#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <FirebaseClient.h>
#include <WebServer.h>
#include <WiFi.h>
#include <esp32cam.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include "ExampleFunctions.h"

#define API_KEY "AIzaSyC4kwGCyoVorFYgMPW_22cZ7koZbn4oq2k"
#define USER_EMAIL "awulejoshua823@gmail.com"
#define USER_PASSWORD "awule12345"
#define DATABASE_URL "https://parqpilot-2c029-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define SLOT_NAME "SlotA1"

const double LOT_LAT=0.3316;
const double LOT_LONG=32.5705;


void processData(AsyncResult &aResult);
void push_async(String slotStatus);
void updateParkingState(String status); // Added missing function declaration

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000);

SSL_CLIENT ssl_client;

using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);

UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD, 3000);
FirebaseApp app;
RealtimeDatabase Database;
AsyncResult databaseResult;

bool taskComplete = false;
float distance_cm = 0; // Global variable for distance

// State management variables
String currentParkingStatus = "Free";
const float DETECTION_THRESHOLD = 50.0; // cm - distance threshold for vehicle detection

// Missing timing and stability variables
const unsigned long SENSOR_READ_INTERVAL = 1000; // Read sensor every 1 second
const int STABLE_READINGS = 3; // Number of consistent readings needed
unsigned long lastSensorRead = 0;
int currentReadings = 0;
bool currentVehicleState = false;
bool previousVehicleState = false;

// Wi-Fi credentials
const char* WIFI_SSID = "DomainExpansion";
const char* WIFI_PASS = "joshua823@Whyfi";

// Pin configuration
const int echopin = 12;
const int trigpin = 13;
const int redLed = 14;
const int greenLed = 15;

WebServer server(80);

// Resolution settings
static auto loRes = esp32cam::Resolution::find(320, 240);
static auto midRes = esp32cam::Resolution::find(350, 530);
static auto hiRes = esp32cam::Resolution::find(800, 600);

void serveJpg() {
  auto frame = esp32cam::capture();
  if (frame == nullptr) {
    Serial.println("CAPTURE FAIL");
    server.send(503, "", "");
    return;
  }

  server.setContentLength(frame->size());
  server.send(200, "image/jpeg");
  WiFiClient client = server.client();
  frame->writeTo(client);
}

void handleJpgLo() {
  if (!esp32cam::Camera.changeResolution(loRes)) {
    Serial.println("SET-LO-RES FAIL");
  }
  serveJpg();
}

void handleJpgMid() {
  if (!esp32cam::Camera.changeResolution(midRes)) {
    Serial.println("SET-MID-RES FAIL");
  }
  serveJpg();
}

void handleJpgHi() {
  if (!esp32cam::Camera.changeResolution(hiRes)) {
    Serial.println("SET-HI-RES FAIL");
  }
  serveJpg();
}

void display_distance(){
  Serial.print("Distance: ");
  Serial.print(distance_cm);
  Serial.println("cm");
}

float measureDistance() {
  digitalWrite(trigpin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigpin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigpin, LOW);

  long duration = pulseIn(echopin, HIGH, 30000); // 30ms timeout
  if (duration == 0) {
    return -1; // Timeout occurred
  }
  return 0.0343 * duration / 2;
}

void updateLEDs(bool vehiclePresent) {
  if (vehiclePresent) {
    digitalWrite(redLed, HIGH);
    digitalWrite(greenLed, LOW);
  } else {
    digitalWrite(redLed, LOW);
    digitalWrite(greenLed, HIGH);
  }
}

// Missing function definition
void updateParkingState(String status) {
  currentParkingStatus = status;
  bool vehiclePresent = (status == "Occupied");
  updateLEDs(vehiclePresent);
  
  // Update Firebase
  if (app.ready()) {
    push_async(status);
  }
  
  Serial.printf("[INFO] Parking state updated to: %s\n", status.c_str());
}

String getISOTime() {
  time_t rawTime = timeClient.getEpochTime();
  struct tm *ptm = gmtime(&rawTime);
  char buffer[25];
  sprintf(buffer, "%04d-%02d-%02dT%02d:%02d:%02dZ",
          ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday,
          ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
  return String(buffer);
}

void checkParkingStatus() {
  unsigned long currentTime = millis();
  
  // Only read sensor at specified intervals
  if (currentTime - lastSensorRead < SENSOR_READ_INTERVAL) {
    return;
  }
  
  lastSensorRead = currentTime;
  distance_cm = measureDistance();
  
  // Skip if sensor reading failed
  if (distance_cm < 0) {
    Serial.println("[WARNING] Sensor reading failed");
    return;
  }
  
  // Determine if vehicle is present based on distance
  bool vehicleDetected = (distance_cm > 0 && distance_cm < DETECTION_THRESHOLD);
  
  // Check if this reading matches the current state
  if (vehicleDetected == currentVehicleState) {
    currentReadings++;
  } else {
    // State changed, reset counter
    currentVehicleState = vehicleDetected;
    currentReadings = 1;
  }
  
  // Only update system state if we have enough stable readings
  if (currentReadings >= STABLE_READINGS && currentVehicleState != previousVehicleState) {
    previousVehicleState = currentVehicleState;
    
    if (currentVehicleState) {
      // Vehicle detected
      Serial.printf("[INFO] Vehicle detected at %.1fcm - Parking spot OCCUPIED\n", distance_cm);
      currentParkingStatus = "Occupied";
      updateLEDs(true);
      
      // Update Firebase
      if (app.ready()) {
        push_async("Occupied");
      }
    } else {
      // Vehicle left
      Serial.printf("[INFO] Vehicle left (%.1fcm) - Parking spot FREE\n", distance_cm);
      currentParkingStatus = "Free";
      updateLEDs(false);
      
      // Update Firebase
      if (app.ready()) {
        push_async("Free");
      }
    }
  }
  
  // Debug output every 10 readings
  static int debugCounter = 0;
  debugCounter++;
  if (debugCounter >= 10) {
    Serial.printf("[DEBUG] Distance: %.1fcm, Status: %s, Readings: %d/%d\n", 
                  distance_cm, currentParkingStatus.c_str(), currentReadings, STABLE_READINGS);
    debugCounter = 0;
  }
}

// Manual trigger endpoints for vehicle detection
void handleVehicleDetected() {
  Serial.println("[INFO] Vehicle detection endpoint triggered");
  
  // Measure distance to confirm vehicle presence
  distance_cm = measureDistance();
  
  if (distance_cm < 0) {
    Serial.println("[WARNING] Sensor reading failed");
    server.send(500, "text/plain", "Sensor reading failed");
    return;
  }
  
  Serial.printf("[INFO] Distance measured: %.1fcm\n", distance_cm);
  
  if (distance_cm > 0 && distance_cm < DETECTION_THRESHOLD) {
    Serial.printf("[INFO] Vehicle confirmed within range (%.1fcm) - Parking spot OCCUPIED\n", distance_cm);
    updateParkingState("Occupied");
    server.send(200, "text/plain", "Vehicle detected - Parking spot now OCCUPIED");
  } else {
    Serial.printf("[INFO] No vehicle within parking range (%.1fcm)\n", distance_cm);
    updateParkingState("Free");
    server.send(200, "text/plain", "No vehicle detected within range - Parking spot remains FREE");
  }
}

void handleVehicleLeft() {
  Serial.println("[INFO] Vehicle exit endpoint triggered");
  
  // Measure distance to confirm vehicle has left
  distance_cm = measureDistance();
  
  if (distance_cm < 0) {
    Serial.println("[WARNING] Sensor reading failed");
    server.send(500, "text/plain", "Sensor reading failed");
    return;
  }
  
  Serial.printf("[INFO] Distance measured: %.1fcm\n", distance_cm);
  
  // Vehicle has left - update to Free regardless of distance
  // (assuming the trigger is reliable)
  Serial.println("[INFO] Vehicle exit confirmed - Parking spot FREE");
  updateParkingState("Free");
  
  server.send(200, "text/plain", "Vehicle exit processed - Parking spot now FREE");
}

// Endpoint to get current parking status
void handleGetStatus() {
  // Get current distance reading
  float currentDistance = measureDistance();
  if (currentDistance >= 0) {
    distance_cm = currentDistance;
  }
  
  String response = "{";
  response += "\"status\":\"" + currentParkingStatus + "\",";
  response += "\"distance\":" + String(distance_cm) + ",";
  response += "\"lastUpdated\":\"" + getISOTime() + "\",";
  response += "\"threshold\":" + String(DETECTION_THRESHOLD);
  response += "}";
  
  server.send(200, "application/json", response);
}

void setup() {
  Serial.begin(115200);
  pinMode(trigpin, OUTPUT);
  pinMode(echopin, INPUT);
  pinMode(redLed, OUTPUT);
  pinMode(greenLed, OUTPUT);

  // Initialize parking as free
  digitalWrite(greenLed, HIGH);
  digitalWrite(redLed, LOW);
  currentParkingStatus = "Free";

  Firebase.printf("Firebase Client v%s\n", FIREBASE_CLIENT_VERSION);
  set_ssl_client_insecure_and_buffer(ssl_client);

  Serial.println("Initializing app...");
  initializeApp(aClient, app, getAuth(user_auth), auth_debug_print, "🔐 authTask");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  // Camera init
  {
    using namespace esp32cam;
    Config cfg;
    cfg.setPins(pins::AiThinker);
    cfg.setResolution(hiRes);
    cfg.setBufferCount(2);
    cfg.setJpeg(80);
    bool ok = Camera.begin(cfg);
    Serial.println(ok ? "CAMERA OK" : "CAMERA FAIL");
  }

  // Wi-Fi
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected!");
  Serial.print("ESP32 IP Address: http://");
  Serial.println(WiFi.localIP());
  Serial.println("Available endpoints:");
  Serial.println("  /cam-lo.jpg");
  Serial.println("  /cam-mid.jpg");
  Serial.println("  /cam-hi.jpg");
  Serial.println("  /vehicle_detected - Trigger when vehicle enters parking zone");
  Serial.println("  /vehicle_left - Trigger when vehicle leaves parking zone");
  Serial.println("  /status - Get current parking status");
  Serial.println("");
  Serial.println("🚗 Manual trigger system active...");
  Serial.printf("   Detection threshold: %.1fcm\n", DETECTION_THRESHOLD);
  Serial.printf("   Current status: %s\n", currentParkingStatus.c_str());

  // Route endpoints
  server.on("/cam-lo.jpg", handleJpgLo);
  server.on("/cam-mid.jpg", handleJpgMid);
  server.on("/cam-hi.jpg", handleJpgHi);
  server.on("/vehicle_detected", handleVehicleDetected);
  server.on("/vehicle_left", handleVehicleLeft);
  server.on("/status", handleGetStatus);

  timeClient.begin();
  while (!timeClient.update()) {
    timeClient.forceUpdate();
  }

  server.begin();
}

void loop() {
  app.loop();

  if (app.ready() && !taskComplete) {
    taskComplete = true;
    Serial.println("🚗 Firebase ready for parking updates");
    // Push initial status to Firebase
    push_async(currentParkingStatus);
  }

  // Check parking status automatically
  // checkParkingStatus();

  server.handleClient();
}

void processData(AsyncResult &aResult) {
  if (!aResult.isResult())
    return;

  Serial.printf("=== Firebase Response Debug ===\n");
  Serial.printf("Task UID: %s\n", aResult.uid().c_str());

  if (aResult.isEvent()) {
    Firebase.printf("Event task: %s, msg: %s, code: %d\n", 
                   aResult.uid().c_str(), 
                   aResult.eventLog().message().c_str(), 
                   aResult.eventLog().code());
  }

  if (aResult.isDebug()) {
    Firebase.printf("Debug task: %s, msg: %s\n", 
                   aResult.uid().c_str(), 
                   aResult.debug().c_str());
  }

  if (aResult.isError()) {
    Firebase.printf("❌ Error task: %s, msg: %s, code: %d\n", 
                   aResult.uid().c_str(), 
                   aResult.error().message().c_str(), 
                   aResult.error().code());
  }

  if (aResult.available()) {
    if (aResult.to<RealtimeDatabaseResult>().name().length()) {
      Firebase.printf("✅ Success - task: %s, name: %s\n", 
                     aResult.uid().c_str(), 
                     aResult.to<RealtimeDatabaseResult>().name().c_str());
    }
    Firebase.printf("📄 Response payload: %s\n", aResult.c_str());
  }
  Serial.println("================================");
}

void push_async(String slotStatus) {
  
  timeClient.update();
  String timeStamp = getISOTime();
  
  JsonWriter writer;
  object_t loclat, loclong, location, location_info, slot_status, slot_last_updated, slot_info, lot_info, lotData;

  // Step 1: Create location object
  // This creates: {"lat": 0.3156, "lng": 32.5825}
  writer.create(loclat, "lat", number_t(LOT_LAT));
  writer.create(loclong, "lng", number_t(LOT_LONG));
  writer.join(location_info, 2, loclat, loclong);
  writer.create(location, "location", location_info );


  // Step 2: Create SlotA1 object  
  // This creates: {"status": "Free", "lastUpdated": "2025-07-23T20:32:28Z"}
  writer.create(slot_status, "status", string_t(slotStatus.c_str()));  // .c_str() is important!
  writer.create(slot_last_updated, "lastUpdated", string_t(timeStamp.c_str()));
  writer.join(slot_info,2,slot_last_updated, slot_status);




  // Step 4: Combine everything into lotData
  // This creates the nested structure:
  // {
  //   "location": {"lat": 0.3156, "lng": 32.5825},
  //   "SlotA1": {"status": "Free", "lastUpdated": "2025-07-23T20:32:28Z"},
  // }
  
  writer.create(lot_info,SLOT_NAME , slot_info);
  writer.join(lotData, 2, lot_info, location);


  Database.set<object_t>(aClient, "/MakerereCocisParking_lot", lotData, processData, "pushParkingData");
}
