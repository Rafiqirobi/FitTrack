import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = await _localAuth.isDeviceSupported();
      print('🔐 Biometric hardware check - canCheckBiometrics: $canAuthenticateWithBiometrics, isDeviceSupported: $canAuthenticate');
      return canAuthenticateWithBiometrics && canAuthenticate;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print('🔐 Biometric authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      print('❌ Error during biometric authentication: $e');
      return false;
    }
  }

  // Check if user has enabled biometric login
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_login_enabled') ?? false;
    } catch (e) {
      print('Error checking biometric login preference: $e');
      return false;
    }
  }

  // Enable/disable biometric login
  Future<void> setBiometricLoginEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_login_enabled', enabled);
    } catch (e) {
      print('Error setting biometric login preference: $e');
    }
  }

  // Get stored email for biometric login
  Future<String?> getBiometricEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('biometric_email');
    } catch (e) {
      print('Error getting biometric email: $e');
      return null;
    }
  }

  // Store email for biometric login
  Future<void> setBiometricEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_email', email);
    } catch (e) {
      print('Error setting biometric email: $e');
    }
  }

  // Perform biometric login
  Future<User?> biometricLogin() async {
    try {
      // Check if biometric is available and enabled
      if (!await isBiometricAvailable()) {
        throw Exception('Biometric authentication not available');
      }

      if (!await isBiometricLoginEnabled()) {
        throw Exception('Biometric login not enabled');
      }

      // Get stored email
      final email = await getBiometricEmail();
      if (email == null) {
        throw Exception('No email stored for biometric login');
      }

      // Authenticate with biometrics
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        return null;
      }

      // Get current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email == email) {
        print('✅ Biometric login successful for user: ${currentUser.uid}');
        return currentUser;
      }

      throw Exception('User session expired. Please login with email and password first.');
    } catch (e) {
      print('❌ Biometric login failed: $e');
      rethrow;
    }
  }

  // Setup biometric login after successful email/password login
  Future<void> setupBiometricLogin(String email) async {
    try {
      await setBiometricEmail(email);
      await setBiometricLoginEnabled(true);
      print('✅ Biometric login setup completed for: $email');
    } catch (e) {
      print('❌ Error setting up biometric login: $e');
      rethrow;
    }
  }

  // Clear biometric login data
  Future<void> clearBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_login_enabled');
      await prefs.remove('biometric_email');
      print('✅ Biometric login data cleared');
    } catch (e) {
      print('❌ Error clearing biometric login data: $e');
    }
  }
}