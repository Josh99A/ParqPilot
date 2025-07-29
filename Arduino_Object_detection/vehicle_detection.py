import cv2
import numpy as np
import urllib.request
import requests
import time
import socket

# Change this to your ESP32's actual IP address
endpoint = "http://10.89.225.140"  # Replace with your ESP32's IP

# ------------------ YOLOv3 CONFIGURATION ------------------
modelConfig = 'yolov3.cfg'              # Use 'yolov3-tiny.cfg' if using tiny version
modelWeights = 'yolov3.weights'         # Use 'yolov3-tiny.weights' for tiny
classesfile = 'coco.names'
classNames = []

# Load class names
try:
    with open(classesfile, 'rt') as f:
        classNames = f.read().rstrip('\n').split('\n')
    print(f"[INFO] Loaded {len(classNames)} class names")
except FileNotFoundError:
    print("[ERROR] coco.names file not found. Please download YOLO files.")
    exit()

# Choose COCO class IDs for vehicles
try:
    carClassId = classNames.index('car')
    motorcycleClassId = classNames.index('motorbike')
    truckClassId = classNames.index('truck')
    busClassId = classNames.index('bus')
    print(f"[INFO] Vehicle class IDs: car={carClassId}, motorbike={motorcycleClassId}, truck={truckClassId}, bus={busClassId}")
except ValueError as e:
    print(f"[ERROR] Could not find vehicle classes: {e}")
    exit()

# ------------------ CAMERA AND ESP32 SETUP ------------------
camera_url = f'{endpoint}/cam-mid.jpg'
esp32_enter_endpoint = f'{endpoint}/vehicle_detected'
esp32_leave_endpoint = f'{endpoint}/vehicle_left'
esp32_status_endpoint = f'{endpoint}/status'

# ------------------ YOLO NETWORK INITIALIZATION ------------------
whT = 320
confThreshold = 0.5
nmsThreshold = 0.3

try:
    net = cv2.dnn.readNetFromDarknet(modelConfig, modelWeights)
    net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
    net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
    print("[INFO] YOLOv3 network loaded successfully")
except Exception as e:
    print(f"[ERROR] Could not load YOLO network: {e}")
    print("Please ensure yolov3.cfg and yolov3.weights are in the same directory")
    exit()

# ------------------ PARKING LOGIC STATE ------------------
vehicle_detected = False
vehicle_present_last_frame = False
cooldown_seconds = 5
last_detected_time = 0
esp32_connected = False

# ------------------ VIRTUAL ZONE COORDINATES ------------------
line1_x = 200
line2_x = 600

# ------------------ CONNECTION TEST ------------------
def test_esp32_connection():
    """Test if ESP32 is reachable"""
    try:
        # Extract IP from endpoint
        ip = endpoint.replace('http://', '').split(':')[0]
        
        # Test socket connection
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        result = sock.connect_ex((ip, 80))
        sock.close()
        
        if result == 0:
            print(f"[INFO] ESP32 is reachable at {ip}")
            return True
        else:
            print(f"[ERROR] Cannot reach ESP32 at {ip}")
            return False
    except Exception as e:
        print(f"[ERROR] Connection test failed: {e}")
        return False

# ------------------ SEND REQUEST TO ESP32 ------------------
def send_to_esp32(endpoint_url):
    """Send HTTP request to ESP32 with better error handling"""
    global esp32_connected
    
    try:
        print(f"[INFO] Sending request to {endpoint_url}")
        response = requests.get(endpoint_url, timeout=5)
        
        if response.status_code == 200:
            print(f"[ESP32 Response] Success: {response.text}")
            esp32_connected = True
            return True
        else:
            print(f"[ESP32 Response] Error {response.status_code}: {response.text}")
            return False
            
    except requests.exceptions.ConnectRefused:
        print("[ERROR] ESP32 refused connection - check if ESP32 is running")
        esp32_connected = False
        return False
    except requests.exceptions.Timeout:
        print("[ERROR] ESP32 request timeout - check network connection")
        esp32_connected = False
        return False
    except requests.exceptions.ConnectionError:
        print("[ERROR] Could not connect to ESP32 - check IP address and network")
        esp32_connected = False
        return False
    except Exception as e:
        print(f"[ERROR] Unexpected error sending to ESP32: {e}")
        esp32_connected = False
        return False

# ------------------ GET ESP32 STATUS ------------------
def get_esp32_status():
    """Get current parking status from ESP32"""
    try:
        response = requests.get(esp32_status_endpoint, timeout=3)
        if response.status_code == 200:
            return response.json()
        return None
    except:
        return None

# ------------------ DETECTION FUNCTION ------------------
def detect_vehicles(outputs, img):
    global vehicle_detected, last_detected_time, vehicle_present_last_frame

    hT, wT, _ = img.shape
    bbox, classIds, confs = [], [], []
    vehicle_in_frame_now = False
    vehicle_count = 0

    for output in outputs:
        for det in output:
            scores = det[5:]
            classId = np.argmax(scores)
            confidence = scores[classId]

            if confidence > confThreshold:
                w, h = int(det[2] * wT), int(det[3] * hT)
                x, y = int((det[0] * wT) - w / 2), int((det[1] * hT) - h / 2)
                bbox.append([x, y, w, h])
                classIds.append(classId)
                confs.append(float(confidence))

    indices = cv2.dnn.NMSBoxes(bbox, confs, confThreshold, nmsThreshold)

    if len(indices) > 0:
        for i in indices:
            idx = i[0] if isinstance(i, (list, np.ndarray)) else i
            x, y, w, h = bbox[idx]
            center_x = x + w // 2
            center_y = y + h // 2

            # Check if it's a vehicle class
            is_vehicle = classIds[idx] in [carClassId, motorcycleClassId, truckClassId, busClassId]
            
            if is_vehicle:
                label = f'{classNames[classIds[idx]].upper()} {int(confs[idx] * 100)}%'
                color = (0, 255, 0) if line1_x < center_x < line2_x else (255, 0, 255)
                
                cv2.rectangle(img, (x, y), (x + w, y + h), color, 2)
                cv2.putText(img, label, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
                cv2.circle(img, (center_x, center_y), 6, (0, 255, 0), -1)

                # Check if vehicle is in the virtual parking zone
                if line1_x < center_x < line2_x:
                    vehicle_in_frame_now = True
                    vehicle_count += 1
                    
                    current_time = time.time()
                    if not vehicle_detected or current_time - last_detected_time > cooldown_seconds:
                        if send_to_esp32(esp32_enter_endpoint):
                            vehicle_detected = True
                            last_detected_time = current_time

    # Vehicle left detection
    if vehicle_present_last_frame and not vehicle_in_frame_now:
        if send_to_esp32(esp32_leave_endpoint):
            print("[INFO] Vehicle has left the zone")
        vehicle_detected = False

    vehicle_present_last_frame = vehicle_in_frame_now

    # Draw virtual zone lines and status
    cv2.line(img, (line1_x, 0), (line1_x, hT), (0, 255, 0), 3)
    cv2.line(img, (line2_x, 0), (line2_x, hT), (0, 0, 255), 3)
    
    # Add text overlay
    zone_text = f"Parking Zone: {'OCCUPIED' if vehicle_in_frame_now else 'FREE'}"
    vehicle_count_text = f"Vehicles in zone: {vehicle_count}"
    esp32_status_text = f"ESP32: {'Connected' if esp32_connected else 'Disconnected'}"
    
    cv2.putText(img, zone_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0) if not vehicle_in_frame_now else (0, 0, 255), 2)
    cv2.putText(img, vehicle_count_text, (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    cv2.putText(img, esp32_status_text, (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0) if esp32_connected else (0, 0, 255), 2)

# ------------------ MAIN LOOP ------------------
def main():
    print("=" * 50)
    print("🚗 ParqPilot Vehicle Detection System")
    print("=" * 50)
    
    # Test ESP32 connection first
    if not test_esp32_connection():
        print("\n⚠️  ESP32 Connection Issues:")
        print("1. Check if ESP32 is powered on and running")
        print("2. Verify the IP address in the 'endpoint' variable")
        print("3. Ensure you're on the same network as ESP32")
        print("4. Check ESP32 Serial Monitor for errors")
        print("\nContinuing with detection only (no ESP32 communication)...")
        input("Press Enter to continue...")
    
    frame_count = 0
    fps_start_time = time.time()
    
    while True:
        try:
            # Capture frame from ESP32 camera
            img_resp = urllib.request.urlopen(camera_url, timeout=5)
            imgnp = np.array(bytearray(img_resp.read()), dtype=np.uint8)
            im = cv2.imdecode(imgnp, -1)
            
            if im is None:
                print("[WARNING] Could not decode image from ESP32")
                continue

            # YOLO detection
            blob = cv2.dnn.blobFromImage(im, 1 / 255, (whT, whT), [0, 0, 0], 1, crop=False)
            net.setInput(blob)
            layerNames = net.getLayerNames()
            outputNames = [layerNames[i - 1] for i in net.getUnconnectedOutLayers().flatten()]
            outputs = net.forward(outputNames)

            detect_vehicles(outputs, im)
            
            # Calculate and display FPS
            frame_count += 1
            if frame_count % 30 == 0:
                fps = 30 / (time.time() - fps_start_time)
                fps_start_time = time.time()
                print(f"[INFO] Processing at {fps:.1f} FPS")
            
            cv2.imshow('ParqPilot Detection', im)

            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                print("[INFO] Quitting application...")
                break
            elif key == ord('s'):
                # Manual status check
                status = get_esp32_status()
                if status:
                    print(f"[ESP32 Status] {status}")
                else:
                    print("[ERROR] Could not get ESP32 status")

        except urllib.error.URLError as e:
            print(f"[ERROR] Camera stream error: {e}")
            print("Check if ESP32 camera is working and accessible")
            time.sleep(1)
        except KeyboardInterrupt:
            print("\n[INFO] Interrupted by user")
            break
        except Exception as e:
            print(f"[ERROR] Unexpected error: {e}")
            time.sleep(1)

    cv2.destroyAllWindows()
    print("[INFO] Application closed")

if __name__ == "__main__":
    main() 