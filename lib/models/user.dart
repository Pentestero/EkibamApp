
class AppUser {
  final String name;
  final String identifier; // Email or phone number
  final String passwordHash;

  AppUser({required this.name, required this.identifier, required this.passwordHash});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'identifier': identifier,
      'passwordHash': passwordHash,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      name: map['name'] as String,
      identifier: map['identifier'] as String,
      passwordHash: map['passwordHash'] as String,
    );
  }
}
