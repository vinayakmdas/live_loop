import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    super.profileImage,
    super.token,
    super.refreshToken,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? token,
    String? refreshToken,
  }) {
    return UserModel(
      id: (json["id"] ?? json["_id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      username: (json["username"] ?? json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      profileImage: (json["profileImage"] ?? json["photoUrl"] ?? json["picture"])?.toString(),
      token: token ?? (json["token"] ?? json["accessToken"])?.toString(),
      refreshToken: refreshToken ?? json["refreshToken"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "username": username,
      "email": email,
      if (profileImage != null) "profileImage": profileImage,
      if (token != null) "token": token,
      if (refreshToken != null) "refreshToken": refreshToken,
    };
  }
}