import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static const _uuid = Uuid();

  /// Simulates / performs user login with validation
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simulates realistic network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Por favor introduce un correo electrónico válido');
    }
    if (password.trim().length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    // Check if an existing stored user matches, otherwise create session
    final existingUser = await StorageService.getUser();
    final user = (existingUser != null && existingUser.email == cleanEmail)
        ? existingUser
        : UserModel(
            id: _uuid.v4(),
            email: cleanEmail,
            username: cleanEmail.split('@').first,
          );

    await StorageService.saveUser(user);
    return user;
  }

  /// Register a new account
  static Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final cleanUsername = username.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanUsername.isEmpty || cleanUsername.length < 3) {
      throw Exception('El nombre de usuario debe tener al menos 3 caracteres');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Introduce un correo electrónico válido');
    }
    if (password.trim().length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final newUser = UserModel(
      id: _uuid.v4(),
      email: cleanEmail,
      username: cleanUsername,
    );

    await StorageService.saveUser(newUser);
    return newUser;
  }

  /// Continue as guest
  static Future<UserModel> continueAsGuest() async {
    final guestUser = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'invitado@mydeck.app',
      username: 'Planeswalker Invitado',
    );
    await StorageService.setGuestMode(true);
    await StorageService.saveUser(guestUser);
    return guestUser;
  }

  /// Logout current session
  static Future<void> logout() async {
    await StorageService.clearUser();
  }

  /// Check if user is already logged in
  static Future<UserModel?> getCurrentUser() async {
    return await StorageService.getUser();
  }
}
