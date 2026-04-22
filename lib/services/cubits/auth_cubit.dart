import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  const AuthState({
    required this.loggedIn,
    this.email = '',
    this.displayName = '',
    this.errorMessage,
  });

  final bool loggedIn;
  final String email;
  final String displayName;
  final String? errorMessage;

  AuthState copyWith({
    bool? loggedIn,
    String? email,
    String? displayName,
    String? errorMessage,
  }) {
    return AuthState(
      loggedIn: loggedIn ?? this.loggedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      errorMessage: errorMessage,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._prefs, this._pocketBase)
    : super(const AuthState(loggedIn: false));

  final SharedPreferences _prefs;
  final PocketBase _pocketBase;
  static const _resetOtpIdPrefix = 'pb_reset_otp_id_';
  static const _resetOtpIdKey = 'pb_reset_otp_id';
  static const _resetOtpCodeKey = 'pb_reset_otp_code';

  Future<void> restore() async {
    final token = _prefs.getString('pb_auth_token');
    final authRecordRaw = _prefs.getString('pb_auth_record_json');

    if (token != null &&
        token.isNotEmpty &&
        authRecordRaw != null &&
        authRecordRaw.isNotEmpty) {
      try {
        final authRecord = RecordModel.fromJson(
          jsonDecode(authRecordRaw) as Map<String, dynamic>,
        );
        _pocketBase.authStore.save(token, authRecord);
      } catch (_) {
        _pocketBase.authStore.clear();
      }
    }

    emit(
      AuthState(
        loggedIn: _pocketBase.authStore.isValid,
        email: _pocketBase.authStore.record?.getStringValue('email') ?? '',
        displayName: _pocketBase.authStore.record?.getStringValue('name') ?? '',
      ),
    );
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email hoặc mật khẩu không được để trống');
    }
    try {
      final authData = await _pocketBase
          .collection('users')
          .authWithPassword(email, password);
      await _persistAuth(authData);
      emit(
        AuthState(
          loggedIn: true,
          email: authData.record.getStringValue('email'),
          displayName: authData.record.getStringValue('name'),
        ),
      );
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(
          error,
          fallback: 'Email hoặc mật khẩu không đúng',
        ),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      await _pocketBase
          .collection('users')
          .create(
            body: <String, dynamic>{
              'name': name,
              'email': email,
              'password': password,
              'passwordConfirm': password,
              'emailVisibility': true,
            },
          );
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(error, fallback: 'Đăng ký thất bại'),
      );
    }
  }

  Future<void> sendResetOtp(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Email không được để trống');
    }
    try {
      final response = await _pocketBase
          .collection('users')
          .requestOTP(email.trim());
      await _prefs.setString(
        '$_resetOtpIdPrefix${email.trim().toLowerCase()}',
        response.otpId,
      );
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(error, fallback: 'Không thể gửi OTP lúc này'),
      );
    }
  }

  Future<void> resendResetOtp(String email) async {
    await sendResetOtp(email);
  }

  Future<void> verifyResetOtp(String email, String otpCode) async {
    if (email.trim().isEmpty || otpCode.trim().isEmpty) {
      throw Exception('Thiếu email hoặc mã xác thực');
    }
    final normalizedEmail = email.trim().toLowerCase();
    final otpId = _prefs.getString('$_resetOtpIdPrefix$normalizedEmail');
    if (otpId == null || otpId.isEmpty) {
      throw Exception('OTP đã hết hạn. Vui lòng yêu cầu mã mới');
    }
    await _prefs.setString(_resetOtpIdKey, otpId);
    await _prefs.setString(_resetOtpCodeKey, otpCode.trim());
  }

  Future<void> clearResetSession(String email) async {
    await _prefs.remove('$_resetOtpIdPrefix${email.trim().toLowerCase()}');
    await _prefs.remove(_resetOtpIdKey);
    await _prefs.remove(_resetOtpCodeKey);
  }

  Future<void> resetPasswordWithOtp(String newPassword) async {
    if (newPassword.isEmpty) {
      throw Exception('Mật khẩu mới không được để trống');
    }
    final otpId = _prefs.getString(_resetOtpIdKey);
    final otpCode = _prefs.getString(_resetOtpCodeKey);
    if (otpId == null || otpId.isEmpty || otpCode == null || otpCode.isEmpty) {
      throw Exception('Phiên OTP không hợp lệ. Vui lòng xác thực lại OTP');
    }

    try {
      await _pocketBase.send(
        '/api/auth/reset-password-by-otp',
        method: 'POST',
        body: <String, dynamic>{
          'otpId': otpId,
          'otpCode': otpCode,
          'newPassword': newPassword,
        },
      );
      await _prefs.remove(_resetOtpIdKey);
      await _prefs.remove(_resetOtpCodeKey);
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(
          error,
          fallback: 'OTP không hợp lệ hoặc đã hết hạn',
        ),
      );
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!_pocketBase.authStore.isValid ||
        _pocketBase.authStore.record == null) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại');
    }
    try {
      final updated = await _pocketBase
          .collection('users')
          .update(
            _pocketBase.authStore.record!.id,
            body: <String, dynamic>{
              'oldPassword': currentPassword,
              'password': newPassword,
              'passwordConfirm': newPassword,
            },
          );
      _pocketBase.authStore.save(_pocketBase.authStore.token, updated);
      await _prefs.setString(
        'pb_auth_record_json',
        jsonEncode(updated.toJson()),
      );
      emit(
        state.copyWith(
          email: updated.getStringValue('email'),
          displayName: updated.getStringValue('name'),
        ),
      );
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(error, fallback: 'Đổi mật khẩu thất bại'),
      );
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? email,
    String? currentPassword,
  }) async {
    if (!_pocketBase.authStore.isValid ||
        _pocketBase.authStore.record == null) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại');
    }
    try {
      final currentEmail = _pocketBase.authStore.record!.getStringValue(
        'email',
      );
      final shouldUpdateEmail =
          email != null && email.isNotEmpty && email != currentEmail;
      final body = <String, dynamic>{
        'name': displayName,
        'emailVisibility': true,
      };
      if (shouldUpdateEmail) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception('Đổi email cần nhập mật khẩu hiện tại');
        }
        body['email'] = email;
        body['password'] = currentPassword;
      }
      final updated = await _pocketBase
          .collection('users')
          .update(_pocketBase.authStore.record!.id, body: body);
      _pocketBase.authStore.save(_pocketBase.authStore.token, updated);
      await _prefs.setString(
        'pb_auth_record_json',
        jsonEncode(updated.toJson()),
      );
      emit(
        state.copyWith(
          displayName: updated.getStringValue('name'),
          email: updated.getStringValue('email'),
        ),
      );
    } on ClientException catch (error) {
      throw Exception(
        _parsePocketBaseError(error, fallback: 'Cập nhật hồ sơ thất bại'),
      );
    }
  }

  Future<void> logout() async {
    _pocketBase.authStore.clear();
    await _prefs.remove('pb_auth_token');
    await _prefs.remove('pb_auth_record_json');
    emit(const AuthState(loggedIn: false));
  }

  Future<void> _persistAuth(RecordAuth authData) async {
    await _prefs.setString('pb_auth_token', authData.token);
    await _prefs.setString(
      'pb_auth_record_json',
      jsonEncode(authData.record.toJson()),
    );
  }

  String _parsePocketBaseError(
    ClientException error, {
    required String fallback,
  }) {
    final message = error.response['message'];
    if (message is String && message.isNotEmpty) return message;
    final data = error.response['data'];
    if (data is Map<String, dynamic>) {
      for (final value in data.values) {
        if (value is Map<String, dynamic>) {
          final msg = value['message'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      }
    }
    return fallback;
  }
}
