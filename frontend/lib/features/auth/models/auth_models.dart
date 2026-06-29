class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isEmailVerified,
    this.homeLatitude,
    this.homeLongitude,
    this.homeWard,
    this.homeMunicipality,
    this.homeDistrict,
    this.hasHomeLocation = false,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isEmailVerified;
  final double? homeLatitude;
  final double? homeLongitude;
  final String? homeWard;
  final String? homeMunicipality;
  final String? homeDistrict;
  final bool hasHomeLocation;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        isEmailVerified: json['is_email_verified'] as bool,
        homeLatitude: (json['home_latitude'] as num?)?.toDouble(),
        homeLongitude: (json['home_longitude'] as num?)?.toDouble(),
        homeWard: json['home_ward'] as String?,
        homeMunicipality: json['home_municipality'] as String?,
        homeDistrict: json['home_district'] as String?,
        hasHomeLocation: json['has_home_location'] as bool? ?? false,
      );

  String get homeLocationLabel {
    final parts = [homeWard, homeMunicipality, homeDistrict].whereType<String>().where((e) => e.isNotEmpty);
    return parts.join(' · ');
  }
}

class TokenPair {
  TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

class AuthResult {
  AuthResult({required this.user, this.tokens, this.message});

  final UserModel user;
  final TokenPair? tokens;
  final String? message;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        tokens: json['tokens'] != null
            ? TokenPair.fromJson(json['tokens'] as Map<String, dynamic>)
            : null,
        message: json['message'] as String?,
      );
}
