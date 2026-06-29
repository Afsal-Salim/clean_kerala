import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/auth_models.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String accountType,
    String? phone,
    String? adminCode,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'account_type': accountType,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (adminCode != null && adminCode.isNotEmpty) 'admin_code': adminCode,
    });
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResult> verifyEmail({required String email, required String otp}) async {
    final response = await _dio.post('/auth/verify-email', data: {
      'email': email,
      'otp': otp,
    });
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resendOtp({required String email, String purpose = 'email_verification'}) async {
    await _dio.post('/auth/resend-otp', data: {
      'email': email,
      'purpose': purpose,
    });
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  Future<UserModel> profile() async {
    final response = await _dio.get('/auth/profile');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<UserModel> updateLocation({
    double? latitude,
    double? longitude,
    String? ward,
    String? municipality,
    String? district,
  }) async {
    final response = await _dio.put('/profile/location', data: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (ward != null && ward.isNotEmpty) 'ward': ward,
      if (municipality != null && municipality.isNotEmpty) 'municipality': municipality,
      if (district != null && district.isNotEmpty) 'district': district,
    });
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
