import 'package:flutter_test/flutter_test.dart';
import 'package:maypole/core/utils/string_utils.dart';

void main() {
  group('StringUtils - validateUsername', () {
    test('returns error for null input', () {
      final result = StringUtils.validateUsername(null);
      expect(result, isNotNull);
      expect(result, contains('Please enter a username'));
    });

    test('returns error for empty string', () {
      final result = StringUtils.validateUsername('');
      expect(result, isNotNull);
      expect(result, contains('Please enter a username'));
    });

    test('returns error for username less than 3 characters', () {
      final result = StringUtils.validateUsername('ab');
      expect(result, isNotNull);
      expect(result, contains('at least 3 characters'));
    });

    test('returns null for valid 3 character username', () {
      final result = StringUtils.validateUsername('abc');
      expect(result, isNull);
    });

    test('returns null for valid alphanumeric username', () {
      final result = StringUtils.validateUsername('user123');
      expect(result, isNull);
    });

    test('returns null for username with underscores', () {
      final result = StringUtils.validateUsername('user_name_123');
      expect(result, isNull);
    });

    test('returns error for username with spaces', () {
      final result = StringUtils.validateUsername('user name');
      expect(result, isNotNull);
      expect(result, contains('can only contain'));
    });

    test('returns error for username with special characters', () {
      final result = StringUtils.validateUsername('user@name');
      expect(result, isNotNull);
      expect(result, contains('can only contain'));
    });

    test('returns error for username with hyphens', () {
      final result = StringUtils.validateUsername('user-name');
      expect(result, isNotNull);
      expect(result, contains('can only contain'));
    });

    test('returns null for long valid username', () {
      final result = StringUtils.validateUsername('very_long_username_123');
      expect(result, isNull);
    });

    test('returns null for username with uppercase letters', () {
      final result = StringUtils.validateUsername('UserName123');
      expect(result, isNull);
    });
  });

  group('StringUtils - validateEmail', () {
    test('returns error for null input', () {
      final result = StringUtils.validateEmail(null);
      expect(result, isNotNull);
      expect(result, contains('Please enter your email'));
    });

    test('returns error for empty string', () {
      final result = StringUtils.validateEmail('');
      expect(result, isNotNull);
      expect(result, contains('Please enter your email'));
    });

    test('returns error for invalid email without @', () {
      final result = StringUtils.validateEmail('notanemail.com');
      expect(result, isNotNull);
      expect(result, contains('valid email'));
    });

    test('returns error for invalid email without domain', () {
      final result = StringUtils.validateEmail('user@');
      expect(result, isNotNull);
      expect(result, contains('valid email'));
    });

    test('returns error for invalid email without TLD', () {
      final result = StringUtils.validateEmail('user@domain');
      expect(result, isNotNull);
      expect(result, contains('valid email'));
    });

    test('returns null for valid simple email', () {
      final result = StringUtils.validateEmail('user@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email with subdomain', () {
      final result = StringUtils.validateEmail('user@mail.example.com');
      expect(result, isNull);
    });

    test('returns null for valid email with plus sign', () {
      final result = StringUtils.validateEmail('user+tag@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email with dots', () {
      final result = StringUtils.validateEmail('first.last@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email with numbers', () {
      final result = StringUtils.validateEmail('user123@example123.com');
      expect(result, isNull);
    });
  });

  group('StringUtils - validatePassword', () {
    test('returns error for null input', () {
      final result = StringUtils.validatePassword(null);
      expect(result, isNotNull);
      expect(result, contains('Please enter a password'));
    });

    test('returns error for empty string', () {
      final result = StringUtils.validatePassword('');
      expect(result, isNotNull);
      expect(result, contains('Please enter a password'));
    });

    test('returns error for password less than 6 characters', () {
      final result = StringUtils.validatePassword('12345');
      expect(result, isNotNull);
      expect(result, contains('at least 6 characters'));
    });

    test('returns null for password with exactly 6 characters', () {
      final result = StringUtils.validatePassword('123456');
      expect(result, isNull);
    });

    test('returns null for password with more than 6 characters', () {
      final result = StringUtils.validatePassword('password123');
      expect(result, isNull);
    });

    test('returns null for password with special characters', () {
      final result = StringUtils.validatePassword('p@ssw0rd!');
      expect(result, isNull);
    });

    test('returns null for password with spaces', () {
      final result = StringUtils.validatePassword('pass word 123');
      expect(result, isNull);
    });

    test('returns null for long password', () {
      final result = StringUtils.validatePassword('this_is_a_very_long_password_123');
      expect(result, isNull);
    });
  });
}
