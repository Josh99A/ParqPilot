import cv2
import numpy as np
import urllib.request
import requests
import time

# ------------------ YOLOv3 CONFIGURATION ------------------
modelConfig = 'yolov3.cfg'              # Use 'yolov3-tiny.cfg' if using tiny version
modelWeights = 'yolov3.weights'         # Use 'yolov3-tiny.weights' for tiny
classesfile = 'coco.names'
classNames = []

# Load class names
with open(classesfile, 'rt') as f:
    classNames = f.read().rstrip('\n').split('\n')

# Choose COCO class IDs (you can modify to use 'car' and 'motorbike')
carClassId = classNames.index('person')        # Change to 'car' if preferred
motorcycleClassId = classNames.index('bottle') # Change to 'motorbike' if preferred

# ------------------ CAMERA AND ESP32 SETUP ------------------
camera_url = 'http://10.253.237.140/cam-lo.jpg'
esp32_enter_endpoint = 'http://10.253.237.140/vehicle_detected'
esp32_leave_endpoint = 'http://10.253.237.140/vehicle_left'

# ------------------ YOLO NETWORK INITIALIZATION ------------------
whT = 320
confThreshold = 0.5
nmsThreshold = 0.3

net = cv2.dnn.readNetFromDarknet(modelConfig, modelWeights)
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

# ------------------ PARKING LOGIC STATE ------------------
vehicle_detected = False
vehicle_present_last_frame = False
cooldown_seconds = 5
last_detected_time = 0

# ------------------ VIRTUAL ZONE COORDINATES ------------------
line1_x = 200
line2_x = 600

# ------------------ SEND REQUEST TO ESP32 ------------------
def send_to_esp32(endpoint):
    try:
        print(f"[INFO] Sending request to {endpoint}")
        response = requests.get(endpoint, timeout=2)
        print("[ESP32 Response]:", response.status_code)
    except Exception as e:
        print("[ERROR] Could not send data to ESP32:", e)

# ------------------ DETECTION FUNCTION ------------------
def detect_vehicles(outputs, img):
    global vehicle_detected, last_detected_time, vehicle_present_last_frame

    hT, wT, _ = img.shape
    bbox, classIds, confs = [], [], []
    vehicle_in_frame_now = False

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

            label = f'{classNames[classIds[idx]].upper()} {int(confs[idx] * 100)}%'
            cv2.rectangle(img, (x, y), (x + w, y + h), (255, 0, 255), 2)
            cv2.putText(img, label, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 255), 2)
            cv2.circle(img, (center_x, center_y), 6, (0, 255, 0), -1)

            # Check if it's in the virtual parking zone
            if classIds[idx] in [carClassId, motorcycleClassId] and line1_x < center_x < line2_x:
                vehicle_in_frame_now = True
                current_time = time.time()
                if not vehicle_detected or current_time - last_detected_time > cooldown_seconds:
                    send_to_esp32(esp32_enter_endpoint)
                    vehicle_detected = True
                    last_detected_time = current_time
                break  # Only count first matching object

    # Vehicle left detection
    if vehicle_present_last_frame and not vehicle_in_frame_now:
        send_to_esp32(esp32_leave_endpoint)
        print("[INFO] Vehicle has left the zone")

    vehicle_present_last_frame = vehicle_in_frame_now

    # Draw virtual zone lines
    cv2.line(img, (line1_x, 0), (line1_x, hT), (0, 255, 0), 2)
    cv2.line(img, (line2_x, 0), (line2_x, hT), (0, 0, 255), 2)

# ------------------ MAIN LOOP ------------------
while True:
    try:
        img_resp = urllib.request.urlopen(camera_url, timeout=3)
        imgnp = np.array(bytearray(img_resp.read()), dtype=np.uint8)
        im = cv2.imdecode(imgnp, -1)

        blob = cv2.dnn.blobFromImage(im, 1 / 255, (whT, whT), [0, 0, 0], 1, crop=False)
        net.setInput(blob)
        layerNames = net.getLayerNames()
        outputNames = [layerNames[i - 1] for i in net.getUnconnectedOutLayers().flatten()]
        outputs = net.forward(outputNames)

        detect_vehicles(outputs, im)
        cv2.imshow('ParqPilot Detection', im)

        if cv2.waitKey(1) == ord('q'):
            break

    except Exception as e:
        print("[ERROR] Stream or Processing Error:", e)

cv2.destroyAllWindows()
