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
  String get notificationSettings => 'Configuración de notificaciones';

  @override
  String get systemNotifications => 'Notificaciones del sistema';

  @override
  String get notificationPermissionGranted => 'Notificaciones habilitadas';

  @override
  String get notificationPermissionGrantedDescription =>
      'Recibirás notificaciones para los tipos seleccionados';

  @override
  String get notificationPermissionDenied => 'Notificaciones deshabilitadas';

  @override
  String get notificationPermissionDeniedDescription =>
      'Habilita las notificaciones para recibir actualizaciones';

  @override
  String get notificationPermissionDeniedMessage =>
      'El permiso de notificación fue denegado. Para habilitar las notificaciones, ve a Configuración y permite las notificaciones para Maypole.';

  @override
  String get enableNotifications => 'Habilitar notificaciones';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get notificationTypes => 'Tipos de notificaciones';

  @override
  String get taggingNotifications => 'Notificaciones de etiquetas';

  @override
  String get taggingNotificationsDescription =>
      'Recibe notificaciones cuando alguien te etiquete en un mensaje';

  @override
  String get directMessageNotifications =>
      'Notificaciones de mensajes directos';

  @override
  String get directMessageNotificationsDescription =>
      'Recibe notificaciones cuando recibas un mensaje directo';

  @override
  String get enableSystemNotificationsFirst =>
      'Habilita las notificaciones del sistema primero para configurar los tipos de notificaciones';

  @override
  String get noUsersFound => 'No se encontraron usuarios';

  @override
  String get errorTitle => 'Error';

  @override
  String get dismiss => 'Descartar';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirmation =>
      '¿Está seguro de que desea eliminar su cuenta? Esta acción no se puede deshacer. Todos sus datos serán eliminados permanentemente.';

  @override
  String get accountDeleted => 'Cuenta eliminada exitosamente';

  @override
  String get delete => 'Eliminar';

  @override
  String get directMessage => 'Mensaje directo';

  @override
  String get block => 'Bloquear';

  @override
  String get blocked => 'Bloqueado';

  @override
  String get blockUser => 'Bloquear usuario';

  @override
  String blockUserConfirmation(String username) {
    return '¿Está seguro de que desea bloquear a $username? Ya no verá sus mensajes.';
  }

  @override
  String userBlocked(String username) {
    return '$username ha sido bloqueado';
  }

  @override
  String get blockedUsers => 'Usuarios bloqueados';

  @override
  String get noBlockedUsers => 'No has bloqueado a ningún usuario';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get unblockUser => 'Desbloquear usuario';

  @override
  String unblockUserConfirmation(String username) {
    return '¿Está seguro de que desea desbloquear a $username?';
  }

  @override
  String userUnblocked(String username) {
    return '$username ha sido desbloqueado';
  }

  @override
  String get errorOpeningEmail =>
      'No se pudo abrir el cliente de correo electrónico';
}
