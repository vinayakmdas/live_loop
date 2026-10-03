import 'package:frontend/features/auth/domain/Entities/user_entites.dart';


class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json["id"] ?? json["_id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      username: (json["username"] ?? json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "username": username,
      "email": email,
    };
  }
}