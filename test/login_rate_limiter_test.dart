import 'package:flutter_test/flutter_test.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

void main() {
  group('LoginRateLimiter', () {
    const email = 'tester@example.com';

    setUp(() {
      LoginRateLimiter.resetForTests();
    });

    test('allows attempts before threshold', () {
      for (int i = 0; i < LoginRateLimiter.maxAttempts - 1; i++) {
        expect(LoginRateLimiter.canAttempt(email), isTrue);
        LoginRateLimiter.recordFailed(email);
      }
      expect(LoginRateLimiter.canAttempt(email), isTrue);
    });

    test('locks account after threshold reached', () {
      for (int i = 0; i < LoginRateLimiter.maxAttempts; i++) {
        LoginRateLimiter.recordFailed(email);
      }

      expect(LoginRateLimiter.canAttempt(email), isFalse);
      expect(LoginRateLimiter.remainingSeconds(email), greaterThan(0));
    });

    test('recordSuccess clears lock and attempts', () {
      for (int i = 0; i < LoginRateLimiter.maxAttempts; i++) {
        LoginRateLimiter.recordFailed(email);
      }

      expect(LoginRateLimiter.canAttempt(email), isFalse);
      LoginRateLimiter.recordSuccess(email);
      expect(LoginRateLimiter.canAttempt(email), isTrue);
      expect(LoginRateLimiter.remainingSeconds(email), equals(0));
    });
  });
}
