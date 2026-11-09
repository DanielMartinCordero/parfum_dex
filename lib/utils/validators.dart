/// Clase que agrupa todas las validaciones de texto para formularios.
/// Al tener esto separado, podemos reutilizarlo en Login y Registro
/// sin duplicar código (principio DRY).
class Validators {
  static const double maxPurchasePrice = 2000;
  static const double maxRating = 5;
  static const int maxCapacityMl = 1000;
  static const int maxNameLength = 50;

  /// Valida que el correo no esté vacío y tenga un formato válido.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Introduce un correo electrónico válido (ej. usuario@dominio.com)';
    }

    return null;
  }

  /// Valida que el nombre público no esté vacío.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    // Mismo máximo que comprueban las reglas de Firestore (lib/firestore.rules)
    if (value.trim().length > maxNameLength) {
      return 'El nombre no puede superar los $maxNameLength caracteres';
    }
    return null;
  }

  /// Valida las reglas de seguridad de la contraseña.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    } else if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Valida que la contraseña de confirmación sea idéntica a la original.
  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != originalPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Valida la capacidad del bote. Es opcional: null significa "sin capacidad".
  static String? validateCapacityMl(int? value) {
    if (value == null) return null;
    if (value <= 0) {
      return 'La capacidad debe ser mayor que 0';
    }
    if (value > maxCapacityMl) {
      return 'La capacidad no puede superar los $maxCapacityMl ml';
    }
    return null;
  }

  /// Valida que los ml restantes estén entre 0 y la capacidad del bote.
  static String? validateRemainingMl(double value, int capacityMl) {
    if (value.isNaN || value < 0) {
      return 'Los mililitros no pueden ser negativos';
    }
    if (value > capacityMl) {
      return 'El bote solo tiene $capacityMl ml de capacidad';
    }
    return null;
  }

  /// Valida el precio de compra. Es opcional: null significa "sin precio".
  static String? validatePurchasePrice(double? value) {
    if (value == null) return null;
    if (value.isNaN || value < 0) {
      return 'El precio no puede ser negativo';
    }
    if (value > maxPurchasePrice) {
      return 'El precio no puede superar los ${maxPurchasePrice.toStringAsFixed(0)} €';
    }
    return null;
  }

  /// Valida la valoración. Es opcional: null significa "sin valorar".
  static String? validateRating(double? value) {
    if (value == null) return null;
    if (value.isNaN || value < 0 || value > maxRating) {
      return 'La valoración debe estar entre 0 y ${maxRating.toStringAsFixed(0)}';
    }
    return null;
  }
}
