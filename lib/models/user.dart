import 'dart:convert';

class User {
  String username;
  String hashedPassword;
  String salt;
  bool isAdmin;

  User({
    this.username,
    this.hashedPassword,
    this.salt,
    this.isAdmin,
  });

  static String get primaryKey => 'username';
  String get name => 'user';
  Map<String, String> get typeMap => {
        'isAdmin': 'bool',
      };
  List<String> get noUpdate => [
        'username',
        'hashedPassword',
        'salt',
      ];
  User copyWith({
    String username,
    String hashedPassword,
    String salt,
    bool isAdmin,
  }) {
    return User(
      username: username ?? this.username,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      salt: salt ?? this.salt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'hashedPassword': hashedPassword,
      'salt': salt,
      'isAdmin': isAdmin,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return User(
      username: map['username'],
      hashedPassword: map['hashedPassword'],
      salt: map['salt'],
      isAdmin: map['isAdmin'],
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(username: $username, hashedPassword: $hashedPassword, salt: $salt, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is User &&
        o.username == username &&
        o.hashedPassword == hashedPassword &&
        o.salt == salt &&
        o.isAdmin == isAdmin;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        hashedPassword.hashCode ^
        salt.hashCode ^
        isAdmin.hashCode;
  }
}
