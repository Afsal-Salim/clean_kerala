import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';
import '../models/auth_models.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  final Ref _ref;

  AuthApi get _api => _ref.read(authApiProvider);
  TokenStorage get _storage => _ref.read(tokenStorageProvider);

  Future<void> _bootstrap() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _api.profile();
      state = AsyncValue.data(user);
    } catch (_) {
      await _storage.clear();
      state = const AsyncValue.data(null);
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String accountType,
    String? phone,
    String? adminCode,
  }) async {
    try {
      final result = await _api.register(
        name: name,
        email: email,
        password: password,
        accountType: accountType,
        phone: phone,
        adminCode: adminCode,
      );
      return result.message;
    } on Exception catch (e) {
      rethrow;
    }
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    final result = await _api.verifyEmail(email: email, otp: otp);
    if (result.tokens != null) {
      await _storage.saveTokens(
        access: result.tokens!.accessToken,
        refresh: result.tokens!.refreshToken,
      );
      state = AsyncValue.data(result.user);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _api.login(email: email, password: password);
    if (result.tokens != null) {
      await _storage.saveTokens(
        access: result.tokens!.accessToken,
        refresh: result.tokens!.refreshToken,
      );
      final user = await _api.profile();
      state = AsyncValue.data(user);
    }
  }

  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh != null) {
      try {
        await _api.logout(refreshToken: refresh);
      } catch (_) {}
    }
    await _storage.clear();
    state = const AsyncValue.data(null);
  }

  Future<UserModel> updateLocation({
    double? latitude,
    double? longitude,
    String? ward,
    String? municipality,
    String? district,
  }) async {
    final user = await _api.updateLocation(
      latitude: latitude,
      longitude: longitude,
      ward: ward,
      municipality: municipality,
      district: district,
    );
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> refreshProfile() async {
    final user = await _api.profile();
    state = AsyncValue.data(user);
  }
}
