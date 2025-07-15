#include <WebServer.h>
#include <WiFi.h>
#include <esp32cam.h>

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

// Helper to capture and serve image
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

// JPEG Endpoints
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



// ✅ When vehicle is detected
void handleVehicleDetected() {
  long duration;
  float distance_cm;

  digitalWrite(trigpin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigpin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigpin, LOW);

  duration = pulseIn(echopin, HIGH);
  distance_cm = 0.0343 * duration / 2;

  

  if (distance_cm > 0 && distance_cm < 50) {
    digitalWrite(redLed, HIGH);      // RED = Occupied
    digitalWrite(greenLed, LOW);
    Serial.println("[INFO] Vehicle is parked within range.");
  } else {
    digitalWrite(redLed, LOW);
    digitalWrite(greenLed, HIGH);    // GREEN = No car
    Serial.println("[INFO] Vehicle not within parking range.");
  }

  server.send(200, "text/plain", "Vehicle detection received");
}

// ✅ When vehicle leaves the zone
void handleVehicleLeft() {
  digitalWrite(redLed, LOW);
  digitalWrite(greenLed, HIGH);  // Green ON = spot is now free
  Serial.println("[INFO] Vehicle has left the parking zone.");

  server.send(200, "text/plain", "Vehicle exit received");
}

void setup() {
  Serial.begin(115200);
  pinMode(trigpin, OUTPUT);
  pinMode(echopin, INPUT);
  pinMode(redLed, OUTPUT);
  pinMode(greenLed, OUTPUT);

  digitalWrite(greenLed, HIGH);  // Initially parking is free

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
  Serial.println("  /vehicle_detected");
  Serial.println("  /vehicle_left");

  // Route endpoints
  server.on("/cam-lo.jpg", handleJpgLo);
  server.on("/cam-mid.jpg", handleJpgMid);
  server.on("/cam-hi.jpg", handleJpgHi);
  server.on("/vehicle_detected", handleVehicleDetected);
  server.on("/vehicle_left", handleVehicleLeft); 

  server.begin();
}

void loop() {
  server.handleClient();
}
