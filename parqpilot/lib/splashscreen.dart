import 'dart:ui'; 
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/car1.png.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), 
              child: Container(
                color: Colors.black.withOpacity(0.2), // optional dark overlay
              ),
            ),
          ),
          // Two icons at top left and right
          Positioned(
            top: 40,
            left: 24,
            child: Icon(Icons.menu, color: Colors.white, size: 32),
          ),
          Positioned(
            top: 40,
            right: 24,
            child: Icon(Icons.account_circle, color: Colors.white, size: 32),
          ),
          // Overlay with content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Main Text
                    Center(
                      child: const Text(
                        'Find yourself a\nparking slot,\neffortlessly',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          //height: 1.3,
                        ),
                        textAlign: TextAlign.center, 
                      
                      ),
                    ),
                    
                    // Car Image
                    Center(
                      child: Image.asset(
                        'assets/car2.png.png',
                        width: size.width * 0.75,
                        fit: BoxFit.contain,
                      ),
                    ),
                   // const Spacer(),
                    // Get Started Button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to next screen
                        },
                        icon: const Icon(Icons.directions_car, color: Colors.white),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Get Started",
                              style: TextStyle(fontSize: 28, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
