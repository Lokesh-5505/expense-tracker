import 'dart:convert';

class AppValidators {
  /// Validate money amount
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final cleaned = value.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    if (parsed > 1000000000) {
      return 'Amount exceeds maximum allowable limit';
    }
    return null;
  }

  /// Validate title or name
  static String? validateTitle(String? value, {String fieldName = 'Title'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (value.trim().length > 60) {
      return '$fieldName must be 60 characters or fewer';
    }
    return null;
  }

  /// Validate 4-digit PIN
  static String? validatePin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN is required';
    }
    if (value.length != 4 || int.tryParse(value) == null) {
      return 'PIN must be exactly 4 digits';
    }
    return null;
  }

  /// Validate backup JSON payload
  static Map<String, dynamic>? validateBackupJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (!decoded.containsKey('version') || !decoded.containsKey('data')) {
        return null;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }
      // Must contain at least transactions or categories or wallets
      if (!data.containsKey('transactions') && !data.containsKey('categories')) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }
}
