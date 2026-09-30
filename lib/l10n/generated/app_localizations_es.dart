// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountGuest => 'Cuenta de invitado';

  @override
  String get accountNone => 'Sin sesión iniciada';

  @override
  String get accountSignOut => 'Cerrar sesión en todos los dispositivos';

  @override
  String get accountSignOutConfirm =>
      'Se cerrará la sesión de tu cuenta en todos los dispositivos. No se eliminarán tu cuenta ni los videos locales. Es posible que debas iniciar sesión de nuevo para acceder al contenido en la nube.';

  @override
  String get accountGuestWarning =>
      'Esta cuenta de invitado no tiene un correo verificado. Si cierras sesión, podrías perder el acceso a su contenido en la nube. Verifica un correo antes de cerrar sesión.';

  @override
  String get accountSignedOut =>
      'Se cerró la sesión en todos los dispositivos.';

  @override
  String get accountCancel => 'Cancelar';

  @override
  String get appVersionLabel => 'Versión de la aplicación';

  @override
  String get applicationTitle => 'Verificación de creadores';

  @override
  String get applicationRefresh => 'Actualizar estado de revisión';

  @override
  String get applicationRetry => 'Actualizar y reintentar';

  @override
  String get applicationLoadFailed =>
      'No se pudo cargar tu solicitud. Actualiza para continuar.';

  @override
  String get applicationNoTags =>
      'Las categorías de personajes aún no están disponibles. Inténtalo más tarde.';

  @override
  String get applicationApproved => 'Creador verificado';

  @override
  String get applicationOpenStudio => 'Abrir estudio de creadores';

  @override
  String get applicationPending => 'Solicitud en revisión';

  @override
  String get applicationSuspended => 'Acceso de creador suspendido';

  @override
  String get applicationReviewNote =>
      'El equipo revisa las solicitudes manualmente. Actualiza para consultar tu estado.';

  @override
  String get applicationRejected =>
      'Actualiza tu solicitud según los comentarios de la revisión y vuelve a enviarla.';

  @override
  String get applicationRoles => 'Especialidades de personajes';

  @override
  String get applicationDirections => 'Especialidades de contenido';

  @override
  String get applicationName => 'Nombre público del creador';

  @override
  String get applicationNameHint => 'Por ejemplo, NovaStudio o Nova2026';

  @override
  String get applicationNameRule =>
      'Usa letras y números, con al menos una letra. Máximo 80 caracteres.';

  @override
  String get applicationEmail =>
      'Correo electrónico (identificador del creador)';

  @override
  String get applicationRegion => 'Ubicación del creador';

  @override
  String get applicationChina => 'China continental';

  @override
  String get applicationUs => 'Estados Unidos';

  @override
  String get applicationEea => 'Espacio Económico Europeo';

  @override
  String get applicationUk => 'Reino Unido';

  @override
  String get applicationJapan => 'Japón';

  @override
  String get applicationHk => 'Hong Kong';

  @override
  String get applicationMo => 'Macao';

  @override
  String get applicationTw => 'Taiwán';

  @override
  String get applicationAsia => 'Otra región de Asia';

  @override
  String get applicationOther => 'Otra región';

  @override
  String get applicationAdult => 'Tengo al menos 18 años';

  @override
  String get applicationAgreement =>
      'Acepto las normas para creadores, los requisitos de confidencialidad y las normas contra las transacciones fuera de la plataforma';

  @override
  String get applicationWorks => 'Videos que he creado';

  @override
  String get applicationWorkNote =>
      'Sube entre 1 y 10 videos MP4 creados por ti, de hasta 15 MB cada uno. Estas muestras son privadas y solo se usan para la verificación. El equipo evalúa su cantidad, calidad y creatividad.';

  @override
  String get applicationUpload => 'Subir mis creaciones';

  @override
  String get applicationUploadFailed =>
      'La carga falló. No se añadió el video.';

  @override
  String get applicationRetryUpload => 'Reintentar carga';

  @override
  String get applicationRemoveFailed => 'Quitar carga fallida';

  @override
  String get applicationSample => 'Muestra de verificación';

  @override
  String get applicationPrivate => 'Subida · Muestra privada';

  @override
  String get applicationPreview => 'Vista previa de la muestra';

  @override
  String get applicationRemove => 'Quitar muestra';

  @override
  String get applicationSave => 'Guardar borrador';

  @override
  String get applicationSubmit => 'Enviar solicitud';

  @override
  String get applicationPreviewTitle =>
      'Vista previa de la muestra de verificación';

  @override
  String get applicationInvalidName =>
      'Usa hasta 80 letras y números, con al menos una letra.';

  @override
  String get applicationInvalidEmail =>
      'Introduce un correo válido antes de subir archivos.';

  @override
  String get applicationRoleRequired =>
      'Selecciona al menos una especialidad de personajes.';

  @override
  String get applicationDirectionRequired =>
      'Selecciona al menos una especialidad de contenido.';

  @override
  String get applicationAdultRequired =>
      'Confirma que tienes al menos 18 años.';

  @override
  String get applicationAgreementRequired =>
      'Lee y acepta las normas para creadores.';

  @override
  String get applicationMp4 => 'Selecciona un video MP4.';

  @override
  String get applicationTooLarge =>
      'Cada video debe ocupar como máximo 15 MB. Comprímelo y vuelve a intentarlo.';

  @override
  String get applicationLimit => 'No subas más de 10 muestras.';

  @override
  String get applicationEmailUsed =>
      'Otro creador ya usa este correo. Usa uno diferente.';

  @override
  String get applicationInvalidFields =>
      'Revisa tu nombre, especialidades, correo y aceptación de las condiciones.';

  @override
  String get applicationProcessorBusy =>
      'El servicio de validación de videos está ocupado. Inténtalo más tarde.';

  @override
  String get applicationLocked =>
      'Esta solicitud está bloqueada. Actualiza para consultar el estado de revisión.';

  @override
  String get applicationVideoLimit =>
      'Quita una muestra antes de añadir otra. El límite es 10.';

  @override
  String get applicationVideoInvalid =>
      'El video no superó la validación. Selecciona un MP4 que se pueda reproducir e inténtalo de nuevo.';

  @override
  String get applicationVideoRequired =>
      'Sube al menos un video que supere la validación.';

  @override
  String get applicationConflict =>
      'La solicitud ha cambiado. Actualiza y vuelve a intentarlo.';

  @override
  String get applicationPreviewFailed =>
      'La vista previa falló. Vuelve atrás e inténtalo de nuevo.';

  @override
  String applicationGrade(String grade) {
    return 'Nivel de creador: $grade';
  }

  @override
  String applicationUploading(String name) {
    return 'Subiendo y validando: $name';
  }

  @override
  String get applicationDirectionAction => 'Acciones sencillas';

  @override
  String get applicationDirectionDance => 'Música y baile';

  @override
  String get applicationDirectionEffects => 'Efectos visuales';

  @override
  String get applicationDirectionGrowth => 'Desarrollo de personajes';

  @override
  String get applicationGradeSilver => 'Plata';

  @override
  String get applicationGradeGold => 'Oro';

  @override
  String get applicationGradeDiamond => 'Diamante';

  @override
  String get applicationGradeMaster => 'Maestro';

  @override
  String get applicationGradeLegend => 'Leyenda';

  @override
  String get authTitle => 'Iniciar sesión con correo electrónico';

  @override
  String get authExplanation =>
      'Inicia sesión con tu correo para acceder a tu cuenta desde otro dispositivo y recibir avisos del servicio. Al iniciar sesión se cambia de cuenta; sus datos no se combinan. Si una cuenta anterior no tiene un correo verificado, contacta con soporte para recuperarla.';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authSend => 'Enviar código';

  @override
  String get authResend => 'Reenviar código';

  @override
  String get authSent => 'Código enviado. Caduca en 10 minutos.';

  @override
  String get authCode => 'Código de 6 dígitos';

  @override
  String get authChange => 'Cambiar correo';

  @override
  String get authVerify => 'Verificar e iniciar sesión';

  @override
  String get authInvalidEmail => 'Introduce una dirección de correo válida.';

  @override
  String get authInvalidCode => 'Introduce el código de 6 dígitos.';

  @override
  String authResendSeconds(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get appName => 'Hildors';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Usar idioma del sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageFallback =>
      'Las variantes del chino usan chino simplificado. Los demás idiomas no compatibles usan inglés.';

  @override
  String get languageSaveFailed =>
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get errorNetwork =>
      'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get errorSession => 'Inicia sesión de nuevo para continuar.';

  @override
  String get errorPermission =>
      'Este contenido no está disponible para tu cuenta.';

  @override
  String get errorConflict =>
      'Este elemento ha cambiado. Actualízalo e inténtalo de nuevo.';

  @override
  String get errorTooLarge =>
      'Este archivo es demasiado grande. Elige uno más pequeño.';

  @override
  String get errorRateLimit =>
      'Hay demasiadas solicitudes. Inténtalo más tarde.';

  @override
  String get errorGeneric => 'Se produjo un error. Inténtalo de nuevo.';

  @override
  String get errorEmailCode =>
      'Revisa tu correo y el código de verificación. Es posible que el código haya caducado.';

  @override
  String get errorServiceUnavailable =>
      'Este servicio no está disponible temporalmente. Inténtalo más tarde.';

  @override
  String fileBytes(String value) {
    return '$value B';
  }

  @override
  String fileKilobytes(String value) {
    return '$value KB';
  }

  @override
  String fileMegabytes(String value) {
    return '$value MB';
  }

  @override
  String get catalogCollection => 'Colección';

  @override
  String get catalogLibrary => 'Biblioteca';

  @override
  String get catalogMyCharacters => 'Mis personajes';

  @override
  String get catalogLoadFailed => 'No se pudo cargar la biblioteca';

  @override
  String get catalogCheckNetwork => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get catalogSearch => 'Buscar personajes, videos o géneros';

  @override
  String get catalogRefresh => 'Actualizar biblioteca';

  @override
  String get catalogSource => 'Origen';

  @override
  String get catalogFormat => 'Formato';

  @override
  String get catalogGenre => 'Género';

  @override
  String get catalogAll => 'Todos';

  @override
  String get catalogOfficial => 'De Hildors';

  @override
  String get catalogCreatorWorks => 'Contenido de creadores';

  @override
  String get catalogAnonymous => 'Creador anónimo';

  @override
  String get catalogSingle => 'Video individual';

  @override
  String get catalogPackage => 'Paquete de personaje';

  @override
  String get catalogEmpty => 'No hay contenido que coincida';

  @override
  String get catalogClear => 'Borrar filtros';

  @override
  String get catalogResults => 'Resultados';

  @override
  String get catalogDescriptionMissing =>
      'La descripción del personaje aún no está disponible';

  @override
  String get catalogPackVideos => 'Videos de este paquete';

  @override
  String get catalogVideo => 'Video';

  @override
  String get catalogNoPreview =>
      'La vista previa no está disponible en este momento';

  @override
  String get catalogDurationUnknown => 'Duración no disponible';

  @override
  String get catalogStoryMissing => 'Aún no hay historia del personaje';

  @override
  String get catalogStory => 'Historia del personaje';

  @override
  String get catalogStoryCollapse => 'Contraer historia';

  @override
  String get catalogStoryExpand => 'Leer historia completa';

  @override
  String get catalogImageLoading => 'Cargando imagen';

  @override
  String get catalogImageRetry =>
      'No se pudo cargar la imagen. Toca para reintentar';

  @override
  String get playerNoSource => 'No hay videos disponibles';

  @override
  String get playerBuffering => 'Almacenando video en búfer…';

  @override
  String get playerLoading => 'Cargando video…';

  @override
  String get playerSlow =>
      'Está tardando más de lo esperado. Revisa tu conexión o vuelve a intentarlo.';

  @override
  String get playerPause => 'Pausar vista previa';

  @override
  String get playerPlay => 'Reproducir vista previa';

  @override
  String get playerZoom =>
      'Pellizca para ampliar · Toca dos veces para restablecer';

  @override
  String get playerFailed => 'La reproducción falló. Inténtalo de nuevo.';

  @override
  String get playerTimeout =>
      'Se agotó el tiempo de carga del video. Inténtalo de nuevo.';

  @override
  String get playerLoadFailed =>
      'No se pudo cargar el video. Inténtalo de nuevo.';

  @override
  String get playerAuthFailed =>
      'No se pudo actualizar el acceso. Vuelve a tus envíos e inténtalo de nuevo.';

  @override
  String get downloadTitle => 'Guardar en Mis personajes';

  @override
  String get downloadUnavailable => 'Las compras no están disponibles';

  @override
  String get downloadFree => 'Descargar gratis';

  @override
  String get downloadInfo =>
      'Los videos gratuitos se pueden descargar y ver sin conexión en Mis personajes. Las compras no están disponibles.';

  @override
  String get downloadCancel => 'Cancelar descarga';

  @override
  String get downloadAvailable => 'Descargar videos disponibles';

  @override
  String get downloadDone => 'Descargado';

  @override
  String get downloadRefresh => 'Actualizar acceso';

  @override
  String get downloadView => 'Ver Mis personajes';

  @override
  String get downloadDisabled =>
      'Las descargas no están disponibles temporalmente. Inténtalo más tarde.';

  @override
  String get downloadSignIn => 'Inicia sesión de nuevo para descargar.';

  @override
  String get downloadDenied =>
      'Este video no está disponible para descargar. Actualiza el acceso e inténtalo de nuevo.';

  @override
  String get downloadAccessFailed =>
      'No se pudo verificar el acceso a la descarga. Revisa tu conexión y tu cuenta e inténtalo de nuevo.';

  @override
  String get downloadFinished =>
      'Descarga completada. Se guardó en Mis personajes.';

  @override
  String get downloadCancelled =>
      'Descarga cancelada. Los videos ya descargados permanecen en Mis personajes.';

  @override
  String get downloadFailed =>
      'Descarga incompleta. Revisa tu conexión, el almacenamiento y el acceso a tu cuenta e inténtalo de nuevo.';

  @override
  String catalogSummary(int count, int creators) {
    return '$count elementos · $creators de creadores';
  }

  @override
  String catalogRefreshed(int count, int creators) {
    return 'Biblioteca actualizada: $count elementos, incluidos $creators de creadores';
  }

  @override
  String catalogCount(String format, int count) {
    return '$format · $count videos';
  }

  @override
  String catalogSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String catalogCreatorSpace(String name) {
    return 'Creaciones de $name';
  }

  @override
  String catalogPublished(int count) {
    return 'Creaciones publicadas · $count';
  }

  @override
  String downloadProgress(int count, int total) {
    return 'Descargados: $count/$total';
  }

  @override
  String downloadActive(String name) {
    return 'Descargando: $name';
  }

  @override
  String downloadPrice(String price) {
    return 'US\$ $price · Comprar para descargar';
  }

  @override
  String get controlsDeleteTitle => '¿Eliminar las descargas locales?';

  @override
  String get controlsDeleteNote =>
      'Se eliminarán de la aplicación los archivos descargados de esta colección. Conservarás el acceso en la nube para volver a descargarlos.';

  @override
  String get controlsCancel => 'Cancelar';

  @override
  String get controlsDelete => 'Eliminar';

  @override
  String get controlsDeleteFailed => 'No se pudo eliminar. Inténtalo de nuevo.';

  @override
  String get controlsDeleteLocal => 'Eliminar descargas locales';

  @override
  String get controlsNoVideos =>
      'Aún no hay videos disponibles para este personaje.';

  @override
  String get controlsPreviewLocal => 'Vista previa del video descargado';

  @override
  String get controlsExamples =>
      'Colecciones de muestra oficiales · Seleccionar videos';

  @override
  String get controlsChooseList => 'Elige una lista de reproducción';

  @override
  String get controlsPendingNote =>
      'Los videos se añaden primero a los elementos pendientes. Aún no se han subido al dispositivo.';

  @override
  String get controlsStartup => 'Visualización diaria';

  @override
  String get controlsBluetooth => 'Modo música';

  @override
  String get controlsAddFailed =>
      'No se pudieron añadir los videos. Inténtalo de nuevo.';

  @override
  String get controlsMyCharacters => 'Mis personajes';

  @override
  String get controlsLoadFailed =>
      'No se pudieron cargar tus personajes. Toca para reintentar.';

  @override
  String get controlsEmpty => 'Aún no hay personajes disponibles';

  @override
  String get controlsEmptyNote =>
      'Descarga un personaje de la biblioteca de contenido y luego elige sus videos.';

  @override
  String get controlsLibrary => 'Biblioteca de contenido';

  @override
  String get controlsBrowse => 'Explorar biblioteca de contenido';

  @override
  String get controlsPickNote =>
      'Elige un personaje y luego selecciona videos para esta lista.';

  @override
  String get controlsListNote =>
      'Añade videos de personajes a Visualización diaria o Modo música.';

  @override
  String get controlsUnavailable => 'No hay videos disponibles';

  @override
  String get controlsSelect => 'Seleccionar videos';

  @override
  String get controlsAdd => 'Añadir a la lista';

  @override
  String get controlsControlTitle => 'Panel de control';

  @override
  String get controlsBrightness => 'Brillo';

  @override
  String get controlsAngle =>
      'Ángulo (unidades y rango del dispositivo sin confirmar)';

  @override
  String get controlsSpeakerTitle => 'Definir nombre del altavoz Bluetooth';

  @override
  String get controlsSpeakerName => 'Nombre del altavoz';

  @override
  String get controlsSave => 'Guardar';

  @override
  String get controlsSpeaker => 'Altavoz Bluetooth';

  @override
  String get controlsConnectSpeaker =>
      'Conecta el dispositivo para leer el nombre de su altavoz.';

  @override
  String get controlsReading => 'Leyendo…';

  @override
  String get controlsNameUnknown => 'Nombre sin cargar';

  @override
  String get controlsRefreshName => 'Actualizar nombre';

  @override
  String get controlsEditName => 'Editar nombre';

  @override
  String get controlsDisconnected => 'Desconectado';

  @override
  String get controlsConnecting => 'Conectando…';

  @override
  String get controlsReconnecting => 'Reconectando…';

  @override
  String get controlsConnected => 'Conectado';

  @override
  String get controlsIp => 'IP del dispositivo';

  @override
  String get controlsPort => 'Puerto predeterminado: 8900';

  @override
  String get controlsStopReconnect => 'Detener reconexión';

  @override
  String get controlsDisconnect => 'Desconectar';

  @override
  String get controlsConnect => 'Conectar';

  @override
  String get controlsQuick => 'Controles rápidos';

  @override
  String get controlsPowerOn => 'Encender';

  @override
  String get controlsPowerOff => 'Apagar';

  @override
  String get controlsPrevious => 'Anterior';

  @override
  String get controlsPause => 'Pausar';

  @override
  String get controlsPlay => 'Reproducir';

  @override
  String get controlsNext => 'Siguiente';

  @override
  String get controlsRefreshStatus => 'Actualizar estado';

  @override
  String get controlsStatus => 'Estado del dispositivo';

  @override
  String get controlsLan => 'Control por red local';

  @override
  String get controlsMode => 'Modo de funcionamiento';

  @override
  String get controlsAudioSource => 'Fuente de audio Bluetooth';

  @override
  String get controlsProtocol => 'Pendiente de compatibilidad del protocolo';

  @override
  String get controlsLocalPlayback => 'Reproducción del dispositivo';

  @override
  String get controlsBluetoothWaiting => 'Esperando Bluetooth';

  @override
  String get controlsBluetoothAudio => 'Audio Bluetooth';

  @override
  String get controlsWaitingSource => 'Esperando una fuente de audio';

  @override
  String get controlsAudioPlaying => 'Audio en reproducción';

  @override
  String get controlsAudioPaused => 'Audio en pausa';

  @override
  String get controlsWasDisconnected => 'Desconectado';

  @override
  String get controlsBatteryFull => 'Carga completa';

  @override
  String get controlsBattery => 'Batería del dispositivo';

  @override
  String get controlsProtocolNote =>
      'El protocolo actual no informa del modo de funcionamiento ni del estado de Bluetooth. Estos indicadores requieren una actualización del protocolo del dispositivo.';

  @override
  String controlsPackageCount(int count) {
    return 'Colección de personaje · $count videos';
  }

  @override
  String controlsDownloaded(int count, int total) {
    return '$count/$total videos descargados';
  }

  @override
  String controlsSeconds(int seconds) {
    return '$seconds segundos';
  }

  @override
  String controlsAddCount(int count) {
    return 'Añadir $count videos a pendientes';
  }

  @override
  String controlsVideoCount(int count) {
    return '$count videos';
  }

  @override
  String controlsAdded(String list) {
    return 'Añadido a los pendientes de $list. Aún no se ha subido al dispositivo.';
  }

  @override
  String controlsNamedPlaying(String name) {
    return '$name · En reproducción';
  }

  @override
  String controlsNamedPaused(String name) {
    return '$name · En pausa';
  }

  @override
  String controlsCharging(int percent) {
    return '$percent% · Cargando';
  }

  @override
  String get coreHome => 'Inicio';

  @override
  String get coreCollection => 'Colección';

  @override
  String get coreExplore => 'Explorar';

  @override
  String get coreProfile => 'Perfil';

  @override
  String get coreDeviceControl => 'Controles del dispositivo';

  @override
  String get coreCustomCharacter => 'Personaliza tu personaje holográfico';

  @override
  String get corePlaylists => 'Listas del dispositivo';

  @override
  String get corePlaylistSubtitle => 'Modos de visualización y música';

  @override
  String get coreDisplay => 'Modo visualización';

  @override
  String get coreStartupSubtitle =>
      'Gestionar el contenido reproducido al encender';

  @override
  String get coreMusic => 'Modo música';

  @override
  String get coreBluetoothSubtitle =>
      'Gestionar el contenido reproducido con audio Bluetooth';

  @override
  String get coreOnline => 'En línea';

  @override
  String get coreDisconnected => 'Desconectado';

  @override
  String get coreDeviceConnected => 'Dispositivo conectado';

  @override
  String get coreConnecting => 'Conectando…';

  @override
  String get coreReconnecting => 'Reconectando…';

  @override
  String get coreDeviceDisconnected => 'Dispositivo desconectado';

  @override
  String get coreLanControl => 'Control por red local · P20 / P20 PORTAL';

  @override
  String get coreConnectP20 => 'Conectar dispositivo';

  @override
  String get coreConnectionSettings => 'Panel de control';

  @override
  String get coreDeviceManagement => 'Gestión del dispositivo';

  @override
  String get coreDevices => 'Dispositivos';

  @override
  String get corePlaylist => 'Listas de reproducción';

  @override
  String get coreDeviceContent => 'Contenido del dispositivo';

  @override
  String get coreCharacterAssets => 'Personajes';

  @override
  String get coreCustomOrders => 'Pedidos personalizados';

  @override
  String get coreOrdersSubtitle =>
      'Sigue la producción y la entrega. Encontrarás los personajes recibidos en Colección.';

  @override
  String get coreCreatorCenter => 'Centro de creadores';

  @override
  String get coreCreatorSubtitle =>
      'Solicitudes, tareas de producción e ingresos';

  @override
  String get coreSupport => 'Soporte';

  @override
  String get corePlaybackGuide => 'Modos de reproducción';

  @override
  String get corePlaybackGuideSubtitle =>
      'Descubre cómo cambian los modos de visualización y música';

  @override
  String get coreLanHelp => 'Ayuda con la red local';

  @override
  String get coreLanHelpSubtitle =>
      'Conectarse al punto de acceso de P20 / P20 PORTAL y resolver problemas';

  @override
  String get coreAppSettings => 'Ajustes del dispositivo y la aplicación';

  @override
  String get coreAppSettingsSubtitle =>
      'Opciones del dispositivo, preferencias de reproducción y versión';

  @override
  String get coreAbout => 'Acerca de HILDORS';

  @override
  String get coreAboutSubtitle =>
      'Portal de personajes · Compatible con P20 / P20 PORTAL';

  @override
  String get corePlayerProfile => 'Perfil de usuario';

  @override
  String get coreLocalAccount => 'Perfil local · Guardado en este dispositivo';

  @override
  String get coreDeviceSettings => 'Ajustes del dispositivo';

  @override
  String get coreReadFailed =>
      'No se pudo leer el estado del dispositivo. Conéctate a su red Wi-Fi e inténtalo de nuevo.';

  @override
  String get coreSettingFailed =>
      'No se pudo aplicar el ajuste. Revisa la conexión del dispositivo e inténtalo de nuevo.';

  @override
  String get corePlaybackBehavior => 'Ajustes de reproducción';

  @override
  String get coreLoopMode => 'Modo de repetición';

  @override
  String get coreLoopSubtitle =>
      'Elige cómo repite el dispositivo la lista actual';

  @override
  String get coreConnectToChange =>
      'Conéctate para consultar y cambiar los ajustes';

  @override
  String get coreDeviceInfo => 'Información del dispositivo';

  @override
  String get coreLanCockpit => 'Dispositivo de red local';

  @override
  String get coreNotRead => 'Aún sin leer';

  @override
  String get coreReadInfo => 'Leer información del dispositivo';

  @override
  String get coreHelp => 'Ayuda';

  @override
  String get coreModesHelpSubtitle =>
      'Cambio automático entre los modos de visualización y música';

  @override
  String get coreHotspotHelp =>
      'Conexión al punto de acceso del dispositivo y solución de problemas';

  @override
  String get coreDeviceConnecting => 'Conectando al dispositivo';

  @override
  String get coreDeviceReconnecting => 'Restableciendo conexión';

  @override
  String get coreCockpitOnline => 'Dispositivo en línea';

  @override
  String get coreGoHomeConnect =>
      'Ve a Inicio para conectar tu P20 / P20 PORTAL';

  @override
  String get coreOpeningLan => 'Estableciendo control por red local';

  @override
  String get coreRetryingLan =>
      'Conexión interrumpida. Reintentando automáticamente';

  @override
  String get coreLanReady => 'Control por red local conectado';

  @override
  String get coreSync => 'Sincronizar estado del dispositivo';

  @override
  String get coreSingleLoop => 'Repetir uno';

  @override
  String get coreSequenceLoop => 'Repetir todos';

  @override
  String get coreRandomLoop => 'Reproducción aleatoria';

  @override
  String get coreSingleOnce => 'Reproducir una vez';

  @override
  String get coreCheckWifi => 'Revisa el Wi-Fi de tu teléfono';

  @override
  String get coreCheckWifiBody =>
      'Conecta tu teléfono al punto de acceso de P20 o al mismo router que tu P20.';

  @override
  String get coreCheckAddress => 'Revisa la dirección de control';

  @override
  String get coreCheckAddressBody =>
      'En modo de punto de acceso, la dirección predeterminada es 192.168.4.1 y el puerto TCP es 8900.';

  @override
  String get coreLanPermission => 'Permitir acceso a la red local';

  @override
  String get coreLanPermissionBody =>
      'En iOS, permite el acceso a la red local. En Android, concede los permisos solicitados de dispositivos cercanos y red.';

  @override
  String get coreReconnect => 'Reconectar';

  @override
  String get coreReconnectBody =>
      'Vuelve a los controles del dispositivo y toca Conectar. Tras una desconexión inesperada, la aplicación reintenta la conexión después de 1, 2, 4, 8, 15 y 30 segundos.';

  @override
  String get coreOfflineWifiHelp =>
      'El aviso «Sin internet» no significa necesariamente que el control del dispositivo haya fallado. Puedes seguir controlándolo mientras tu teléfono permanezca en la red local de P20.';

  @override
  String get coreLocalPlayback => 'Reproducción del dispositivo';

  @override
  String get coreLocalPlaybackBody =>
      'P20 reproduce los videos guardados en el dispositivo, incluido su audio. Usa este modo para la reproducción al encender, las secuencias repetidas y el contenido fijo.';

  @override
  String get coreBluetoothSpeaker => 'Altavoz Bluetooth';

  @override
  String get coreBluetoothSpeakerBody =>
      'Un teléfono o una computadora envía audio a P20 por Bluetooth mientras P20 reproduce el video configurado para el modo Bluetooth.';

  @override
  String get coreSeparateConnections =>
      'Hildors controla P20 por Wi-Fi local. El control por red local y el audio Bluetooth usan conexiones independientes.';

  @override
  String get coreCharacterPortal => 'Portal de personajes';

  @override
  String get coreExploreSubtitle =>
      'Personaliza personajes, comparte tus deseos y crea.';

  @override
  String get coreWishSubtitle =>
      'Comparte tus deseos y sigue las novedades sobre licencias';

  @override
  String get coreCreatorExploreSubtitle => 'Solicitudes, tareas e ingresos';

  @override
  String get coreWish => 'Deseos de personajes';

  @override
  String get coreCustomize => 'Personaliza tu personaje';

  @override
  String get coreEnter => 'Abrir';

  @override
  String get coreCreatorFreeSubtitle =>
      'Solicita la verificación de creador y publica contenido gratuito';

  @override
  String get coreExploreFreeSubtitle =>
      'Explora oportunidades para crear y compartir contenido gratuito.';

  @override
  String get coreConnectionFailed =>
      'No se pudo conectar. Conecta el teléfono al Wi-Fi del dispositivo e inténtalo de nuevo.';

  @override
  String get coreSystemLabel => 'SISTEMA DEL DISPOSITIVO';

  @override
  String get coreProfileLabel => 'PERFIL DE USUARIO';

  @override
  String get coreLocalLabel => 'LOCAL';

  @override
  String get corePilotLabel => 'PILOTO HILDORS';

  @override
  String get coreServiceLabel => 'SERVICIO PRINCIPAL';

  @override
  String get coreCreatorLabel => 'CREADOR';

  @override
  String get coreOnlineLabel => 'EN LÍNEA';

  @override
  String get coreConnectingLabel => 'CONECTANDO';

  @override
  String get coreReconnectingLabel => 'RECONECTANDO';

  @override
  String get coreOfflineLabel => 'SIN CONEXIÓN';

  @override
  String get creatorWorkbench => 'Estudio de creadores';

  @override
  String get creatorOriginal => 'Contenido original';

  @override
  String get creatorFreeNote =>
      'Sube un video o una colección de personaje para revisión. Esta versión solo admite envíos gratuitos. El contenido se publica tras su aprobación.';

  @override
  String get creatorPublishingNote =>
      'Sube videos o colecciones de personajes para revisión. Los creadores estándar y verificados publican contenido gratuito; los socios pueden fijar precios.';

  @override
  String get creatorSubmissions => 'Subir / Mis envíos';

  @override
  String get creatorTasks => 'Proyectos personalizados';

  @override
  String get creatorTasksNote =>
      'Consulta los proyectos disponibles y los pedidos personalizados en curso';

  @override
  String get customPlansTitle => 'Videos personalizados';

  @override
  String get customOrdersTitle => 'Mis pedidos personalizados';

  @override
  String get customUnavailable =>
      'Los pagos de la tienda aún no están conectados. No se puede realizar ningún cobro.';

  @override
  String get customWebsiteTitle => 'Sitio web oficial de Hildors';

  @override
  String get customWebsiteBody =>
      'Conoce Hildors y el hardware compatible. La compra de vídeos personalizados no está disponible en esta versión.';

  @override
  String get customWebsiteButton => 'Visitar el sitio web de Hildors';

  @override
  String get customWebsiteError => 'No se pudo abrir el sitio web de Hildors.';

  @override
  String customBase(String price) {
    return 'Precio base de referencia en USD: $price. Al pagar se usa el precio de la tienda.';
  }

  @override
  String customSeconds(int seconds) {
    return 'Video de $seconds segundos';
  }

  @override
  String get customRequest => 'Enviar requisitos para revisión';

  @override
  String get customName => 'Nombre del personaje / proyecto';

  @override
  String get customRequirements => 'Tus requisitos';

  @override
  String get customMaterials => 'Añadir imágenes de referencia';

  @override
  String customMaterialCount(int count) {
    return '$count imágenes de referencia';
  }

  @override
  String get customPrivacy =>
      'Los materiales de referencia se usan para evaluar y producir este pedido privado. Su exhibición pública requiere un consentimiento aparte.';

  @override
  String get customConsent =>
      'Acepto que se usen estos materiales para este pedido.';

  @override
  String get customValidation =>
      'Introduce un nombre de proyecto y los requisitos, y confirma el aviso de uso de materiales.';

  @override
  String get customImageError =>
      'Elige hasta 8 imágenes JPG/PNG, de un máximo de 8 MB cada una.';

  @override
  String get customSubmitted =>
      'Solicitud enviada para revisión. No se ha realizado ningún cobro.';

  @override
  String get customTerms => 'Revisa el alcance confirmado antes de pagar';

  @override
  String get customContent => 'Contenido que se entregará';

  @override
  String get customPeriod => 'Plazo de entrega';

  @override
  String get customRevisions => 'Alcance de las revisiones';

  @override
  String get customRights => 'Derechos de uso';

  @override
  String get customAcceptTerms =>
      'Acepto este alcance confirmado y sus condiciones.';

  @override
  String customPay(String price) {
    return 'Pagar $price';
  }

  @override
  String get customRestore => 'Consultar compras pendientes';

  @override
  String get customTestMode => 'PAGO DE PRUEBA — sin cargos reales';

  @override
  String get customAccept => 'Aceptar entrega';

  @override
  String get customRevise => 'Solicitar revisión';

  @override
  String get customRevisionNote => 'Describe la revisión que solicitas';

  @override
  String get customStatusReview => 'Requisitos en revisión';

  @override
  String get customStatusInfo => 'Se necesita más información';

  @override
  String get customStatusQuote => 'Alcance confirmado; pendiente de pago';

  @override
  String get customStatusMaking => 'En producción';

  @override
  String get customStatusQc => 'Revisión de calidad';

  @override
  String get customStatusAccept => 'Listo para tu revisión';

  @override
  String get customStatusDelivered => 'Entregado';

  @override
  String get customStatusRejected => 'Solicitud rechazada';

  @override
  String get customStatusWithdrawn => 'Retirado / reembolsado';

  @override
  String get customPending =>
      'El pago está pendiente. La producción comienza solo después de la verificación del servidor.';

  @override
  String get customEmpty => 'Aún no hay elementos disponibles.';

  @override
  String get customAudioNone => 'Sin audio — paquete básico';

  @override
  String get customAudioMatched => 'Audio seleccionado por la plataforma';

  @override
  String get customAudioHelp =>
      'Seleccionamos música de fondo o efectos de sonido sencillos para tu video. No se admiten canciones específicas, narraciones ni archivos de audio subidos.';

  @override
  String customAudioTotal(String price) {
    return 'Total de referencia en USD: $price';
  }

  @override
  String customAudioRate(int percent) {
    return 'Recargo por selección de audio: $percent%';
  }

  @override
  String get customSupplement => 'Actualizar requisitos y volver a enviar';

  @override
  String get customSupplementSaved =>
      'Requisitos actualizados enviados para revisión.';

  @override
  String get customSaveDelivery => 'Guardar entrega en Mis personajes';

  @override
  String get customSavedDelivery =>
      'Guardado en Mis personajes para usar sin conexión.';

  @override
  String get customSavingDelivery => 'Descargando entrega privada…';

  @override
  String get customConfirmDelivery =>
      '¿Aceptar esta versión como entrega final?';

  @override
  String customRevisionLimit(int used, int limit) {
    return 'Solicitudes de revisión: $used de $limit';
  }

  @override
  String get customProgress => 'Avances de producción';

  @override
  String get deletionTitle => 'Eliminar cuenta';

  @override
  String get deletionExplanation =>
      'Solicita la eliminación de tu cuenta de Hildors y sus datos asociados. Se enviará una solicitud para revisión; los datos no se eliminarán de inmediato ni se cerrará tu sesión. Puedes consultar su estado aquí o cancelarla mientras esté pendiente.';

  @override
  String get deletionSubmit => 'Solicitar eliminación de la cuenta';

  @override
  String get deletionConfirm =>
      '¿Enviar esta solicitud de eliminación? Tu cuenta seguirá activa mientras se revise la solicitud.';

  @override
  String get deletionNone => 'No hay solicitudes de eliminación pendientes.';

  @override
  String get deletionReceived => 'Solicitud recibida';

  @override
  String get deletionReview => 'En revisión';

  @override
  String get deletionInformation => 'Se necesita más información';

  @override
  String get deletionCancelled => 'Solicitud cancelada';

  @override
  String get deletionCancel => 'Cancelar solicitud de eliminación';

  @override
  String get deletionRefresh => 'Actualizar estado';

  @override
  String deletionReference(String id) {
    return 'ID de solicitud: $id';
  }

  @override
  String get devicePlayingDelete =>
      'Reproduce otro video antes de eliminar este.';

  @override
  String get deviceDeleteTitle =>
      '¿Eliminar este archivo del dispositivo de forma permanente?';

  @override
  String get deviceDeleteIntro =>
      'Este video se eliminará permanentemente del dispositivo holográfico:';

  @override
  String get deviceDeleteNote =>
      'Esta acción no se puede deshacer. Las copias descargadas en tu teléfono y los registros de compra se conservarán.';

  @override
  String get deviceCancel => 'Cancelar';

  @override
  String get deviceDelete => 'Eliminar permanentemente';

  @override
  String get deviceVideoLibrary => 'Videos del dispositivo';

  @override
  String get deviceRefresh => 'Actualizar';

  @override
  String get deviceConnectFirst =>
      'Primero conecta tu dispositivo en Controles.';

  @override
  String get deviceReadVideos => 'Cargar videos del dispositivo';

  @override
  String get devicePlaying => 'En reproducción';

  @override
  String get devicePlay => 'Reproducir';

  @override
  String get deviceMore => 'Más acciones';

  @override
  String get deviceDeleteFrom => 'Eliminar del dispositivo';

  @override
  String get frameSaved =>
      'Encuadre guardado. El video original no ha cambiado; no se ha convertido ni subido.';

  @override
  String get frameSaveFailed => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get frameTitle => 'Ajustar encuadre circular';

  @override
  String get frameCircle =>
      'El círculo marca el área de visualización del dispositivo.';

  @override
  String get frameInstructions =>
      'Pellizca para ampliar y arrastra para cambiar la posición. Reproduce el video completo para comprobar que el personaje y sus movimientos permanecen dentro del círculo.';

  @override
  String get framePause => 'Pausar vista previa';

  @override
  String get framePlay => 'Reproducir vista previa';

  @override
  String get framePlaybackFailed =>
      'La reproducción falló. Vuelve atrás e inténtalo de nuevo.';

  @override
  String get frameZoom => 'Ampliación';

  @override
  String get frameFit => 'Ajustar cuadro completo';

  @override
  String get frameFill => 'Rellenar círculo';

  @override
  String get frameReset => 'Restablecer';

  @override
  String get frameFitNote =>
      'Ajustar conserva el cuadro completo. Rellenar recorta los bordes.';

  @override
  String get frameRestoreFailed =>
      'No se pudo cargar el encuadre guardado. Ajústalo y guárdalo de nuevo.';

  @override
  String get frameSaving => 'Guardando…';

  @override
  String get frameSave => 'Guardar encuadre';

  @override
  String get frameUnavailable => 'Convertir y subir · No disponible';

  @override
  String get framePending =>
      'Por ahora solo se guarda el encuadre. La conversión de video para el dispositivo aún no está disponible.';

  @override
  String get framePreviewFailed =>
      'No se pudo cargar la vista previa. Vuelve atrás e inténtalo de nuevo.';

  @override
  String deviceDeleted(String name) {
    return 'Se eliminó $name del dispositivo.';
  }

  @override
  String frameTime(int position, int duration) {
    return '$position / $duration segundos';
  }

  @override
  String get copyDeviceLog => 'Copiar registro de comunicación del dispositivo';

  @override
  String get deviceLogCopied =>
      'Registro copiado. Contiene metadatos del protocolo; se omiten los datos multimedia.';

  @override
  String get deviceDeleteAudioNote =>
      'También se eliminará el archivo de audio asociado.';

  @override
  String get governanceReport => 'Denunciar contenido';

  @override
  String get governanceBlock => 'Bloquear creador';

  @override
  String get governanceCopyright => 'Infracción de derechos de autor';

  @override
  String get governanceAbuse => 'Acoso o abuso';

  @override
  String get governanceSexual => 'Contenido sexual';

  @override
  String get governanceViolence => 'Violencia';

  @override
  String get governanceSpam => 'Contenido no deseado';

  @override
  String get governanceOther => 'Otro';

  @override
  String get governanceDetails => 'Detalles (opcional)';

  @override
  String get governanceReportNote =>
      'Tu denuncia se enviará a nuestro equipo de revisión. Si se trata de derechos de autor, describe la obra original y dónde aparece. No incluyas información personal sensible.';

  @override
  String get governanceCancel => 'Cancelar';

  @override
  String get governanceSubmit => 'Enviar denuncia';

  @override
  String governanceReceived(String reference) {
    return 'Denuncia recibida. Referencia: $reference';
  }

  @override
  String get governanceBlockNote =>
      'Oculta el contenido de este creador en el catálogo de esta cuenta. Puedes desbloquearlo en Denuncias y creadores bloqueados.';

  @override
  String get governanceBlocked => 'Creador bloqueado.';

  @override
  String get governanceAuthError =>
      'Tu sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get governanceUnavailableError =>
      'Este contenido ya no está disponible.';

  @override
  String get governanceInvalidError =>
      'Revisa tu denuncia e inténtalo de nuevo.';

  @override
  String get governanceConflictError =>
      'Esta acción no está disponible. Actualiza e inténtalo de nuevo.';

  @override
  String get governanceNetworkError =>
      'No se pudo conectar. Inténtalo de nuevo.';

  @override
  String get governanceTitle => 'Denuncias y creadores bloqueados';

  @override
  String get governanceRefresh => 'Actualizar';

  @override
  String get governanceReports => 'Mis denuncias';

  @override
  String get governanceBlocks => 'Creadores bloqueados';

  @override
  String get governanceEmpty => 'Aún no hay elementos.';

  @override
  String get governanceUnblock => 'Desbloquear';

  @override
  String get governanceStatusReceived => 'Recibida';

  @override
  String get governanceStatusReview => 'En revisión';

  @override
  String get governanceStatusAction => 'Medidas tomadas';

  @override
  String get governanceStatusNoViolation => 'No se encontró ninguna infracción';

  @override
  String get playlistFromCharacters => 'Elegir de Mis personajes';

  @override
  String get playlistChooseCharacter => 'Elige videos de tus personajes';

  @override
  String get playlistFromPhone => 'Importar del teléfono';

  @override
  String get playlistFromDevice => 'Añadir videos existentes del dispositivo';

  @override
  String get playlistPickFailed =>
      'No se pudo seleccionar un video. Inténtalo de nuevo.';

  @override
  String get playlistPendingSaveFailed =>
      'No se pudieron guardar los elementos pendientes y podrían perderse al salir. Inténtalo de nuevo.';

  @override
  String get playlistRetry => 'Reintentar';

  @override
  String get playlistReselectTitle => 'Selecciona de nuevo el video original';

  @override
  String get playlistReselectNote =>
      'El archivo se movió o se borró su caché temporal. La entrada de la lista permanece. Vuelve a seleccionar el original y confirma su encuadre.';

  @override
  String get playlistCancel => 'Cancelar';

  @override
  String get playlistReselect => 'Seleccionar de nuevo';

  @override
  String get playlistReadFailed =>
      'No se pudo leer el video. Inténtalo de nuevo.';

  @override
  String get playlistOriginalTitle => 'Se necesita el video original';

  @override
  String get playlistOriginalNote =>
      'En el dispositivo solo está disponible el nombre del archivo. Elige el video original de tu teléfono para ajustar el encuadre. Al guardar solo se registra el encuadre; al convertir y subir se añade un nuevo archivo al dispositivo y se conserva el original.';

  @override
  String get playlistChooseOriginal => 'Elegir video original';

  @override
  String get playlistOriginalFailed =>
      'No se pudo leer el video original. Inténtalo de nuevo.';

  @override
  String get playlistRemovePending => '¿Quitar el video pendiente?';

  @override
  String get playlistRemovePendingNote =>
      'Solo se quitará esta entrada de la lista. Se conservarán los videos del teléfono y del dispositivo.';

  @override
  String get playlistRemove => 'Quitar';

  @override
  String get playlistReadLocalFailed =>
      'No se pudo cargar la lista local. Inténtalo de nuevo.';

  @override
  String get playlistSaveLocalFailed =>
      'No se pudo guardar la lista local. Inténtalo de nuevo.';

  @override
  String get playlistAddDevice => 'Añadir desde la biblioteca del dispositivo';

  @override
  String get playlistAllAdded =>
      'Todos los videos del dispositivo ya están en este borrador.';

  @override
  String get playlistConnectFirst =>
      'Conecta el dispositivo antes de reproducir.';

  @override
  String get playlistNotUploaded =>
      'Este video no está en el dispositivo. Es necesario convertirlo y subirlo antes de reproducirlo.';

  @override
  String get playlistRemoveTitle => '¿Quitar de la lista?';

  @override
  String get playlistRemoveList => 'Quitar de la lista';

  @override
  String get playlistUndo => 'Deshacer';

  @override
  String get playlistTitle => 'Listas del dispositivo';

  @override
  String get playlistReadDevice => 'Leer videos del dispositivo';

  @override
  String get playlistStartup => 'Al encender';

  @override
  String get playlistBluetooth => 'Bluetooth';

  @override
  String get playlistStartupNote =>
      'El dispositivo reproduce esta lista al encenderse.';

  @override
  String get playlistBluetoothNote =>
      'El dispositivo cambia a esta lista cuando se conecta Bluetooth.';

  @override
  String get playlistLoop => 'Modo de repetición';

  @override
  String get playlistListLoop => 'Repetir lista';

  @override
  String get playlistSingleLoop => 'Repetir uno';

  @override
  String get playlistOnce => 'Reproducir una vez';

  @override
  String get playlistOrder => 'Orden de reproducción';

  @override
  String get playlistAddVideo => 'Añadir video';

  @override
  String get playlistPendingLoadFailed =>
      'No se pudieron cargar los elementos pendientes. Toca para reintentar.';

  @override
  String get playlistPending => 'Videos pendientes · Sin subir al dispositivo';

  @override
  String get playlistPendingNote =>
      'Las entradas pendientes hacen referencia a los archivos originales. La conversión aún no está disponible. Mantén los archivos originales en su ubicación después de ajustar el encuadre.';

  @override
  String get playlistConvertPending => 'Pendiente de conversión · Sin subir';

  @override
  String get playlistFrame => 'Ajustar encuadre';

  @override
  String get playlistRemovePendingAction => 'Quitar video pendiente';

  @override
  String get playlistEmpty => 'Esta lista está vacía';

  @override
  String get playlistFirst => 'Primer video predeterminado';

  @override
  String get playlistUp => 'Mover arriba';

  @override
  String get playlistDown => 'Mover abajo';

  @override
  String get playlistRemoveDraft => 'Quitar del borrador';

  @override
  String get playlistSaveDevice =>
      'Guardar en el dispositivo · Pendiente de compatibilidad del protocolo';

  @override
  String get playlistRecovery => 'Tras desconectar Bluetooth';

  @override
  String get playlistRecoveryNote =>
      'Reanudar el video anterior del dispositivo cuando sea compatible. Pendiente de confirmación del protocolo.';

  @override
  String get playlistDisconnected => 'Dispositivo desconectado';

  @override
  String get playlistReadDeviceFailed =>
      'Red conectada · No se pudo leer el dispositivo';

  @override
  String get playlistReadDeviceReady => 'Red conectada · Toca para leer';

  @override
  String get playlistReadNote =>
      'Lee el contenido del dispositivo para verificar la conexión de control.';

  @override
  String get playlistConnectNote =>
      'Conéctate al Wi-Fi del dispositivo y luego lee su lista.';

  @override
  String get playlistRead => 'Leer';

  @override
  String playlistSourceTitle(String name) {
    return '$name · Encuadre original';
  }

  @override
  String playlistSent(String name) {
    return 'Enviado al dispositivo: $name';
  }

  @override
  String playlistRemoveNote(String name) {
    return 'Quitar «$name» solo de esta lista. Se conservarán los archivos del teléfono y del dispositivo.';
  }

  @override
  String playlistRemoved(String name) {
    return 'Se quitó $name de la lista';
  }

  @override
  String playlistCount(int count) {
    return '$count videos';
  }

  @override
  String playlistDeviceCount(int count) {
    return 'El dispositivo responde · $count videos';
  }

  @override
  String get playlistMoveToTop => 'Mover al principio';

  @override
  String get submissionDraftSaved =>
      'Borrador guardado. Sube tus videos y luego envíalos para revisión.';

  @override
  String get submissionTitle => 'Mis envíos';

  @override
  String get submissionRefresh => 'Actualizar envíos';

  @override
  String get submissionCreate => 'Crear envío';

  @override
  String get submissionEmpty =>
      'Aún no hay envíos. Crea un borrador, sube tus videos y envíalo tras la validación.';

  @override
  String get submissionUpdated => 'Envío actualizado.';

  @override
  String get submissionFree => 'Gratis';

  @override
  String get submissionPaid => 'De pago';

  @override
  String get submissionPrice => 'Precio (USD)';

  @override
  String get submissionDecimals => 'Hasta dos decimales';

  @override
  String get submissionInvalidPrice =>
      'Introduce un precio positivo en USD con hasta dos decimales.';

  @override
  String get submissionReviewNote =>
      'Todos los videos deben revisarse antes de su publicación.';

  @override
  String get submissionCancel => 'Cancelar';

  @override
  String get submissionSavePrice => 'Guardar precio';

  @override
  String get submissionSubmitted =>
      'Enviado para revisión. La edición está bloqueada durante la revisión.';

  @override
  String get submissionPartnerNote =>
      'Los socios pueden publicar videos gratuitos o de pago. Todo el contenido debe revisarse.';

  @override
  String get submissionFreeNote =>
      'Envía videos gratuitos o colecciones de personajes para revisión.';

  @override
  String get submissionCharacterPackage => 'Colección de personaje';

  @override
  String get submissionSingleVideo => 'Video individual';

  @override
  String get submissionRejectedReason => 'Cambios solicitados';

  @override
  String get submissionReviewFeedback => 'Comentarios de la revisión';

  @override
  String get submissionName => 'Título';

  @override
  String get submissionNameRequired => 'Introduce un título.';

  @override
  String get submissionFormat => 'Formato del contenido';

  @override
  String get submissionSingle => 'Video individual';

  @override
  String get submissionPackage => 'Colección de videos';

  @override
  String get submissionTags => 'Etiquetas de contenido';

  @override
  String get submissionNoTags =>
      'Las etiquetas de contenido aún no están disponibles.';

  @override
  String get submissionStory => 'Historia del personaje';

  @override
  String get submissionStoryRequired => 'Introduce una historia del personaje.';

  @override
  String get submissionVideos => 'Videos';

  @override
  String get submissionAddVideo => 'Añadir video';

  @override
  String get submissionRemoveVideo => 'Quitar video';

  @override
  String get submissionVideoNameRequired =>
      'Introduce un título para el video.';

  @override
  String get submissionSaveDraft => 'Guardar borrador';

  @override
  String get submissionSaveInfo => 'Guardar detalles';

  @override
  String get submissionCoverUploaded => 'Portada subida';

  @override
  String get submissionCover => 'Portada de la colección';

  @override
  String get submissionCoverTypes => 'JPG o PNG';

  @override
  String get submissionReplace => 'Reemplazar';

  @override
  String get submissionUpload => 'Subir';

  @override
  String get submissionSetPrice => 'Fijar precio';

  @override
  String get submissionMakeFree => 'Ofrecer gratis';

  @override
  String get submissionReplaceMp4 => 'Reemplazar MP4';

  @override
  String get submissionUploadMp4 => 'Subir MP4';

  @override
  String get submissionCheckVideo => 'Validar video';

  @override
  String get submissionResubmit => 'Volver a enviar para revisión';

  @override
  String get submissionSubmit => 'Enviar para revisión';

  @override
  String get submissionRequirements =>
      'Valida todos los videos antes de enviarlos. Las colecciones también requieren una portada.';

  @override
  String get submissionInfo => 'Detalles del contenido';

  @override
  String get submissionNoStory => 'Aún no hay historia del personaje.';

  @override
  String get submissionRetry => 'Reintentar';

  @override
  String get submissionPending => 'En revisión';

  @override
  String get submissionPublished => 'Publicado';

  @override
  String get submissionApproved => 'Aprobado, pendiente de publicación';

  @override
  String get submissionRejected => 'Cambios solicitados';

  @override
  String get submissionDraft => 'Borrador';

  @override
  String get submissionNoMedia => 'No se ha subido ningún video';

  @override
  String get submissionChecked => 'Validación superada';

  @override
  String get submissionProcessing => 'Validando video';

  @override
  String get submissionFailed =>
      'La validación falló. Reemplaza el video e inténtalo de nuevo.';

  @override
  String get submissionWaiting => 'Subido, pendiente de validación';

  @override
  String get submissionApprovalError =>
      'El acceso de creador no está aprobado o está suspendido. Consulta la página de verificación.';

  @override
  String get submissionDataError =>
      'No se pudieron leer los datos del envío. Actualiza e inténtalo de nuevo.';

  @override
  String get submissionLoadError =>
      'No se pudieron cargar los envíos. Inténtalo más tarde.';

  @override
  String get submissionSessionError =>
      'Tu sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get submissionAccessError =>
      'Se necesita una cuenta activa de creador verificado.';

  @override
  String get submissionPaidError =>
      'Esta cuenta no permite contenido de pago. Configura el video como gratuito antes de enviarlo.';

  @override
  String get submissionPriceError =>
      'Introduce un precio válido en USD con hasta dos decimales.';

  @override
  String get submissionConflictError =>
      'El envío ha cambiado. Actualiza e inténtalo de nuevo.';

  @override
  String get submissionMediaError => 'Primero sube y valida todos los videos.';

  @override
  String get submissionCoverError =>
      'Primero sube una portada para la colección.';

  @override
  String get submissionTagError =>
      'Algunas etiquetas ya no están disponibles. Actualiza y vuelve a seleccionarlas.';

  @override
  String get submissionServerError =>
      'El servicio no está disponible. Inténtalo más tarde.';

  @override
  String get submissionRequestError =>
      'No se pudo completar la acción. Revisa tu contenido e inténtalo de nuevo.';

  @override
  String get submissionAccountChanged =>
      'Tu cuenta ha cambiado. Actualiza los envíos.';

  @override
  String get submissionPreviewError =>
      'El video no se ha subido o la vista previa no está disponible.';

  @override
  String submissionVideoPrice(String name) {
    return 'Precio del video · $name';
  }

  @override
  String submissionVideoName(int index) {
    return 'Título del video $index';
  }

  @override
  String submissionLegacyTag(String name) {
    return '$name (antigua)';
  }

  @override
  String get supportContact => 'Contactar con soporte';

  @override
  String get supportInstructions =>
      'Envíanos un correo con los pasos para reproducir el problema, la versión de la aplicación y el modelo del dispositivo. Puedes adjuntar capturas de pantalla relevantes.';

  @override
  String get supportWriteEmail => 'Escribir un correo';

  @override
  String get supportCopyEmail => 'Copiar dirección de correo';

  @override
  String get supportEmailCopied => 'Dirección de correo de soporte copiada';

  @override
  String get supportCopyFailed =>
      'No se pudo copiar. Selecciona la dirección de correo para copiarla manualmente.';

  @override
  String get supportNoMailApp =>
      'No se pudo abrir una aplicación de correo. Copia la dirección y contáctanos desde tu servicio de correo.';

  @override
  String get p20Refresh => 'Actualizar lista del dispositivo';

  @override
  String get p20Daily => 'A Diario';

  @override
  String get p20Bluetooth => 'B Bluetooth';

  @override
  String get p20ConnectNote =>
      'Conéctate para ver la lista guardada en tu dispositivo';

  @override
  String get p20ConnectWifi =>
      'Conecta tu teléfono al Wi-Fi del dispositivo y luego toca Conectar dispositivo.';

  @override
  String get p20Connecting => 'Conectando…';

  @override
  String get p20Connect => 'Conectar dispositivo';

  @override
  String get p20Reading => 'Leyendo lista del dispositivo…';

  @override
  String get p20ReadFailed => 'No se pudo leer la lista del dispositivo';

  @override
  String get p20Mode => 'Modo de reproducción (compartido por A/B)';

  @override
  String get p20OrderNote =>
      'El orden procede de tu dispositivo. Al mover un video se actualiza el dispositivo y se vuelve a leer el orden confirmado.';

  @override
  String get p20Empty => 'Esta lista del dispositivo está vacía';

  @override
  String get p20Pending => 'Videos listos para subir';

  @override
  String get p20PendingNote =>
      'Estos videos están pendientes en tu teléfono y aún no se han subido al dispositivo.';

  @override
  String get p20Unconfirmed =>
      'El dispositivo no confirmó el cambio. Se ha actualizado su estado actual. Revísalo e inténtalo de nuevo.';

  @override
  String get p20UploadEntry =>
      'Abre desde una lista del dispositivo para subir';

  @override
  String get p20UploadAction => 'Convertir y subir';

  @override
  String get p20FramingNote =>
      'Se usará el encuadre actual al subir. No es necesario guardarlo por separado.';

  @override
  String p20ConnectedCount(int count) {
    return 'Dispositivo conectado · $count videos';
  }

  @override
  String get p20UploadTitle => 'Subir al dispositivo';

  @override
  String get p20UploadStart => 'Preparar y subir';

  @override
  String get p20UploadCancel => 'Cancelar carga';

  @override
  String get p20UploadClose => 'Volver a la lista';

  @override
  String get p20UploadDisconnected =>
      'Conéctate al dispositivo desde Inicio antes de subir archivos.';

  @override
  String get p20UploadDaily =>
      'La lista A Diario admite videos con o sin sonido. Con audio: se extrae el MP3, se convierte el video y se suben primero el audio y luego el video. Sin audio: solo se convierte y sube el video.';

  @override
  String get p20UploadBluetooth =>
      'La lista B Bluetooth admite videos con o sin sonido. Solo se convierte y sube el video; se ignora el audio original.';

  @override
  String get p20UploadSettings => '298 × 298 · 20 fps · Encuadre actual';

  @override
  String get p20UploadDownloadFirst =>
      'Descarga este video en Mis personajes antes de subirlo al dispositivo.';

  @override
  String get p20UploadFailed =>
      'La preparación o la carga falló. Revisa el video, la conexión del dispositivo y el almacenamiento e inténtalo de nuevo.';

  @override
  String get p20UploadConfirmedProgress => 'Confirmado por el dispositivo';

  @override
  String get p20UploadFailureStageLabel => 'Error durante';

  @override
  String get p20UploadConfirmedLabel => 'Confirmado';

  @override
  String get p20UploadBytesLabel => 'bytes';

  @override
  String get p20UploadBusy =>
      'El dispositivo está ocupado. Inténtalo en unos momentos.';

  @override
  String get p20UploadWriteFailed =>
      'El dispositivo no pudo escribir el archivo. Revisa su tarjeta de almacenamiento.';

  @override
  String get p20UploadAlreadyExists =>
      'El archivo ya existe en el dispositivo.';

  @override
  String get p20UploadStorageFull =>
      'El almacenamiento o la lista del dispositivo está lleno.';

  @override
  String get p20UploadBatteryLow =>
      'La batería del dispositivo está demasiado baja. Cárgalo e inténtalo de nuevo.';

  @override
  String get p20UploadRejected => 'El dispositivo rechazó el archivo.';

  @override
  String get p20UploadConfirmationTimeout =>
      'Se agotó el tiempo de confirmación del dispositivo. Anota la etapa y el progreso que aparecen abajo y vuelve a conectarte.';

  @override
  String get p20UploadProcessingTimeout =>
      'Se agotó el tiempo de procesamiento multimedia. Prueba con un video más corto.';

  @override
  String get p20UploadConnectionLost =>
      'Se perdió la conexión con el dispositivo. Vuelve a conectarte e inténtalo de nuevo.';

  @override
  String get p20UploadLocalFileError =>
      'No se pueden leer o escribir los archivos locales. Revisa el archivo original y el espacio disponible en el teléfono.';

  @override
  String get p20UploadInvalidReply =>
      'La respuesta del dispositivo o la secuencia de progreso no coincide. Revisa el protocolo del firmware.';

  @override
  String get p20UploadPartial =>
      'El audio se subió, pero el video no terminó de subirse. No se ha eliminado ningún archivo del dispositivo ni se ha reintentado automáticamente.';

  @override
  String get p20UploadRefreshFailed =>
      'El dispositivo confirmó la carga, pero no se pudo actualizar la lista. Vuelve a conectarte y actualiza; no subas el archivo otra vez.';

  @override
  String get p20UploadCleanupPending =>
      'Los archivos temporales siguen en uso y se han conservado.';

  @override
  String get p20UploadWaitingAcceptance => 'Esperando aceptación de la carga';

  @override
  String get p20UploadTransferring => 'Transfiriendo archivo';

  @override
  String get p20UploadWaitingCompletion =>
      'Esperando confirmación de finalización';

  @override
  String get p20UploadConfirmedCompletion =>
      'El dispositivo confirmó la finalización';

  @override
  String get p20UploadReady => 'Listo';

  @override
  String get p20UploadExtractingAudio =>
      'Comprobando y extrayendo audio si lo hay';

  @override
  String get p20UploadConvertingVideo => 'Convirtiendo video';

  @override
  String get p20UploadUploadingAudio => 'Subiendo audio';

  @override
  String get p20UploadUploadingVideo => 'Subiendo video';

  @override
  String get p20UploadRefreshing => 'Actualizando lista';

  @override
  String get p20UploadComplete => 'Carga completada';

  @override
  String get p20UploadIncomplete => 'Carga incompleta';

  @override
  String get p20UploadCancelled => 'Cancelado';

  @override
  String get p20SingleOnce => 'Reproducir una vez';

  @override
  String p20UploadFailureStage(String stage) {
    return 'Error durante: $stage';
  }

  @override
  String p20UploadTransferDetails(String phase, int acknowledged, int total) {
    return '$phase · Confirmados $acknowledged / $total bytes';
  }

  @override
  String get creatorMediaOpenFailed =>
      'No se pudo abrir este video. Actualiza tus envíos e inténtalo de nuevo.';

  @override
  String creatorMediaPreviewLabel(String title) {
    return 'Vista previa del video: $title';
  }

  @override
  String get creatorMediaThumbnailPending =>
      'La miniatura aún no está lista. Toca para ver la vista previa.';

  @override
  String get creatorMediaPreview => 'Vista previa del video';

  @override
  String get p20SingleList => 'Videos del dispositivo';

  @override
  String get p20SingleValidationPending =>
      'La carga de video para este dispositivo está pendiente de validación del hardware.';

  @override
  String get p20SingleTransferComplete =>
      'Transferencia confirmada. La reproducción está pendiente de validación del hardware.';

  @override
  String get p20DeviceType => 'Tipo de dispositivo';

  @override
  String get p20DeviceAuto => 'Detectar automáticamente';

  @override
  String get p20DeviceSingle => 'P20 (una lista, sin sonido)';

  @override
  String get p20DeviceDual => 'P20 PORTAL (dos listas, Bluetooth)';
}
