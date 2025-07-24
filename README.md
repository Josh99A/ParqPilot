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