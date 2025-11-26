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

  @override
  String get settings => 'Configuración';

  @override
  String get selectImageSource => 'Seleccionar fuente de imagen';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String get profilePictureUpdated => 'Foto de perfil actualizada exitosamente';

  @override
  String get accountSettings => 'Configuración de cuenta';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get privacy => 'Privacidad';

  @override
  String get help => 'Ayuda y comentarios';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get comingSoon => '¡Próximamente!';

  @override
  String get logoutConfirmation => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get justNow => 'Justo ahora';

  @override
  String minutesAgo(int minutes) {
    return 'Hace ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'Hace ${hours}h';
  }

  @override
  String get at => 'a las';

  @override
  String get searchPlaces => 'Buscar lugares';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get systemNotifications => 'System Notifications';

  @override
  String get notificationPermissionGranted => 'Notifications enabled';

  @override
  String get notificationPermissionGrantedDescription =>
      'You will receive notifications for your selected types';

  @override
  String get notificationPermissionDenied => 'Notifications Disabled';

  @override
  String get notificationPermissionDeniedDescription =>
      'Enable notifications to receive updates';

  @override
  String get notificationPermissionDeniedMessage =>
      'Notification permission was denied. To enable notifications, please go to Settings and allow notifications for Maypole.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get taggingNotifications => 'Tagging Notifications';

  @override
  String get taggingNotificationsDescription =>
      'Get notified when someone tags you in a message';

  @override
  String get directMessageNotifications => 'Direct Message Notifications';

  @override
  String get directMessageNotificationsDescription =>
      'Get notified when you receive a direct message';

  @override
  String get enableSystemNotificationsFirst =>
      'Enable system notifications first to configure notification types';

  @override
  String get noUsersFound => 'No se encontraron usuarios';
}
