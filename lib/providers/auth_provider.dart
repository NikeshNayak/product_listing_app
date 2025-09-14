import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final authStateProvider = StateNotifierProvider<AuthNotifier, UserModel?>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _service;

  AuthNotifier(this._service) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final user = await _service.currentUser();
    state = user;
  }

  Future<void> register(
    String name,
    String email,
    String password,
    File profileImage,
  ) async {
    await _service.register(name, email, password, profileImage);
    final user = await _service.currentUser();
    state = user;
  }

  Future<bool> login(String email, String password) async {
    final user = await _service.login(email, password);
    if (user != null) state = user;
    return user != null;
  }

  Future<void> updateProfile(String name) async {
    if (state == null) return;
    await _service.updateProfile(name);
  }

  Future<void> logout() async {
    await _service.logout();
    state = null;
  }
}
