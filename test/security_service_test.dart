import 'package:flutter_test/flutter_test.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

void main() {
  group('SecurityService', () {
    test('hashPassword and verifyPassword work correctly', () {
      const password = 'Admin@123';
      final hash = SecurityService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(SecurityService.verifyPassword(password, hash), isTrue);
      expect(SecurityService.verifyPassword('wrongPassword', hash), isFalse);
    });

    test('normalizeEmail trims and lowercases', () {
      final normalized = SecurityService.normalizeEmail('  USER@Example.COM  ');
      expect(normalized, equals('user@example.com'));
    });

    test('normalizeName collapses repeated spaces', () {
      final normalized = SecurityService.normalizeName('  Jane   Doe  ');
      expect(normalized, equals('Jane Doe'));
    });

    test('isStrongPassword validates complexity', () {
      expect(SecurityService.isStrongPassword('abc'), isFalse);
      expect(SecurityService.isStrongPassword('Abcdefgh'), isFalse);
      expect(SecurityService.isStrongPassword('Abcdefg1'), isFalse);
      expect(SecurityService.isStrongPassword('Abcdefg1!'), isTrue);
    });
  });

  group('ValidationService', () {
    test('validateEmail checks format and length', () {
      expect(ValidationService.validateEmail(null), isNotNull);
      expect(ValidationService.validateEmail('bad-email'), isNotNull);
      expect(ValidationService.validateEmail('valid@mail.com'), isNull);
    });

    test('validatePassword enforces strong password policy', () {
      expect(ValidationService.validatePassword('weakpass'), isNotNull);
      expect(ValidationService.validatePassword('StrongPass1!'), isNull);
    });

    test('validateName checks normalized boundaries', () {
      expect(ValidationService.validateName(''), isNotNull);
      expect(ValidationService.validateName('A'), isNotNull);
      expect(ValidationService.validateName('John Doe'), isNull);
    });

    test('validatePhone accepts optional and checks format', () {
      expect(ValidationService.validatePhone(''), isNull);
      expect(ValidationService.validatePhone('+60123456789'), isNull);
      expect(ValidationService.validatePhone('abc'), isNotNull);
    });
  });
}
