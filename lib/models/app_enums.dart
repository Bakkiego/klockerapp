enum userRole {
  Manager,
  Employee,
  Admin;

  String get toSql => name;

  // Add this static method here
  static userRole fromString(String? roleName) {
    return userRole.values.firstWhere(
      (role) => role.name.toLowerCase() == roleName?.toLowerCase(),
      orElse: () =>
          userRole.Employee, // Default to Employee if something goes wrong
    );
  }
}
