import 'package:flutter/material.dart';

import '../../models/driver_reserve_preference.dart';

class AppStrings {
  const AppStrings._(this._locale);

  final Locale _locale;

  static AppStrings of(BuildContext context) {
    return AppStrings._(Localizations.localeOf(context));
  }

  bool get _en => _locale.languageCode == 'en';
  bool get _es => _locale.languageCode == 'es';

  String pick({required String pt, required String en, required String es}) {
    if (_en) return en;
    if (_es) return es;
    return pt;
  }

  String get settingsTitle =>
      pick(pt: 'Configuracoes', en: 'Settings', es: 'Configuracion');

  String get overview =>
      pick(pt: 'Visao geral', en: 'Overview', es: 'Vision general');

  String get home => pick(pt: 'Home', en: 'Home', es: 'Inicio');

  String get journeys => pick(pt: 'Jornadas', en: 'Shifts', es: 'Jornadas');

  String get journeysShort => pick(pt: 'Jorn.', en: 'Shifts', es: 'Jorn.');

  String get goals => pick(pt: 'Objetivos', en: 'Goals', es: 'Objetivos');

  String get goalsShort => pick(pt: 'Metas', en: 'Goals', es: 'Metas');

  String get finance => pick(pt: 'Financeiro', en: 'Finance', es: 'Finanzas');

  String get financeShort => pick(pt: 'Fin.', en: 'Fin.', es: 'Fin.');

  String get settingsShort =>
      pick(pt: 'Config.', en: 'Settings', es: 'Ajustes');

  String get alertsTooltip => pick(pt: 'Avisos', en: 'Alerts', es: 'Avisos');

  String get signOutTooltip => pick(pt: 'Sair', en: 'Sign out', es: 'Salir');

  String get newItem => pick(pt: 'Novo', en: 'New', es: 'Nuevo');

  String get close => pick(pt: 'Fechar', en: 'Close', es: 'Cerrar');

  String get newJourney =>
      pick(pt: 'Nova jornada', en: 'New shift', es: 'Nueva jornada');

  String get newGoal =>
      pick(pt: 'Novo objetivo', en: 'New goal', es: 'Nuevo objetivo');

  String get newExpense =>
      pick(pt: 'Nova despesa', en: 'New expense', es: 'Nuevo gasto');

  String get newFueling => pick(
    pt: 'Novo abastecimento',
    en: 'New fueling',
    es: 'Nuevo abastecimiento',
  );

  String get newMaintenance => pick(
    pt: 'Nova manutencao',
    en: 'New maintenance',
    es: 'Nuevo mantenimiento',
  );

  String get newVehicle =>
      pick(pt: 'Novo veiculo', en: 'New vehicle', es: 'Nuevo vehiculo');

  String get newPlatform =>
      pick(pt: 'Nova plataforma', en: 'New platform', es: 'Nueva plataforma');

  String get yourDayInApp => pick(
    pt: 'Seu dia no app',
    en: 'Your day in the app',
    es: 'Tu dia en la app',
  );

  String get today => pick(pt: 'Hoje', en: 'Today', es: 'Hoy');

  String get week => pick(pt: 'Semana', en: 'Week', es: 'Semana');

  String get month => pick(pt: 'Mes', en: 'Month', es: 'Mes');

  String get custom =>
      pick(pt: 'Personalizado', en: 'Custom', es: 'Personalizado');

  String periodSummary(String periodLabel) => pick(
    pt: 'Seu resumo de ${periodLabel.toLowerCase()}',
    en: 'Your ${periodLabel.toLowerCase()} summary',
    es: 'Tu resumen de ${periodLabel.toLowerCase()}',
  );

  String get driverFallback =>
      pick(pt: 'Motorista', en: 'Driver', es: 'Conductor');

  String planLabel(String planName) =>
      pick(pt: 'Plano $planName', en: '$planName plan', es: 'Plan $planName');

  String journeysCount(int count) =>
      pick(pt: '$count jornadas', en: '$count shifts', es: '$count jornadas');

  String deliveriesCount(int count) => pick(
    pt: '$count entregas',
    en: '$count deliveries',
    es: '$count entregas',
  );

  String get account => pick(pt: 'Conta', en: 'Account', es: 'Cuenta');

  String get userFallback => pick(pt: 'usuario', en: 'user', es: 'usuario');

  String get currentNet =>
      pick(pt: 'Liquido atual', en: 'Current net', es: 'Neto actual');

  String get income => pick(pt: 'Receita', en: 'Income', es: 'Ingresos');

  String incomeDelta(String delta) => pick(
    pt: 'Receita $delta que antes',
    en: 'Income $delta vs before',
    es: 'Ingresos $delta que antes',
  );

  String get moneyFlow => pick(
    pt: 'Como o dinheiro entrou',
    en: 'How money came in',
    es: 'Como entro el dinero',
  );

  String get periodComparison => pick(
    pt: 'Comparativo do periodo',
    en: 'Period comparison',
    es: 'Comparativo del periodo',
  );

  String get leftOver => pick(pt: 'Sobrou', en: 'Left over', es: 'Sobro');

  String get deliveries =>
      pick(pt: 'Entregas', en: 'Deliveries', es: 'Entregas');

  String get freeBalance => pick(pt: 'Livre', en: 'Free', es: 'Libre');

  String get costs => pick(pt: 'Custos', en: 'Costs', es: 'Costos');

  String get distance => pick(pt: 'Distancia', en: 'Distance', es: 'Distancia');

  String get goalsDetail => pick(pt: 'Objetivos', en: 'Goals', es: 'Objetivos');

  String launchesCount(int count) => pick(
    pt: '$count lancamentos',
    en: '$count entries',
    es: '$count movimientos',
  );

  String get costPerKm => pick(pt: 'custo/km', en: 'cost/km', es: 'costo/km');

  String perJourney(String value) => pick(
    pt: '$value por jornada',
    en: '$value per shift',
    es: '$value por jornada',
  );

  String deltaLabel(double delta, String fallback) {
    final prefix = delta >= 0 ? '+' : '';
    final value = '$prefix${delta.toStringAsFixed(0)}%';
    return pick(
      pt: '$value que antes | $fallback',
      en: '$value vs before | $fallback',
      es: '$value que antes | $fallback',
    );
  }

  String get saveForLater =>
      pick(pt: 'Para guardar', en: 'Set aside', es: 'Para guardar');

  String get yourProgress =>
      pick(pt: 'Seu progresso', en: 'Your progress', es: 'Tu progreso');

  String level(int level) =>
      pick(pt: 'Nivel $level', en: 'Level $level', es: 'Nivel $level');

  String xpAndAchievements(int xp, int medals) => pick(
    pt: '$xp XP | $medals conquistas',
    en: '$xp XP | $medals achievements',
    es: '$xp XP | $medals logros',
  );

  String get viewProgress =>
      pick(pt: 'Ver progresso', en: 'View progress', es: 'Ver progreso');

  String get notEnoughHistory => pick(
    pt: 'Ainda falta historico para desenhar.',
    en: 'Not enough history to draw this yet.',
    es: 'Todavia falta historial para dibujar esto.',
  );

  String get performanceTips => pick(
    pt: 'Dicas para render mais',
    en: 'Tips to earn better',
    es: 'Consejos para rendir mas',
  );

  String get noMovement =>
      pick(pt: 'sem movimento', en: 'no activity', es: 'sin movimiento');

  String get newMovement =>
      pick(pt: 'novo movimento', en: 'new activity', es: 'nuevo movimiento');

  String get before => pick(pt: 'Antes', en: 'Before', es: 'Antes');

  String get period => pick(pt: 'Periodo', en: 'Period', es: 'Periodo');

  String get accountIdentity => pick(
    pt: 'Conta e identidade',
    en: 'Account and identity',
    es: 'Cuenta e identidad',
  );

  String get driverProfile => pick(
    pt: 'Perfil do motorista',
    en: 'Driver profile',
    es: 'Perfil del conductor',
  );

  String get driverProfileSubtitle => pick(
    pt: 'Seu nome, telefone e foto',
    en: 'Your name, phone and photo',
    es: 'Tu nombre, telefono y foto',
  );

  String get publicProfile =>
      pick(pt: 'Perfil publico', en: 'Public profile', es: 'Perfil publico');

  String get publicProfileSubtitle => pick(
    pt: 'Seu @, cidade e convite',
    en: 'Your @, city and invite',
    es: 'Tu @, ciudad e invitacion',
  );

  String get appPreferences => pick(
    pt: 'Preferencias do app',
    en: 'App preferences',
    es: 'Preferencias de la app',
  );

  String get appPreferencesSubtitle => pick(
    pt: 'Idioma, moeda e formato do app',
    en: 'Language, currency and app format',
    es: 'Idioma, moneda y formato de la app',
  );

  String get appPreferencesDescription => pick(
    pt: 'Escolha como o Omnya Driver fala com voce e mostra seus valores.',
    en: 'Choose how Omnya Driver talks to you and shows your values.',
    es: 'Elige como Omnya Driver habla contigo y muestra tus valores.',
  );

  String languageLabel(String code) => switch (code) {
    'en-US' => pick(pt: 'Ingles', en: 'English', es: 'Ingles'),
    'es-ES' => pick(pt: 'Espanhol', en: 'Spanish', es: 'Espanol'),
    _ => pick(
      pt: 'Portugues do Brasil',
      en: 'Brazilian Portuguese',
      es: 'Portugues de Brasil',
    ),
  };

  String currencyLabel(String code) => switch (code) {
    'USD' => pick(
      pt: 'Dolar americano',
      en: 'US dollar',
      es: 'Dolar estadounidense',
    ),
    'EUR' => pick(pt: 'Euro', en: 'Euro', es: 'Euro'),
    _ => pick(
      pt: 'Real brasileiro',
      en: 'Brazilian real',
      es: 'Real brasileno',
    ),
  };

  String get language => pick(pt: 'Idioma', en: 'Language', es: 'Idioma');

  String get currency => pick(pt: 'Moeda', en: 'Currency', es: 'Moneda');

  String get themeApp =>
      pick(pt: 'Tema do app', en: 'App theme', es: 'Tema de la app');

  String get darkThemeActive => pick(
    pt: 'Tema escuro ativo',
    en: 'Dark theme on',
    es: 'Tema oscuro activo',
  );

  String get lightThemeActive => pick(
    pt: 'Tema claro ativo',
    en: 'Light theme on',
    es: 'Tema claro activo',
  );

  String get automaticReserve => pick(
    pt: 'Reserva automatica',
    en: 'Automatic reserve',
    es: 'Reserva automatica',
  );

  String reserveSummary(
    DriverReservePreference preference,
    String Function(double value) currency,
  ) {
    return switch (preference.mode) {
      DriverReserveMode.none => pick(
        pt: 'Reserva desligada',
        en: 'Reserve off',
        es: 'Reserva apagada',
      ),
      DriverReserveMode.dailyPercent => pick(
        pt: '${_percentText(preference.dailyPercentage)}% do que sobrar',
        en: '${_percentText(preference.dailyPercentage)}% of what is left',
        es: '${_percentText(preference.dailyPercentage)}% de lo que sobre',
      ),
      DriverReserveMode.perDeliveryFixed => pick(
        pt: '${currency(preference.amountPerDelivery)} por entrega',
        en: '${currency(preference.amountPerDelivery)} per delivery',
        es: '${currency(preference.amountPerDelivery)} por entrega',
      ),
    };
  }

  String _percentText(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  String get records => pick(pt: 'Cadastros', en: 'Records', es: 'Registros');

  String get vehicles => pick(pt: 'Veiculos', en: 'Vehicles', es: 'Vehiculos');

  String get vehiclesSubtitle => pick(
    pt: 'Suas motos, carros e status',
    en: 'Your bikes, cars and status',
    es: 'Tus motos, autos y estado',
  );

  String get platforms =>
      pick(pt: 'Plataformas', en: 'Platforms', es: 'Plataformas');

  String get platformsSubtitle => pick(
    pt: 'Apps, restaurantes e lugares de ganho',
    en: 'Apps, restaurants and income places',
    es: 'Apps, restaurantes y lugares de ingreso',
  );

  String get communityProgress => pick(
    pt: 'Comunidade e progresso',
    en: 'Community and progress',
    es: 'Comunidad y progreso',
  );

  String get driverProgress => pick(
    pt: 'Progresso do motorista',
    en: 'Driver progress',
    es: 'Progreso del conductor',
  );

  String get driverProgressSubtitle => pick(
    pt: 'Nivel, conquistas e proximos passos',
    en: 'Level, wins and next steps',
    es: 'Nivel, logros y proximos pasos',
  );

  String get community =>
      pick(pt: 'Comunidade', en: 'Community', es: 'Comunidad');

  String get communitySubtitle => pick(
    pt: 'Chame amigos e encontre motoristas',
    en: 'Invite friends and find drivers',
    es: 'Invita amigos y encuentra conductores',
  );

  String get ranking => pick(pt: 'Ranking', en: 'Ranking', es: 'Ranking');

  String get rankingSubtitle => pick(
    pt: 'Pontos, conquistas e disputa saudavel',
    en: 'Points, achievements and friendly competition',
    es: 'Puntos, logros y competencia sana',
  );

  String get notices => pick(pt: 'Avisos', en: 'Alerts', es: 'Avisos');

  String get noticesSubtitle => pick(
    pt: 'Lembretes de jornada, metas e ganhos',
    en: 'Reminders for shifts, goals and earnings',
    es: 'Recordatorios de turnos, metas e ingresos',
  );

  String get planSupport =>
      pick(pt: 'Plano e suporte', en: 'Plan and support', es: 'Plan y soporte');

  String get subscription =>
      pick(pt: 'Assinatura', en: 'Subscription', es: 'Suscripcion');

  String get subscriptionSubtitle => pick(
    pt: 'Planos, pagamento e historico',
    en: 'Plans, payment and history',
    es: 'Planes, pago e historial',
  );

  String get securityData => pick(
    pt: 'Seguranca e dados',
    en: 'Security and data',
    es: 'Seguridad y datos',
  );

  String get securityDataSubtitle => pick(
    pt: 'Backup, privacidade e encerramento',
    en: 'Backup, privacy and account closure',
    es: 'Backup, privacidad y cierre de cuenta',
  );

  String get developerTools => pick(
    pt: 'Ferramentas internas da OmnyaTech',
    en: 'OmnyaTech internal tools',
    es: 'Herramientas internas de OmnyaTech',
  );

  String get signOut =>
      pick(pt: 'Sair da conta', en: 'Sign out', es: 'Cerrar sesion');

  String get signOutSubtitle => pick(
    pt: 'Encerrar neste aparelho',
    en: 'Leave this device',
    es: 'Salir de este dispositivo',
  );

  String get cancel => pick(pt: 'Cancelar', en: 'Cancel', es: 'Cancelar');

  String get save => pick(pt: 'Salvar', en: 'Save', es: 'Guardar');

  String get preferencesSaved => pick(
    pt: 'Preferencias atualizadas.',
    en: 'Preferences updated.',
    es: 'Preferencias actualizadas.',
  );

  String get dataStaysWithYou => pick(
    pt: 'Seus dados continuam com voce',
    en: 'Your data stays with you',
    es: 'Tus datos siguen contigo',
  );

  String get securityHeroBody => pick(
    pt: 'Aqui voce consegue copiar um backup da sua rotina e pedir encerramento da conta quando precisar.',
    en: 'Here you can copy a backup of your routine and ask to close your account whenever you need.',
    es: 'Aqui puedes copiar un backup de tu rutina y pedir cerrar tu cuenta cuando lo necesites.',
  );

  String get takeMyData =>
      pick(pt: 'Levar meus dados', en: 'Take my data', es: 'Llevar mis datos');

  String get takeMyDataBody => pick(
    pt: 'Geramos um arquivo em texto com jornadas, despesas, abastecimentos, metas e configuracoes da conta.',
    en: 'We create a text file with shifts, expenses, fuel, goals and account settings.',
    es: 'Creamos un archivo de texto con turnos, gastos, combustible, metas y configuraciones.',
  );

  String get preparing =>
      pick(pt: 'Preparando...', en: 'Preparing...', es: 'Preparando...');

  String get copyBackup =>
      pick(pt: 'Copiar backup', en: 'Copy backup', es: 'Copiar backup');

  String get backupCopied => pick(
    pt: 'Backup copiado para a area de transferencia.',
    en: 'Backup copied to clipboard.',
    es: 'Backup copiado al portapapeles.',
  );

  String get closeAccount =>
      pick(pt: 'Encerrar conta', en: 'Close account', es: 'Cerrar cuenta');

  String get closeAccountBody => pick(
    pt: 'Para evitar perda sem querer, o app registra um pedido. A equipe confere assinaturas, pagamentos e dados antes de apagar tudo.',
    en: 'To avoid accidental loss, the app creates a request. The team checks subscriptions, payments and data before deleting anything.',
    es: 'Para evitar perdidas por accidente, la app crea una solicitud. El equipo revisa suscripciones, pagos y datos antes de borrar todo.',
  );

  String get reasonOptional => pick(
    pt: 'Quer contar o motivo? Opcional',
    en: 'Want to share why? Optional',
    es: 'Quieres contar el motivo? Opcional',
  );

  String get reasonHint => pick(
    pt: 'Ex: parei de entregar por enquanto',
    en: 'Example: I stopped delivering for now',
    es: 'Ej: deje de repartir por ahora',
  );

  String get requestClosure =>
      pick(pt: 'Pedir encerramento', en: 'Request closure', es: 'Pedir cierre');

  String get sendingRequest => pick(
    pt: 'Enviando pedido...',
    en: 'Sending request...',
    es: 'Enviando solicitud...',
  );

  String get twoFactorTitle => pick(
    pt: 'Verificacao em duas etapas',
    en: 'Two-step verification',
    es: 'Verificacion en dos pasos',
  );

  String get twoFactorEnabled => pick(
    pt: 'Ativa neste login',
    en: 'Enabled for this login',
    es: 'Activa en este acceso',
  );

  String get twoFactorDisabled => pick(
    pt: 'Proteja sua conta com codigo do autenticador',
    en: 'Protect your account with an authenticator code',
    es: 'Protege tu cuenta con codigo de autenticador',
  );

  String get configureTwoFactor =>
      pick(pt: 'Configurar 2FA', en: 'Set up 2FA', es: 'Configurar 2FA');

  String get disableTwoFactor =>
      pick(pt: 'Desativar 2FA', en: 'Disable 2FA', es: 'Desactivar 2FA');
}
