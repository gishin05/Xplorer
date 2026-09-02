import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/utils/security_validator.dart';

void main() {
  group('SecurityValidator Tests', () {
    test('normalizePath resolves relative segments and slashes', () {
      expect(
        SecurityValidator.normalizePath('/storage/emulated/0/Download/../Documents'),
        '/storage/emulated/0/Documents',
      );
      expect(
        SecurityValidator.normalizePath('C:\\Users\\test\\..\\documents'),
        'C:/Users/documents',
      );
    });

    test('isSafePath blocks path traversal', () {
      const base = '/storage/emulated/0';
      expect(SecurityValidator.isSafePath(base, '/storage/emulated/0/Downloads'), isTrue);
      expect(SecurityValidator.isSafePath(base, '/storage/emulated/0/../etc/passwd'), isFalse);
      expect(SecurityValidator.isSafePath(base, '/system/bin/sh'), isFalse);
    });

    test('isValidFileName rejects illegal characters', () {
      expect(SecurityValidator.isValidFileName('valid_file.txt'), isTrue);
      expect(SecurityValidator.isValidFileName('report-2026.pdf'), isTrue);
      expect(SecurityValidator.isValidFileName('file/with/slash'), isFalse);
      expect(SecurityValidator.isValidFileName('file:with:colon'), isFalse);
      expect(SecurityValidator.isValidFileName('file*wildcard'), isFalse);
      expect(SecurityValidator.isValidFileName('..'), isFalse);
      expect(SecurityValidator.isValidFileName(''), isFalse);
    });

    test('sanitizeFileName removes illegal characters safely', () {
      expect(
        SecurityValidator.sanitizeFileName('my<file>?test*.zip'),
        'my_file__test_.zip',
      );
      expect(
        SecurityValidator.sanitizeFileName('..'),
        'unnamed_file',
      );
    });
  });
}
