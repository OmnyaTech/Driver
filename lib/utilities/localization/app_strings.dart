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

  String get helpCenter =>
      pick(pt: 'Central de ajuda', en: 'Help center', es: 'Centro de ayuda');

  String get helpCenterSubtitle => pick(
    pt: 'Respostas rapidas e contato com suporte',
    en: 'Quick answers and support contact',
    es: 'Respuestas rapidas y contacto con soporte',
  );

  String get helpCenterIntro => pick(
    pt: 'Encontre respostas rapidas ou fale com a gente quando alguma coisa travar na rotina.',
    en: 'Find quick answers or talk to us whenever something blocks your routine.',
    es: 'Encuentra respuestas rapidas o habla con nosotros cuando algo frene tu rutina.',
  );

  String get helpCenterSearchHint => pick(
    pt: 'Pesquise por jornada, veiculo, assinatura ou seguranca',
    en: 'Search for shifts, vehicles, subscription or security',
    es: 'Busca jornadas, vehiculos, suscripcion o seguridad',
  );

  String get helpCenterAction => pick(
    pt: 'Falar com o suporte',
    en: 'Talk to support',
    es: 'Hablar con soporte',
  );

  String get helpCenterFirstSteps => pick(
    pt: 'Primeiros passos: crie sua conta com e-mail, Google ou Microsoft, complete o perfil e cadastre seu primeiro veiculo e plataforma para liberar os numeros do painel.',
    en: 'First steps: create your account with email, Google or Microsoft, complete your profile and add your first vehicle and platform to unlock the dashboard numbers.',
    es: 'Primeros pasos: crea tu cuenta con e-mail, Google o Microsoft, completa tu perfil y registra tu primer vehiculo y plataforma para liberar los numeros del panel.',
  );

  String get helpCenterVehicles => pick(
    pt: 'Veiculos: no Free voce usa 1 veiculo ativo. Se trocar de moto ou carro, arquive o antigo para manter o historico sem baguncar a frota.',
    en: 'Vehicles: on Free you use 1 active vehicle. If you change bikes or cars, archive the old one to keep history without cluttering your fleet.',
    es: 'Vehiculos: en Free usas 1 vehiculo activo. Si cambias de moto o auto, archiva el anterior para mantener el historial sin desordenar la flota.',
  );

  String get helpCenterTipJourney => pick(
    pt: 'Jornadas: inicie quando sair para trabalhar e encerre informando km final, entregas, ganhos e custos. Se esquecer aberta, o app lembra voce.',
    en: 'Shifts: start when you go to work and finish by entering final mileage, deliveries, earnings and costs. If you leave one open, the app reminds you.',
    es: 'Jornadas: inicia cuando salgas a trabajar y finaliza con kilometraje final, entregas, ingresos y costos. Si la dejas abierta, la app te avisa.',
  );

  String get helpCenterGoals => pick(
    pt: 'Objetivos: aportes nao movimentam dinheiro real. Eles so ajudam voce a separar mentalmente o que sobrou para revisao, pneu, IPVA, emergencia ou outro plano.',
    en: 'Goals: deposits do not move real money. They simply help you mentally set aside what is left for maintenance, tires, taxes, emergencies or another plan.',
    es: 'Objetivos: los aportes no mueven dinero real. Solo ayudan a separar mentalmente lo que sobro para revision, llantas, impuestos, emergencia u otro plan.',
  );

  String get helpCenterTipBilling => pick(
    pt: 'Planos e assinatura: o Premium libera historico ampliado, multiplas plataformas, exportacoes e controles avancados. O acesso muda quando o Asaas confirma o pagamento.',
    en: 'Plans and subscription: Premium unlocks deeper history, multiple platforms, exports and advanced controls. Access changes when Asaas confirms payment.',
    es: 'Planes y suscripcion: Premium libera historial ampliado, multiples plataformas, exportaciones y controles avanzados. El acceso cambia cuando Asaas confirma el pago.',
  );

  String get helpCenterTipSupport => pick(
    pt: 'Suporte: tenha em maos o e-mail da conta e, se der, gere um backup em Seguranca e dados. Isso acelera bastante o atendimento.',
    en: 'Support: keep your account email ready and, if possible, generate a backup in Security and data. That makes support much faster.',
    es: 'Soporte: ten a mano el e-mail de tu cuenta y, si puedes, genera un backup en Seguridad y datos. Eso acelera mucho la atencion.',
  );

  List<String> get helpCenterSectionLabels => [
    pick(pt: 'Primeiros passos', en: 'First steps', es: 'Primeros pasos'),
    pick(pt: 'Veiculos', en: 'Vehicles', es: 'Vehiculos'),
    pick(pt: 'Jornadas', en: 'Shifts', es: 'Jornadas'),
    pick(pt: 'Objetivos', en: 'Goals', es: 'Objetivos'),
    pick(pt: 'Planos', en: 'Plans', es: 'Planes'),
    pick(pt: 'Suporte', en: 'Support', es: 'Soporte'),
    pick(pt: 'Ainda precisa?', en: 'Still need help?', es: 'Aun necesitas?'),
  ];

  List<String> get helpCenterHighlights => [
    pick(pt: 'Busca rapida', en: 'Quick search', es: 'Busqueda rapida'),
    pick(pt: 'Suporte humano', en: 'Human support', es: 'Soporte humano'),
    pick(pt: 'Rotina sem complicar', en: 'Simple routine', es: 'Rutina simple'),
  ];

  String get helpCenterFooter => pick(
    pt: 'Nao achou o que precisava? Fale com a OmnyaTech pelo suporte do app ou pelo e-mail suporte@omnyatech.com.',
    en: 'Did not find what you need? Contact OmnyaTech through app support or suporte@omnyatech.com.',
    es: 'No encontraste lo que necesitabas? Habla con OmnyaTech por el soporte de la app o suporte@omnyatech.com.',
  );

  String get aboutOmnyaDriver =>
      pick(pt: 'Sobre o app', en: 'About the app', es: 'Sobre la app');

  String get aboutOmnyaDriverSubtitle => pick(
    pt: 'Gerencie sua renda, nao apenas suas entregas',
    en: 'Manage your income, not only your deliveries',
    es: 'Gestiona tus ingresos, no solo tus entregas',
  );

  String get aboutOmnyaDriverBody => pick(
    pt: 'O Omnya Driver foi criado para quem vive de entregas e precisa entender o que realmente sobra no fim do dia.',
    en: 'Omnya Driver was created for people who live from deliveries and need to understand what is really left at the end of the day.',
    es: 'Omnya Driver fue creado para quienes viven de entregas y necesitan entender lo que realmente queda al final del dia.',
  );

  String get aboutOmnyaDriverWhy => pick(
    pt: 'O que os apps de entrega mostram nem sempre e o que fica no bolso. Combustivel, manutencao, desgaste e despesas entram na conta. O app transforma tudo isso em numeros simples.',
    en: 'What delivery apps show is not always what stays in your pocket. Fuel, maintenance, wear and trip costs matter. The app turns all of that into simple numbers.',
    es: 'Lo que muestran las apps de entrega no siempre es lo que queda en el bolsillo. Combustible, mantenimiento, desgaste y gastos cuentan. La app transforma todo eso en numeros simples.',
  );

  String get aboutOmnyaDriverCanDo => pick(
    pt: 'Com ele voce registra jornadas, acompanha ganhos por plataforma, controla custos, entende lucro real, cria objetivos e acompanha relatorios feitos para quem esta na rua.',
    en: 'With it you track shifts, follow earnings by platform, control costs, understand real profit, create goals and read reports built for people on the road.',
    es: 'Con el registras jornadas, sigues ingresos por plataforma, controlas costos, entiendes ganancia real, creas objetivos y ves reportes hechos para quien esta en la calle.',
  );

  String get aboutOmnyaDriverBrand => pick(
    pt: 'Principios: rapidez para registrar, privacidade por padrao e clareza no lugar de complicacao. Tecnologia simples, confiavel e focada em resultado real.',
    en: 'Principles: fast records, privacy by default and clarity instead of complexity. Simple, reliable technology focused on real results.',
    es: 'Principios: rapidez para registrar, privacidad por defecto y claridad en lugar de complicacion. Tecnologia simple, confiable y enfocada en resultados reales.',
  );

  String get aboutOmnyaDriverTech => pick(
    pt: 'Desenvolvido pela OmnyaTech para autonomos que querem organizar a renda sem depender de planilha. Contato: suporte@omnyatech.com.',
    en: 'Built by OmnyaTech for independent workers who want to organize income without depending on spreadsheets. Contact: suporte@omnyatech.com.',
    es: 'Desarrollado por OmnyaTech para autonomos que quieren organizar ingresos sin depender de planillas. Contacto: suporte@omnyatech.com.',
  );

  List<String> get aboutSectionLabels => [
    pick(pt: 'Por que existe', en: 'Why it exists', es: 'Por que existe'),
    pick(
      pt: 'O que voce controla',
      en: 'What you control',
      es: 'Que controlas',
    ),
    pick(pt: 'Principios', en: 'Principles', es: 'Principios'),
    pick(pt: 'OmnyaTech', en: 'OmnyaTech', es: 'OmnyaTech'),
  ];

  List<String> get aboutHighlights => [
    pick(pt: 'Lucro real', en: 'Real profit', es: 'Ganancia real'),
    pick(pt: 'Sem planilha', en: 'No spreadsheet', es: 'Sin planilla'),
    pick(pt: 'Privado', en: 'Private', es: 'Privado'),
  ];

  String get termsOfUse =>
      pick(pt: 'Termos de uso', en: 'Terms of use', es: 'Terminos de uso');

  String get termsOfUseSubtitle => pick(
    pt: 'Regras simples para usar o app',
    en: 'Simple rules for using the app',
    es: 'Reglas simples para usar la app',
  );

  String get termsOfUseBody => pick(
    pt: 'Ao criar uma conta ou usar o Omnya Driver, voce concorda com estes termos. Se algo aqui nao fizer sentido para voce, fale com a gente antes de continuar.',
    en: 'By creating an account or using Omnya Driver, you agree to these terms. If anything here does not make sense to you, talk to us before continuing.',
    es: 'Al crear una cuenta o usar Omnya Driver, aceptas estos terminos. Si algo aqui no tiene sentido para ti, habla con nosotros antes de continuar.',
  );

  String get termsOfUseService => pick(
    pt: 'Servico: o app organiza jornadas, ganhos, despesas, veiculos, plataformas e objetivos. Os calculos dependem dos dados que voce informa e servem como apoio para sua rotina.',
    en: 'Service: the app organizes shifts, earnings, expenses, vehicles, platforms and goals. Calculations depend on the data you enter and support your routine.',
    es: 'Servicio: la app organiza jornadas, ingresos, gastos, vehiculos, plataformas y objetivos. Los calculos dependen de los datos que ingresas y apoyan tu rutina.',
  );

  String get termsOfUseAccount => pick(
    pt: 'Conta: voce pode entrar com e-mail, Google ou Microsoft. Mantenha seus dados atualizados, proteja sua senha e use 2FA se quiser uma camada extra de seguranca.',
    en: 'Account: you can sign in with email, Google or Microsoft. Keep your data updated, protect your password and use 2FA if you want extra security.',
    es: 'Cuenta: puedes entrar con e-mail, Google o Microsoft. Mantén tus datos actualizados, protege tu clave y usa 2FA si quieres mas seguridad.',
  );

  String get termsOfUseBilling => pick(
    pt: 'Assinaturas e pagamentos sao processados pelo provedor de pagamento. Recursos Premium entram quando o pagamento for confirmado. Cancelamentos, trocas de plano e vencimentos seguem o ciclo registrado no provedor.',
    en: 'Subscriptions and payments are processed by the payment provider. Premium features start when payment is confirmed. Cancellations, plan changes and due dates follow the cycle registered by the provider.',
    es: 'Suscripciones y pagos son procesados por el proveedor de pago. Premium entra cuando el pago sea confirmado. Cancelaciones, cambios de plan y vencimientos siguen el ciclo registrado por el proveedor.',
  );

  String get termsOfUseData => pick(
    pt: 'Voce pode solicitar backup, exportacao e encerramento de conta em Seguranca e dados. Perfil publico, ranking e gamificacao sao opcionais e nao exibem seus ganhos financeiros.',
    en: 'You can request backup, export and account closure in Security and data. Public profile, ranking and gamification are optional and do not show your financial earnings.',
    es: 'Puedes solicitar backup, exportacion y cierre de cuenta en Seguridad y datos. Perfil publico, ranking y gamificacion son opcionales y no muestran tus ingresos financieros.',
  );

  String get termsOfUseConduct => pick(
    pt: 'Uso adequado: nao use o app para fraude, dados falsos, acesso indevido ou copia nao autorizada. Contas que violem as regras podem ser suspensas.',
    en: 'Fair use: do not use the app for fraud, fake data, unauthorized access or unauthorized copying. Accounts that break the rules may be suspended.',
    es: 'Uso adecuado: no uses la app para fraude, datos falsos, acceso indebido o copia no autorizada. Cuentas que rompan las reglas pueden ser suspendidas.',
  );

  String get termsOfUseContact => pick(
    pt: 'Duvidas sobre estes termos podem ser enviadas para juridico@omnyatech.com.',
    en: 'Questions about these terms can be sent to juridico@omnyatech.com.',
    es: 'Dudas sobre estos terminos pueden enviarse a juridico@omnyatech.com.',
  );

  List<String> get termsSectionLabels => [
    pick(pt: 'Servico', en: 'Service', es: 'Servicio'),
    pick(pt: 'Conta', en: 'Account', es: 'Cuenta'),
    pick(pt: 'Assinatura', en: 'Subscription', es: 'Suscripcion'),
    pick(pt: 'Dados', en: 'Data', es: 'Datos'),
    pick(pt: 'Uso correto', en: 'Fair use', es: 'Uso correcto'),
    pick(pt: 'Contato', en: 'Contact', es: 'Contacto'),
  ];

  List<String> get termsHighlights => [
    pick(pt: 'Dados verdadeiros', en: 'True data', es: 'Datos reales'),
    pick(
      pt: 'Premium via Asaas',
      en: 'Premium via Asaas',
      es: 'Premium via Asaas',
    ),
    pick(
      pt: 'Ganhos privados',
      en: 'Private earnings',
      es: 'Ingresos privados',
    ),
  ];

  String get privacyPolicy => pick(
    pt: 'Politica de privacidade',
    en: 'Privacy policy',
    es: 'Politica de privacidad',
  );

  String get privacyPolicySubtitle => pick(
    pt: 'Como seus dados sao tratados',
    en: 'How your data is handled',
    es: 'Como se tratan tus datos',
  );

  String get privacyPolicyBody => pick(
    pt: 'A OmnyaTech respeita sua privacidade e trata seus dados para fazer o app funcionar com seguranca, clareza e conforme a LGPD.',
    en: 'OmnyaTech respects your privacy and handles your data so the app works safely, clearly and in line with privacy laws.',
    es: 'OmnyaTech respeta tu privacidad y trata tus datos para que la app funcione con seguridad, claridad y segun la ley.',
  );

  String get privacyPolicyCollected => pick(
    pt: 'Coletamos dados de conta, perfil, veiculos, plataformas, jornadas, entregas, custos, metas, assinatura, dispositivo, preferencias e notificacoes.',
    en: 'We collect account, profile, vehicle, platform, shift, delivery, cost, goal, subscription, device, preference and notification data.',
    es: 'Recolectamos datos de cuenta, perfil, vehiculos, plataformas, jornadas, entregas, costos, metas, suscripcion, dispositivo, preferencias y notificaciones.',
  );

  String get privacyPolicyUse => pick(
    pt: 'Usamos esses dados para calcular lucro real, gerar relatorios, enviar avisos uteis, proteger sua conta, processar assinatura e melhorar a experiencia.',
    en: 'We use this data to calculate real profit, generate reports, send useful alerts, protect your account, process subscription and improve the experience.',
    es: 'Usamos esos datos para calcular ganancia real, generar reportes, enviar avisos utiles, proteger tu cuenta, procesar suscripcion y mejorar la experiencia.',
  );

  String get privacyPolicyStorage => pick(
    pt: 'Fotos, logos, backups e arquivos ficam protegidos por permissoes de conta e politicas de seguranca. Podemos compartilhar dados com provedores essenciais, como autenticacao, hospedagem, notificacoes e pagamento, apenas para operar o servico.',
    en: 'Photos, logos, backups and files are protected by account permissions and security policies. We may share data with essential providers such as authentication, hosting, notifications and payment only to operate the service.',
    es: 'Fotos, logos, backups y archivos quedan protegidos por permisos de cuenta y politicas de seguridad. Podemos compartir datos con proveedores esenciales como autenticacion, hospedaje, notificaciones y pago solo para operar el servicio.',
  );

  String get privacyPolicyContact => pick(
    pt: 'Voce pode pedir acesso, correcao, portabilidade, exclusao ou revisao de consentimentos. Para duvidas de privacidade, fale com o suporte OmnyaTech pelos canais oficiais do app.',
    en: 'You can request access, correction, portability, deletion or consent review. For privacy questions, contact OmnyaTech support through the official app channels.',
    es: 'Puedes pedir acceso, correccion, portabilidad, eliminacion o revision de consentimientos. Para dudas de privacidad, habla con soporte OmnyaTech por los canales oficiales de la app.',
  );

  String get privacyPolicyPublicProfile => pick(
    pt: 'Perfil publico e ranking sao opcionais. Eles podem mostrar nivel, medalhas, titulo e estatisticas nao sensiveis, mas nunca seus ganhos financeiros.',
    en: 'Public profile and ranking are optional. They may show level, medals, title and non-sensitive stats, but never your financial earnings.',
    es: 'Perfil publico y ranking son opcionales. Pueden mostrar nivel, medallas, titulo y estadisticas no sensibles, pero nunca tus ingresos financieros.',
  );

  String get privacyPolicyDpo => pick(
    pt: 'Para exercer seus direitos de privacidade, use Seguranca e dados no app ou fale pelo e-mail privacidade@omnyatech.com.',
    en: 'To exercise your privacy rights, use Security and data in the app or contact privacidade@omnyatech.com.',
    es: 'Para ejercer tus derechos de privacidad, usa Seguridad y datos en la app o escribe a privacidade@omnyatech.com.',
  );

  List<String> get privacySectionLabels => [
    pick(pt: 'Dados coletados', en: 'Collected data', es: 'Datos recolectados'),
    pick(pt: 'Uso dos dados', en: 'Data use', es: 'Uso de datos'),
    pick(pt: 'Seguranca', en: 'Security', es: 'Seguridad'),
    pick(pt: 'Perfil publico', en: 'Public profile', es: 'Perfil publico'),
    pick(pt: 'Seus direitos', en: 'Your rights', es: 'Tus derechos'),
    pick(pt: 'Contato', en: 'Contact', es: 'Contacto'),
  ];

  List<String> get privacyHighlights => [
    pick(pt: 'LGPD', en: 'Privacy rights', es: 'Privacidad'),
    pick(
      pt: 'Ganhos privados',
      en: 'Private earnings',
      es: 'Ingresos privados',
    ),
    pick(
      pt: 'Permissoes por conta',
      en: 'Account permissions',
      es: 'Permisos por cuenta',
    ),
  ];

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
