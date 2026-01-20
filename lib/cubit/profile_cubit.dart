import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:FitTrack/services/biometric_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  final BiometricService _biometricService = BiometricService();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  /// Initialize the cubit and start listening to user data
  Future<void> initialize() async {
    emit(state.copyWith(status: ProfileStatus.loading));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'User not logged in',
      ));
      return;
    }

    // Set up real-time listener for user data
    _setupUserListener(user.uid);

    // Check biometric availability
    await _checkBiometricAvailability();
  }

  /// Set up real-time listener for user document
  void _setupUserListener(String userId) {
    _userSubscription?.cancel();

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final user = FirebaseAuth.instance.currentUser;

          emit(state.copyWith(
            status: ProfileStatus.loaded,
            username: data['username'] ?? 'User',
            email: user?.email ?? 'No email',
            profileImageUrl: data['profileImageUrl'],
          ));

          print('👤 Profile updated: ${data['username']}, Image: ${data['profileImageUrl']}');
        }
      },
      onError: (error) {
        print('❌ Profile listener error: $error');
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Failed to load profile: $error',
        ));
      },
    );
  }

  /// Check biometric availability
  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricLoginEnabled();

      emit(state.copyWith(
        isBiometricAvailable: available,
        isBiometricEnabled: enabled,
      ));
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        await _uploadProfileImage(File(image.path));
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to pick image: $e',
      ));
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        await _uploadProfileImage(File(image.path));
      }
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to take photo: $e',
      ));
    }
  }

  /// Upload profile image to Firebase Storage
  Future<void> _uploadProfileImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    emit(state.copyWith(status: ProfileStatus.uploading));

    try {
      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Upload file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profileImageUrl': downloadUrl}, SetOptions(merge: true));

      // Also update Firebase Auth photo URL
      await user.updatePhotoURL(downloadUrl);

      print('✅ Profile image uploaded successfully: $downloadUrl');

      // State will be updated automatically by the listener
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to upload image: $e',
      ));
    }
  }

  /// Remove profile image
  Future<void> removeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    emit(state.copyWith(status: ProfileStatus.uploading));

    try {
      // Delete from storage
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        // File might not exist, ignore error
        print('⚠️ Could not delete storage file: $e');
      }

      // Remove URL from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': FieldValue.delete()});

      // Clear Firebase Auth photo URL
      await user.updatePhotoURL(null);

      print('✅ Profile image removed successfully');

      // State will be updated automatically by the listener
    } catch (e) {
      print('❌ Error removing profile image: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to remove image: $e',
      ));
    }
  }

  /// Update profile information
  Future<void> updateProfile({
    String? username,
    String? email,
    String? password,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update username in Firestore
      if (username != null && username != state.username) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'username': username}, SetOptions(merge: true));
        await user.updateDisplayName(username);
      }

      // Update email if changed
      if (email != null && email != state.email && email.isNotEmpty) {
        await user.updateEmail(email);
      }

      // Update password if provided
      if (password != null && password.isNotEmpty) {
        await user.updatePassword(password);
      }

      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to update profile: $e',
      ));
      rethrow;
    }
  }

  /// Toggle biometric login
  Future<bool> toggleBiometricLogin() async {
    try {
      if (state.isBiometricEnabled) {
        await _biometricService.clearBiometricLogin();
        emit(state.copyWith(isBiometricEnabled: false));
        return true;
      } else {
        if (!state.isBiometricAvailable) {
          return false;
        }

        final authenticated = await _biometricService.authenticateWithBiometrics();
        if (authenticated) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email != null) {
            await _biometricService.setupBiometricLogin(user.email!);
            emit(state.copyWith(isBiometricEnabled: true));
            return true;
          }
        }
        return false;
      }
    } catch (e) {
      print('❌ Error toggling biometric login: $e');
      return false;
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
