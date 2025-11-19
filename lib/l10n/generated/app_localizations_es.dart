// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Maypole';

  @override
  String get appTitleDev => 'Maypole (Dev)';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get maypolesTab => 'Maypoles';

  @override
  String get directMessagesTab => 'Mensajes directos';

  @override
  String get noPlaceChats => 'Aún no hay chats de lugares.';

  @override
  String get noDirectMessages => 'Aún no hay mensajes directos.';

  @override
  String lastMessage(String time) {
    return 'Último mensaje: $time';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String welcome(String email) {
    return 'Bienvenido $email';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get register => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Iniciar sesión';

  @override
  String get continueToApp => 'Continuar a la aplicación';

  @override
  String get pleaseEnterEmail => 'Por favor ingrese su correo electrónico';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor ingrese un correo electrónico válido';

  @override
  String get pleaseEnterPassword => 'Por favor ingrese su contraseña';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get searchMaypoles => 'Buscar Maypoles';

  @override
  String get searchForMaypole => 'Buscar un maypole';

  @override
  String get enterMessage => 'Ingrese un mensaje';

  @override
  String get devEnvironment => 'DEV';
}
