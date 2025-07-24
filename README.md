# ParqPilot-Smart Parking System
ParqPilot is a real-time smart parking system to help drivers quickly identify available and unavailable parking slots.combining ultrasonic sensors,ESP32-CAM microcontrollers  and Firebaseto deliver live slot updates on a web-based dashboard


## Overview
In many urban areas,drivers struggle to find open parking spaces,leading to time loss and traffic congestion .ParqPilot addresses this challenge by showing the availability of each parking slot in real-time through a visual dashboard and LED indicators on-site.The system is easy to install and scalable for different parking lot sizes.

## System Architecture
[Ultrasonic Sensors (HC-SR04)]
↓
[ESP32-CAM] -- Wi-Fi --> [Firebase Realtime Database] --> [Web Dashboard]
↓
[LED Indicators]




## Features

-Real-Time Slot Status: Shows live status of each slot (Green = Free, Red = Occupied).
-LED Indicators: On-site visual indicators for each slot.
-Firebase Integration: ESP32-CAM pushes data to Firebase database.
-Responsive Web Dashboard: Viewable from phone, tablet, or desktop.
-Wireless Communication: ESP32 connects over Wi-Fi without cables.
-Battery Powered: No need for external power supply.


## How It Works

1. Ultrasonic sensors detect if a car is parked in a slot based on distance.
2. ESP32-CAM processes the data and sends it to Firebase in real-time.
3. The LED indicator turns red when a slot is occupied, green when free.
4. The web dashboard fetches data from Firebase and updates automatically.



## Technologies Used

Hardware:  
  - HC-SR04 Ultrasonic Sensors  
  - ESP32-CAM Microcontroller  
  - LED Lights  
  - Potentiometer & Resistors  
  - FTDI Programmer  
  - Battery Power Supply  

Software:  
  - Arduino IDE (ESP32 firmware)  
  - Firebase Realtime Database  
  - HTML, CSS, JavaScript (dashboard)

---

## Setup Instructions

### Hardware Setup
1. Connect HC-SR04 sensors to ESP32-CAM (use 5V, GND, TRIG, ECHO).
2. Add LEDs with 200Ω resistors to display status.
3. Power the ESP32 with a battery pack.
4. Use an FTDI programmer to upload your code.

###  Software Setup
1. Install Arduino IDE and ESP32 board support.
2. Upload the code to ESP32-CAM with Firebase credentials.
3. Configure your Firebase database paths (e.g., `/parking/slot1`, etc.).

###  Web Dashboard
1. Clone or download the web interface files.
2. Open `index.html` in your browser.
3. Make sure your Firebase config matches your own database.



## Screenshots



 Real-time slot status on dashboard   
Firebase data showing occupied/free  
Serial monitor showing sensor readings  
Mobile & desktop views of the dashboard  



## Project Repository & Website

[GitHub Repository](https://github.com/Josh99A/ParqPilot.git)  
[Live Dashboard (if hosted)](https://your-link.vercel.app) *(Optional)*



## Contributors
Awule Joshua 
Komuhendo Vivian
Kuteesa Mercylinah
Birungi Jennifer
Mwesigwa Daniel
