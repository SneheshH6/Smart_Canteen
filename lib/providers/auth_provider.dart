import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _userSubscription;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  AuthProvider() {
    _init();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _startUserListener(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _firestoreService.getUserStream(userId).listen((user) {
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    });
  }

  Future<void> _init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        _currentUser = user;
        _startUserListener(user.userId);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (_currentUser != null) {
        _startUserListener(_currentUser!.userId);
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String studentId,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmailPassword(
        name: name,
        studentId: studentId,
        email: email,
        phone: phone,
        password: password,
      );
      if (_currentUser != null) {
        _startUserListener(_currentUser!.userId);
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorMessage = null;
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? profilePhoto,
  }) async {
    if (_currentUser == null) return false;

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        profilePhoto: profilePhoto ?? _currentUser!.profilePhoto,
      );
      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.authenticated; // keep logged in
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        profilePhoto: photoUrl,
      );
      await _firestoreService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWalletMoney(double amount, {String description = 'Wallet Top-Up (UPI)'}) async {
    if (_currentUser == null) return false;
    try {
      final newBalance = await _firestoreService.addWalletMoney(
        _currentUser!.userId,
        amount,
        description: description,
      );
      _currentUser = _currentUser!.copyWith(walletBalance: newBalance);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deductWalletMoney(double amount, {required String orderId, required String description}) async {
    if (_currentUser == null) return false;
    try {
      final newBalance = await _firestoreService.deductWalletMoney(
        _currentUser!.userId,
        amount,
        orderId: orderId,
        description: description,
      );
      _currentUser = _currentUser!.copyWith(walletBalance: newBalance);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _userSubscription?.cancel();
    _userSubscription = null;

    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
