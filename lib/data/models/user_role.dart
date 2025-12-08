enum UserRole { coach, coloso, colosoPrime, admin }

extension UserRoleX on UserRole {
  String get id {
    switch (this) {
      case UserRole.coach:
        return 'coach';
      case UserRole.coloso:
        return 'coloso';
      case UserRole.colosoPrime:
        return 'coloso_prime';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.coach:
        return 'Coach';
      case UserRole.coloso:
        return 'Coloso';
      case UserRole.colosoPrime:
        return 'Coloso Prime';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  static UserRole fromId(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'coach':
        return UserRole.coach;
      case 'coloso_prime':
      case 'coloso-prime':
      case 'colosoprime':
        return UserRole.colosoPrime;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'coloso':
      default:
        return UserRole.coloso;
    }
  }
}
