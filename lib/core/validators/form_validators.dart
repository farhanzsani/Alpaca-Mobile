/// Centralized form validators for the ALPACA application.
///
/// Provides reusable validation functions for form fields
/// with user-friendly error messages in Indonesian.
library;

/// Centralized form validation utilities.
///
/// All validators return `null` when valid, or an error message string
/// when invalid. This matches Flutter's [FormField.validator] signature.
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: FormValidators.email,
/// )
///
/// TextFormField(
///   validator: (value) => FormValidators.compose([
///     () => FormValidators.required(value, fieldName: 'Nama'),
///     () => FormValidators.minLength(value, 3, fieldName: 'Nama'),
///   ]),
/// )
/// ```
abstract final class FormValidators {
  // ─── General Validators ──────────────────────────────────────────────

  /// Validates that a field is not empty.
  ///
  /// [value] - The field value to validate.
  /// [fieldName] - Optional field name for the error message.
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validates minimum string length.
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) return null; // Let required handle empty
    if (value.trim().length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }

  /// Validates maximum string length.
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > max) {
      return '$fieldName maksimal $max karakter';
    }
    return null;
  }

  // ─── Email Validator ─────────────────────────────────────────────────

  /// Email regex pattern.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // ─── Password Validators ─────────────────────────────────────────────

  /// Validates a password meets minimum requirements.
  ///
  /// Requirements:
  /// - At least 8 characters
  /// - Contains at least one uppercase letter
  /// - Contains at least one lowercase letter
  /// - Contains at least one digit
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal 8 karakter';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Kata sandi harus mengandung huruf besar';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Kata sandi harus mengandung huruf kecil';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Kata sandi harus mengandung angka';
    }
    return null;
  }

  /// Validates that the confirmation password matches.
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != originalPassword) {
      return 'Kata sandi tidak cocok';
    }
    return null;
  }

  // ─── Numeric Validators ──────────────────────────────────────────────

  /// Validates that a value is a valid number.
  static String? numeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    if (double.tryParse(cleaned) == null) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  /// Validates that a value is a valid integer.
  static String? integer(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll('.', '');
    if (int.tryParse(cleaned) == null) {
      return '$fieldName harus berupa bilangan bulat';
    }
    return null;
  }

  /// Validates a minimum numeric value.
  static String? minValue(
    String? value,
    num min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    final number = double.tryParse(cleaned);
    if (number == null) return '$fieldName harus berupa angka';
    if (number < min) {
      return '$fieldName minimal $min';
    }
    return null;
  }

  /// Validates a maximum numeric value.
  static String? maxValue(
    String? value,
    num max, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    final number = double.tryParse(cleaned);
    if (number == null) return '$fieldName harus berupa angka';
    if (number > max) {
      return '$fieldName maksimal $max';
    }
    return null;
  }

  // ─── Price Validator ─────────────────────────────────────────────────

  /// Validates a price field (Indonesian Rupiah).
  ///
  /// - Must be a valid number
  /// - Must be >= 0
  /// - Must not exceed 999,999,999,999 (1 trillion)
  static String? price(String? value, {bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga wajib diisi';
    }

    // Remove Rp prefix, dots (thousand separator), and spaces.
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .trim();

    final number = double.tryParse(cleaned);
    if (number == null) {
      return 'Format harga tidak valid';
    }
    if (number < 0) {
      return 'Harga tidak boleh negatif';
    }
    if (!allowZero && number == 0) {
      return 'Harga harus lebih dari 0';
    }
    if (number > 999999999999) {
      return 'Harga melebihi batas maksimum';
    }
    return null;
  }

  // ─── Inventory Quantity Validator ────────────────────────────────────

  /// Validates an inventory quantity.
  ///
  /// - Must be a valid integer
  /// - Must be >= 0
  /// - Must not exceed 999,999
  static String? inventoryQuantity(String? value, {bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah stok wajib diisi';
    }

    final cleaned = value.replaceAll('.', '').replaceAll(' ', '').trim();
    final number = int.tryParse(cleaned);

    if (number == null) {
      return 'Jumlah stok harus berupa bilangan bulat';
    }
    if (number < 0) {
      return 'Jumlah stok tidak boleh negatif';
    }
    if (!allowZero && number == 0) {
      return 'Jumlah stok harus lebih dari 0';
    }
    if (number > 999999) {
      return 'Jumlah stok melebihi batas maksimum';
    }
    return null;
  }

  // ─── Phone Number Validator ──────────────────────────────────────────

  /// Validates an Indonesian phone number.
  ///
  /// Accepts formats:
  /// - 08xxxxxxxxxx
  /// - +628xxxxxxxxxx
  /// - 628xxxxxxxxxx
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon wajib diisi';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Check valid Indonesian phone patterns.
    final phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{7,11}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  // ─── URL Validator ───────────────────────────────────────────────────

  /// Validates a URL.
  static String? url(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Format $fieldName tidak valid';
    }
    return null;
  }

  // ─── Composition ─────────────────────────────────────────────────────

  /// Composes multiple validators, returning the first error found.
  ///
  /// Usage:
  /// ```dart
  /// TextFormField(
  ///   validator: (value) => FormValidators.compose([
  ///     () => FormValidators.required(value, fieldName: 'Nama Produk'),
  ///     () => FormValidators.minLength(value, 3, fieldName: 'Nama Produk'),
  ///     () => FormValidators.maxLength(value, 100, fieldName: 'Nama Produk'),
  ///   ]),
  /// )
  /// ```
  static String? compose(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }

  /// Creates a validator function from a list of validator closures.
  ///
  /// Useful for creating reusable composed validators:
  /// ```dart
  /// final productNameValidator = FormValidators.createValidator([
  ///   (v) => FormValidators.required(v, fieldName: 'Nama Produk'),
  ///   (v) => FormValidators.minLength(v, 3, fieldName: 'Nama Produk'),
  /// ]);
  ///
  /// TextFormField(validator: productNameValidator)
  /// ```
  static String? Function(String?) createValidator(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
