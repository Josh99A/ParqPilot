import 'package:flutter/material.dart';
import 'splashscreen.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0014A8),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Logo.png',
                width: size.width * 0.25, 
                height: size.height * 0.25,
              ),
              const SizedBox(height: 20),
              const Text(
                'ParqPilot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const Icon(
                Icons.horizontal_rule,
                size: 40,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  
        
    
      
          
     
  


