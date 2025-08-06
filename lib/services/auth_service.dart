// Import Firebase Authentication package
import 'package:firebase_auth/firebase_auth.dart';
// Import Cloud Firestore package
import 'package:cloud_firestore/cloud_firestore.dart';
// Import Flutter material design package (for UI)
import 'package:flutter/material.dart';
// Import SharedPreferences package (for saving data locally)
import 'package:shared_preferences/shared_preferences.dart';

// AuthService class handles all login, signup, user-related work
class AuthService {
  // Create Firebase Auth instance to interact with authentication
  final _auth = FirebaseAuth.instance;
  // Create Firestore instance to interact with database
  final _firestore = FirebaseFirestore.instance;

  // Method to get the current user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid; // Return user id if logged in, else null
  }

  // Method to create a user with email and password
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    BuildContext context, {
    required String fullName, // Require user's full name too
  }) async {
    try {
      // Create user with email and password on Firebase
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // If user created successfully, add their info in Firestore 'users' collection
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid, // Store user's UID
          'email': email, // Store user's email
          'fullName': fullName, // Store user's full name
          'profileImageUrl': null, // Placeholder for profile image
        });

        // Update the display name of the user in Firebase Auth profile
        await cred.user!.updateDisplayName(fullName);
      }

      return cred.user; // Return the created user
    } catch (e) {
      print('Create user error: $e'); // Print any error
      rethrow; // Rethrow error so UI can catch and show message
    }
  }

  // Method to log in a user with email and password
  Future<User?> loginUserWithEmailAndPassword(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      // Try signing in user with email and password
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // If login successful, update 'lastLogin' time in Firestore
        await _firestore.collection('users').doc(cred.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(), // Save server time
        });
      }

      return cred.user; // Return the logged-in user
    } catch (e) {
      print('Login error: $e'); // Print any error
      rethrow; // Rethrow error
    }
  }

  // Method to send an email verification link to user
  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      // Send a verification email to current user
      await _auth.currentUser?.sendEmailVerification();

      // If user exists, update email verification status in Firestore
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'isEmailVerified': true}, // Set email verified true
        );
      }
    } catch (e) {
      print('Verification error: $e'); // Print any error
      rethrow; // Throw error
    }
  }

  // Method to get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser != null) {
        // Get the document of current user from Firestore
        final docSnapshot =
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .get();

        if (docSnapshot.exists) {
          // If user data exists, return it
          return docSnapshot.data();
        }
      }
      return null; // If no user logged in or data doesn't exist
    } catch (e) {
      print('Get user data error: $e'); // Print error
      rethrow; // Rethrow
    }
  }

  // Method to update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser != null) {
        // Update the current user's Firestore document with new data
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(data);
      }
    } catch (e) {
      print('Update user data error: $e'); // Print error
      rethrow;
    }
  }

  // Method to check if user's email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false; // Return true or false
  }

  // Method to send password reset email
  Future<void> sendResetPassword(String email) async {
    try {
      // Send a password reset link to user's email
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset error: $e'); // Print error
      rethrow;
    }
  }

  // Method to sign out the user
  Future<void> signout() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      // Clear login info from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      print('Signout error: $e'); // Print error
      rethrow;
    }
  }

  // Method to delete the user's account
  Future<void> deleteUser() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // First delete user's data from Firestore
        await _firestore.collection('users').doc(currentUser.uid).delete();

        // Then delete the user account from Firebase Auth
        await currentUser.delete();

        // Clear login status from local storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);

        print('User account and data deleted successfully'); // Success message
      } else {
        throw Exception('No user currently logged in'); // If no user found
      }
    } catch (e) {
      print('Delete user error: $e'); // Print error
      rethrow;
    }
  }
}
