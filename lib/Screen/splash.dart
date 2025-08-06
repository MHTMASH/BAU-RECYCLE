// Import Flutter material design package
import 'package:flutter/material.dart';
// Import Firebase Authentication package
import 'package:firebase_auth/firebase_auth.dart';
// Import the update screens
import 'package:my_app/Screen/update_screens.dart';
// Import the update checking service
import 'package:my_app/services/update_service.dart';
// Import shared preferences for local storage
import 'package:shared_preferences/shared_preferences.dart';
// Import HomePage screen
import 'package:my_app/Screen/home.dart';
// Import LoginPage screen
import 'package:my_app/Screen/login.dart';

// Define SplashScreen as a StatefulWidget because its state changes
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState(); // Create its state
}

// Define the private state class for SplashScreen
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // SingleTickerProvider is needed for animation controller
  late AnimationController _animationController; // Controls animations
  late Animation<double> _fadeAnimation; // Fade-in animation
  late Animation<double> _scaleAnimation; // Scale-up (zoom) animation

  @override
  void initState() {
    super.initState();
    _checkVersionAndLogin(); // First check if app needs update or is under maintenance

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000), // Animation runs for 2 seconds
      vsync: this, // Provide a ticker provider (this widget itself)
    );

    // Define how the fade animation behaves
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn), // Ease in curve
      ),
    );

    // Define how the scale animation behaves
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.0,
          0.5,
          curve: Curves.easeOutBack,
        ), // A playful scale curve
      ),
    );

    // Start the animation immediately
    _animationController.forward();

    // Check user's login status and navigate accordingly
    _checkAuthStatus();
  }

  // Check authentication status
  Future<void> _checkAuthStatus() async {
    await Future.delayed(
      Duration(seconds: 3),
    ); // Wait 3 seconds (splash screen delay)

    // Get current logged-in user from Firebase
    User? currentUser = FirebaseAuth.instance.currentUser;
    // Access local storage (SharedPreferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Get 'isLoggedIn' status from preferences (default false if not set)
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // If widget is no longer active, stop further actions
    if (!mounted) return;

    // If user is logged in and session is valid
    if (currentUser != null && isLoggedIn) {
      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // Otherwise, reset login status in preferences
      await prefs.setBool('isLoggedIn', false);
      // Navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Dispose animation controller to free memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Add a vertical gradient background color
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController, // Listen to animation changes
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center contents vertically
                children: [
                  // App Logo with fade and scale animation
                  FadeTransition(
                    opacity: _fadeAnimation, // Apply fade animation
                    child: ScaleTransition(
                      scale: _scaleAnimation, // Apply scale animation
                      child: Container(
                        height: 150, // Logo container height
                        width: 150, // Logo container width
                        decoration: BoxDecoration(
                          color: Colors.white, // Logo background color
                          shape: BoxShape.circle, // Make it circular
                          boxShadow: [
                            // Add a green soft shadow
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'lib/assets/logo.png', // Logo image path
                            height: 100, // Logo image height
                            width: 100, // Logo image width
                            fit: BoxFit.contain, // Fit image nicely inside
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24), // Add some space
                  // App Name text with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'BAU ReCycle', // App Name
                      style: TextStyle(
                        fontSize: 32, // Big font
                        fontWeight: FontWeight.bold, // Bold text
                        color: Colors.green.shade800, // Dark green color
                      ),
                    ),
                  ),
                  SizedBox(height: 8), // Small space
                  // Tagline text with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Buy, sell, reduce, reuse!', // App tagline
                      style: TextStyle(
                        fontSize: 16, // Smaller font
                        color: Colors.grey.shade600, // Greyish color
                      ),
                    ),
                  ),
                  SizedBox(height: 48), // Large space
                  // Circular loading spinner with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600, // Green color spinner
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Check if the app needs update or is under maintenance
  void _checkVersionAndLogin() async {
    if (!mounted) return; // Ensure widget is still mounted

    final updateService = UpdateService(); // Create update service
    final updateStatus = await updateService.checkUpdate(); // Check for updates

    if (!mounted) return; // Double check widget is mounted

    // If app is under maintenance, show maintenance screen
    if (updateStatus['isUnderMaintenance']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MaintenancePage()),
      );
      return;
    }

    // If app needs mandatory update, show update prompt screen
    if (updateStatus['needsUpdate']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpdatePromptPage(onUpdate: () {}),
        ),
      );
      return;
    }
  }
}
