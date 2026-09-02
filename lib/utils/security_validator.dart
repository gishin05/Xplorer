class SecurityValidator {
  static final RegExp _illegalFileNameChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Normalizes path by resolving '..' and '.' segments and converting slashes.
  static String normalizePath(String path) {
    var cleaned = path.replaceAll('\\', '/');
    // Remove null bytes
    cleaned = cleaned.replaceAll('\u0000', '');

    final isAbsolute = cleaned.startsWith('/');
    final segments = cleaned.split('/');
    final resolved = <String>[];

    for (final seg in segments) {
      if (seg.isEmpty || seg == '.') {
        continue;
      }
      if (seg == '..') {
        if (resolved.isNotEmpty) {
          resolved.removeLast();
        }
      } else {
        resolved.add(seg);
      }
    }

    final result = resolved.join('/');
    return isAbsolute ? '/$result' : result;
  }

  /// Checks if a requested subpath attempts to traverse outside of [basePath].
  static bool isSafePath(String basePath, String requestedPath) {
    final normBase = normalizePath(basePath);
    final normTarget = normalizePath(requestedPath);

    // If exact match, it's safe
    if (normTarget == normBase) return true;

    // Must start with base path followed by '/'
    if (normTarget.startsWith('$normBase/')) {
      return true;
    }

    return false;
  }

  /// Checks if a file name is valid and does not contain illegal characters or traversal.
  static bool isValidFileName(String name) {
    if (name.trim().isEmpty) return false;
    if (name == '.' || name == '..') return false;
    if (name.length > 255) return false;
    return !_illegalFileNameChars.hasMatch(name);
  }

  /// Sanitizes a file name by replacing illegal characters with an underscore.
  static String sanitizeFileName(String name) {
    var sanitized = name.replaceAll(_illegalFileNameChars, '_').trim();
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = 'unnamed_file';
    }
    if (sanitized.length > 255) {
      sanitized = sanitized.substring(0, 255);
    }
    return sanitized;
  }
}
