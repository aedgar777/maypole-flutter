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
  String get signIn => 'Iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get register => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Iniciar sesión';

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
  String get pleaseEnterUsername => 'Por favor ingrese un nombre de usuario';

  @override
  String get usernameMinLength =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String usernameMaxLength(int maxLength) {
    return 'El nombre de usuario no debe tener más de $maxLength caracteres';
  }

  @override
  String get usernameInvalidCharacters =>
      'El nombre de usuario solo puede contener letras, números y guiones bajos';

  @override
  String emailMaxLength(int maxLength) {
    return 'El correo electrónico no debe tener más de $maxLength caracteres';
  }

  @override
  String passwordMaxLength(int maxLength) {
    return 'La contraseña no debe tener más de $maxLength caracteres';
  }

  @override
  String get pleaseConfirmPassword => 'Por favor confirme su contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

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

  @override
  String get unknownError => 'Ocurrió un error desconocido';

  @override
  String get deleteMessage => 'Eliminar';

  @override
  String tagUser(String name) {
    return 'Etiquetar a $name';
  }

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get deletionCancelled => 'Eliminación cancelada';

  @override
  String get conversationDeleted => 'Conversación eliminada';

  @override
  String errorDeletingMessage(String error) {
    return 'Error al eliminar mensaje: $error';
  }

  @override
  String errorDeletingConversation(String error) {
    return 'Error al eliminar conversación: $error';
  }

  @override
  String get emailAddress => 'Dirección de correo electrónico';

  @override
  String get validated => 'Verificado';

  @override
  String get notValidated => 'No verificado';

  @override
  String get verifyEmail => 'Verificar correo electrónico';

  @override
  String get resendVerification => 'Reenviar verificación';

  @override
  String get verificationEmailSent =>
      '¡Correo de verificación enviado! Por favor revise su bandeja de entrada.';

  @override
  String get registrationSuccessTitle => '¡Bienvenido a Maypole!';

  @override
  String registrationSuccessMessage(String email) {
    return 'Su cuenta ha sido creada exitosamente. Hemos enviado un correo de verificación a $email. Por favor revise su bandeja de entrada y haga clic en el enlace de verificación para activar todas las funciones.';
  }

  @override
  String get gotIt => 'Entendido';
}
