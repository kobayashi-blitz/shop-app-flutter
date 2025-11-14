class User {
  final int id;
  final String name;
  final String officeName;

  User({
    required this.id,
    required this.name,
    required this.officeName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      officeName: json['office_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'office_name': officeName,
    };
  }
}
