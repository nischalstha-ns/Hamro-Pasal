class Validators {
  Validators._();

  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Phone validation (Nepal: 10 digits starting with 9)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^9[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter valid 10-digit number starting with 9';
    }
    return null;
  }

  // Required field validator
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  // Required field (direct)
  static String? requiredField(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Number validation
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    if (double.parse(value!) <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }
    return null;
  }

  // Min length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (value.length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  // Max length
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'This field'} must not exceed $max characters';
    }
    return null;
  }

  // PAN number (Nepal: 9 digits)
  static String? panNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final panRegex = RegExp(r'^[0-9]{9}$');
    if (!panRegex.hasMatch(value)) {
      return 'Enter valid 9-digit PAN number';
    }
    return null;
  }

  // VAT number (Nepal: 9 digits)
  static String? vatNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final vatRegex = RegExp(r'^[0-9]{9}$');
    if (!vatRegex.hasMatch(value)) {
      return 'Enter valid 9-digit VAT number';
    }
    return null;
  }
}
