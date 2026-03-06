enum UserRole { student, driver, admin, unknown }

extension UserRoleExtension on UserRole {
  // Logic: Converts raw strings from Laravel/SharedPreferences into safe Enums [cite: 2026-02-24]
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      default:
        // Logic: Prevents app crashes if an unexpected role is received [cite: 2026-02-24]
        return UserRole.unknown;
    }
  }

  // Logic: Helper for displaying labels in the UI
  String get name => toString().split('.').last;
}
