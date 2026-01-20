import 'package:equatable/equatable.dart';

/// Represents the status of profile operations
enum ProfileStatus { initial, loading, loaded, uploading, error }

/// The state for the Profile feature
class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? errorMessage;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.username = '',
    this.email = '',
    this.profileImageUrl,
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
  });

  /// Creates a copy of this state with the given fields replaced
  ProfileState copyWith({
    ProfileStatus? status,
    String? errorMessage,
    String? username,
    String? email,
    String? profileImageUrl,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }

  /// Check if user has a profile image
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Get user's initial for avatar fallback
  String get userInitial => username.isNotEmpty ? username[0].toUpperCase() : 'U';

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        username,
        email,
        profileImageUrl,
        isBiometricAvailable,
        isBiometricEnabled,
      ];
}
