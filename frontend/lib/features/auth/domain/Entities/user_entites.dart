class UserEntity {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? profileImage;
  final String? token;
  final String? refreshToken;

  const UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage,
    this.token,
    this.refreshToken,
  });
}