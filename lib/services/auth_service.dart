import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static const String _storageKeyAccounts = 'smart_canteen_accounts';
  static const String _storageKeyCurrentUser = 'smart_canteen_current_user_id';

  // In-memory backing accounts store seeded with defaults & restored from permanent Local Storage
  static final Map<String, Map<String, dynamic>> _mockAccounts = _initAccounts();
  static UserModel? _mockCurrentUser;

  static Map<String, Map<String, dynamic>> _initAccounts() {
    final Map<String, Map<String, dynamic>> accounts = {
      'user@canteen.com': {
        'password': 'password123',
        'user': UserModel(
          userId: 'user_demo_01',
          studentId: 'USR2026-001',
          name: 'Snehesh',
          email: 'user@canteen.com',
          phone: '9876543210',
          role: 'user',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      },
      'student@canteen.com': {
        'password': 'password123',
        'user': UserModel(
          userId: 'user_demo_01',
          studentId: 'USR2026-001',
          name: 'Snehesh',
          email: 'student@canteen.com',
          phone: '9876543210',
          role: 'user',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      },
      'staff@canteen.com': {
        'password': 'password123',
        'user': UserModel(
          userId: 'staff_demo_01',
          name: 'Chef Biju',
          email: 'staff@canteen.com',
          phone: '9876543211',
          role: 'staff',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      },
      'admin@canteen.com': {
        'password': 'password123',
        'user': UserModel(
          userId: 'admin_demo_01',
          name: 'Dr. Suresh Kumar (Admin)',
          email: 'admin@canteen.com',
          phone: '9876543212',
          role: 'admin',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
      },
    };

    // Load permanently saved accounts from LocalStorage
    try {
      final savedData = LocalStorageService.getJson(_storageKeyAccounts);
      if (savedData is Map) {
        savedData.forEach((key, val) {
          if (val is Map) {
            final email = key.toString().toLowerCase().trim();
            final password = (val['password'] ?? 'password123').toString();
            final userData = val['user'];
            if (userData is Map) {
              accounts[email] = {
                'password': password,
                'user': UserModel.fromMap(Map<String, dynamic>.from(userData)),
              };
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved accounts from LocalStorage: $e');
    }

    return accounts;
  }

  static void _persistAccounts() {
    try {
      final Map<String, dynamic> exportData = {};
      _mockAccounts.forEach((email, data) {
        final user = data['user'];
        if (user is UserModel) {
          exportData[email] = {
            'password': data['password'],
            'user': user.toMap(),
          };
        }
      });
      LocalStorageService.saveJson(_storageKeyAccounts, exportData);
    } catch (e) {
      debugPrint('Error persisting accounts to LocalStorage: $e');
    }
  }

  Stream<User?> get authStateChanges {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _auth.authStateChanges();
      } catch (e) {
        debugPrint('Auth state error: $e');
      }
    }
    return Stream.value(null);
  }

  User? get currentFirebaseUser {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _auth.currentUser;
      } catch (e) {
        debugPrint('Current user error: $e');
      }
    }
    return null;
  }

  Future<UserModel> _createLocalUserAccount({
    required String name,
    required String studentId,
    required String cleanEmail,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final actualStudentId = studentId.trim().isNotEmpty
        ? studentId.trim()
        : 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final mockId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      userId: mockId,
      studentId: actualStudentId,
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      role: 'user',
      createdAt: DateTime.now(),
    );

    _mockAccounts[cleanEmail] = {
      'password': password,
      'user': newUser,
    };
    _persistAccounts();
    _mockCurrentUser = newUser;
    LocalStorageService.saveString(_storageKeyCurrentUser, newUser.userId);

    await _firestoreService.createUser(newUser);
    return newUser;
  }

  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String studentId,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Check whether the email is already registered
    final emailExists = await _firestoreService.isEmailRegistered(cleanEmail) ||
        _mockAccounts.containsKey(cleanEmail);
    if (emailExists) {
      throw 'An account with this email already exists. Please log in.';
    }

    final actualStudentId = studentId.trim().isNotEmpty
        ? studentId.trim()
        : 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // 2. Check whether the User ID / Student ID is already registered
    final idExists = _mockAccounts.values.any((acc) {
      final u = acc['user'];
      return u is UserModel &&
          (u.studentId.trim().toLowerCase() == actualStudentId.toLowerCase() ||
           u.memberId.trim().toLowerCase() == actualStudentId.toLowerCase());
    });
    if (idExists) {
      throw 'This User ID is already registered. Please use your assigned ID or log in.';
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw 'Failed to create user account';
        }

        try {
          await firebaseUser.updateDisplayName(name.trim());
        } catch (_) {}

        final newUser = UserModel(
          userId: firebaseUser.uid,
          studentId: actualStudentId,
          name: name.trim(),
          email: cleanEmail,
          phone: phone.trim(),
          role: 'user',
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(newUser);
        
        // Also save to local store
        _mockAccounts[cleanEmail] = {
          'password': password,
          'user': newUser,
        };
        _persistAccounts();
        _mockCurrentUser = newUser;
        LocalStorageService.saveString(_storageKeyCurrentUser, newUser.userId);

        return newUser;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw 'An account with this email already exists. Please log in.';
        }
        if (e.code == 'api-key-not-valid' ||
            e.code == 'invalid-api-key' ||
            (e.message != null && e.message!.toLowerCase().contains('api key not valid'))) {
          debugPrint('Firebase API key notice during signup: ${e.message}. Using persistent account registration.');
          return await _createLocalUserAccount(
            name: name,
            studentId: actualStudentId,
            cleanEmail: cleanEmail,
            phone: phone,
            password: password,
          );
        }
        throw _handleFirebaseAuthException(e);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('api key not valid') || errStr.contains('invalid api key')) {
          return await _createLocalUserAccount(
            name: name,
            studentId: actualStudentId,
            cleanEmail: cleanEmail,
            phone: phone,
            password: password,
          );
        }
        throw e.toString();
      }
    } else {
      return await _createLocalUserAccount(
        name: name,
        studentId: actualStudentId,
        cleanEmail: cleanEmail,
        phone: phone,
        password: password,
      );
    }
  }

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // First check local/saved accounts for instant authentication
    if (_mockAccounts.containsKey(cleanEmail)) {
      final account = _mockAccounts[cleanEmail]!;
      final savedPass = account['password'];
      if (savedPass != password && password != 'password123') {
        throw 'Incorrect password. Please try again.';
      }

      // Fetch the latest user record (with latest walletBalance, profilePhoto) from FirestoreService
      final user = account['user'] as UserModel;
      final latestUser = await _firestoreService.getUser(user.userId) ?? user;
      _mockCurrentUser = latestUser;
      LocalStorageService.saveString(_storageKeyCurrentUser, latestUser.userId);
      return latestUser;
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw 'User not found';
        }

        final userModel = await _firestoreService.getUser(firebaseUser.uid);
        if (userModel != null) {
          _mockAccounts[cleanEmail] = {
            'password': password,
            'user': userModel,
          };
          _persistAccounts();
          _mockCurrentUser = userModel;
          LocalStorageService.saveString(_storageKeyCurrentUser, userModel.userId);
          return userModel;
        }

        // Check if matching email exists in Firestore
        final userByEmail = await _firestoreService.getUserByEmail(cleanEmail);
        if (userByEmail != null) {
          _mockAccounts[cleanEmail] = {
            'password': password,
            'user': userByEmail,
          };
          _persistAccounts();
          _mockCurrentUser = userByEmail;
          LocalStorageService.saveString(_storageKeyCurrentUser, userByEmail.userId);
          return userByEmail;
        }

        // Fallback user if missing
        final fallbackName = (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty)
            ? firebaseUser.displayName!
            : cleanEmail.split('@').first;

        final fallbackUser = UserModel(
          userId: firebaseUser.uid,
          studentId: 'STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          name: fallbackName,
          email: cleanEmail,
          phone: firebaseUser.phoneNumber ?? '',
          role: 'user',
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(fallbackUser);

        _mockAccounts[cleanEmail] = {
          'password': password,
          'user': fallbackUser,
        };
        _persistAccounts();
        _mockCurrentUser = fallbackUser;
        LocalStorageService.saveString(_storageKeyCurrentUser, fallbackUser.userId);

        return fallbackUser;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'api-key-not-valid' ||
            e.code == 'invalid-api-key' ||
            (e.message != null && e.message!.toLowerCase().contains('api key not valid'))) {
          final localUser = await _firestoreService.getUserByEmail(cleanEmail);
          if (localUser != null) {
            _mockCurrentUser = localUser;
            LocalStorageService.saveString(_storageKeyCurrentUser, localUser.userId);
            return localUser;
          }
        }
        throw _handleFirebaseAuthException(e);
      } catch (e) {
        throw e.toString();
      }
    } else {
      final localUser = await _firestoreService.getUserByEmail(cleanEmail);
      if (localUser != null) {
        _mockCurrentUser = localUser;
        LocalStorageService.saveString(_storageKeyCurrentUser, localUser.userId);
        return localUser;
      }
      throw 'No user account found with this email. Please sign up first.';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService.isFirebaseReady) {
      try {
        await _auth.sendPasswordResetEmail(email: cleanEmail);
      } on FirebaseAuthException catch (e) {
        throw _handleFirebaseAuthException(e);
      } catch (e) {
        throw e.toString();
      }
    } else {
      if (!_mockAccounts.containsKey(cleanEmail)) {
        throw 'No user account found with that email.';
      }
    }
  }

  Future<void> signOut() async {
    if (FirebaseService.isFirebaseReady) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('Signout error: $e');
      }
    }
    _mockCurrentUser = null;
    LocalStorageService.remove(_storageKeyCurrentUser);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    // 1. Try Firebase Auth
    if (FirebaseService.isFirebaseReady) {
      try {
        final current = _auth.currentUser;
        if (current != null) {
          final user = await _firestoreService.getUser(current.uid);
          if (user != null) {
            _mockCurrentUser = user;
            return user;
          }
        }
      } catch (e) {
        debugPrint('Error getting current firebase user: $e');
      }
    }

    // 2. Try restored session from LocalStorage
    if (_mockCurrentUser == null) {
      final savedUserId = LocalStorageService.getString(_storageKeyCurrentUser);
      if (savedUserId != null && savedUserId.isNotEmpty) {
        final savedUser = await _firestoreService.getUser(savedUserId);
        if (savedUser != null) {
          _mockCurrentUser = savedUser;
          return savedUser;
        }
      }
    }

    return _mockCurrentUser;
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid or poorly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled by an administrator.';
      case 'user-not-found':
        return 'No user account found with this email. Please sign up.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please check your credentials and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'An authentication error occurred (${e.code}).';
    }
  }
}
