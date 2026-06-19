import 'json_utils.dart';

/// Authenticated user returned by the backend (serialize_user dict).
class UserModel {
  final String id;
  final String email;
  final String username;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: asString(pick(json, ['id', '_id'])),
      email: asString(json['email']),
      username: asString(json['username']),
      createdAt: asDate(pick(json, ['created_at', 'createdAt'])),
    );
  }
}

/// Registration request body. Sent as {email, username, password}.
class UserRegister {
  final String email;
  final String username;
  final String password;

  const UserRegister({
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'username': username,
        'password': password,
      };
}

/// Login request body. Sent as {email, password}.
class UserLogin {
  final String email;
  final String password;

  const UserLogin({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Token bundle returned by login/refresh (TokenResponse).
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresIn = 0,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: asString(pick(json, ['access_token', 'accessToken'])),
      refreshToken: asString(pick(json, ['refresh_token', 'refreshToken'])),
      tokenType: asString(pick(json, ['token_type', 'tokenType']), 'bearer'),
      expiresIn: asInt(pick(json, ['expires_in', 'expiresIn'])),
    );
  }
}
