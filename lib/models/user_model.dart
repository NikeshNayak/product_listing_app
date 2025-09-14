class UserModel {
  final String name;
  final String email;
  final String profileImage;

  UserModel({
    required this.name,
    required this.email,
    required this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] as String,
    email: json['email'] as String,
    profileImage: json['profileImage'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'profileImage': profileImage,
  };
}
