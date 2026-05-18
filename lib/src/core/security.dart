import 'package:crypto/crypto.dart';
import 'dart:convert';

class SessionPolicy {
  static const Duration inactivityTimeout = Duration(minutes: 15);
}

class SecurityService {
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String normalizeName(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    // At least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
  }
}

class ValidationService {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final normalized = SecurityService.normalizeEmail(email);
    if (normalized.length > 120) {
      return 'Email is too long';
    }
    if (!SecurityService.isValidEmail(normalized)) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length > 128) {
      return 'Password is too long';
    }
    if (!SecurityService.isStrongPassword(password)) {
      return 'Use 8+ chars with uppercase, lowercase, number, and symbol';
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    final normalized = SecurityService.normalizeName(name);
    if (normalized.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (normalized.length > 80) {
      return 'Name is too long';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // optional field
    }
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  static String? validateHallName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Hall name is required';
    }
    if (name.length < 3) {
      return 'Hall name must be at least 3 characters';
    }
    return null;
  }

  static String? validateCapacity(int? capacity) {
    if (capacity == null || capacity <= 0) {
      return 'Capacity must be greater than 0';
    }
    if (capacity > 10000) {
      return 'Capacity cannot exceed 10,000';
    }
    return null;
  }

  static String? validatePrice(double? price) {
    if (price == null || price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }
}

class LoginRateLimiter {
  static final Map<String, int> _attempts = {};
  static final Map<String, DateTime> _lockUntil = {};

  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 5);

  static bool canAttempt(String email) {
    final key = SecurityService.normalizeEmail(email);
    final lock = _lockUntil[key];
    if (lock == null) return true;

    if (DateTime.now().isAfter(lock)) {
      _lockUntil.remove(key);
      _attempts.remove(key);
      return true;
    }
    return false;
  }

  static int remainingSeconds(String email) {
    final key = SecurityService.normalizeEmail(email);
    final lock = _lockUntil[key];
    if (lock == null) return 0;
    final diff = lock.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  static void recordFailed(String email) {
    final key = SecurityService.normalizeEmail(email);
    final attempts = (_attempts[key] ?? 0) + 1;
    _attempts[key] = attempts;

    if (attempts >= maxAttempts) {
      _lockUntil[key] = DateTime.now().add(lockDuration);
    }
  }

  static void recordSuccess(String email) {
    final key = SecurityService.normalizeEmail(email);
    _attempts.remove(key);
    _lockUntil.remove(key);
  }

  static void resetForTests() {
    _attempts.clear();
    _lockUntil.clear();
  }
}
