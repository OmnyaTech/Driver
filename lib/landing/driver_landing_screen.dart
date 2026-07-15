import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../login/login_screen.dart';
import '../services/download_links_service.dart';
import '../services/referral_service.dart';
import '../utilities/state/app_session.dart';
import '../utilities/ui/omnya_visuals.dart';

const _driverLogoAsset = 'src/driver_icon/driver_icon_png.png';

class DriverLandingScreen extends StatefulWidget {
  const DriverLandingScreen({super.key, this.inviteSlug});

  final String? inviteSlug;

  @override
  State<DriverLandingScreen> createState() => _DriverLandingScreenState();
}

class _DriverLandingScreenState extends State<DriverLandingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 820;
    final inviteSlug = widget.inviteSlug;

    return Scaffold(
      body: _LandingBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 44,
                    18,
                    compact ? 18 : 44,
                    0,
                  ),
                  child: Column(
                    children: [
                      _LandingNav(
                        onDownload: () => _openDownload(context, inviteSlug),
                      ),
                      const SizedBox(height: 28),
                      _HeroSection(
                        compact: compact,
                        inviteSlug: inviteSlug,
                        onDownload: () => _openDownload(context, inviteSlug),
                      ),
                      const _LandingTicker(),
                    ],
                  ),
                ),
                _SectionBand(child: _HowItWorksSection(compact: compact)),
                _SectionBand(
                  dark: true,
                  child: _FeatureSection(compact: compact),
                ),
                _SectionBand(child: _CommunitySection(compact: compact)),
                _SectionBand(
                  dark: true,
                  child: _PlanSection(
                    compact: compact,
                    onDownload: () => _openDownload(context, inviteSlug),
                  ),
                ),
                const _SectionBand(child: _FaqSection()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 44,
                    34,
                    compact ? 18 : 44,
                    44,
                  ),
                  child: _FinalDownloadBlock(
                    onDownload: () => _openDownload(context, inviteSlug),
                  ),
                ),
                const _LandingFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDownload(BuildContext context, String? inviteSlug) {
    final query = inviteSlug == null || inviteSlug.trim().isEmpty
        ? ''
        : '?ref=${Uri.encodeQueryComponent(inviteSlug)}';
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: '/download$query'),
        builder: (_) => DriverDownloadGateScreen(inviteSlug: inviteSlug),
      ),
    );
  }
}

class DriverDownloadGateScreen extends StatefulWidget {
  const DriverDownloadGateScreen({super.key, this.inviteSlug});

  final String? inviteSlug;

  @override
  State<DriverDownloadGateScreen> createState() =>
      _DriverDownloadGateScreenState();
}

class _DriverDownloadGateScreenState extends State<DriverDownloadGateScreen> {
  final _downloadLinksService = const DownloadLinksService();

  bool _captured = false;
  late Future<DriverDownloadLinks> _downloadLinksFuture;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _downloadLinksFuture = _downloadLinksService.fetchLinks();
    _captureReferral();
  }

  Future<void> _captureReferral() async {
    if (_captured) return;
    _captured = true;
    final slug = widget.inviteSlug;
    if (slug == null || slug.trim().isEmpty) return;
    await ReferralService().captureReferralFromUri(
      Uri.parse('https://driver.omnyatech.com.br/convite/$slug'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    if (!session.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!session.isAuthenticated) {
      return _LandingBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: math
                          .max(720, MediaQuery.sizeOf(context).height - 120)
                          .toDouble(),
                      child: const LoginScreen(
                        startInSignUp: true,
                        downloadMode: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final profile = session.profile;
    return Scaffold(
      body: _LandingBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: OmnyaGlassCard(
                  highlight: true,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(_driverLogoAsset, width: 82, height: 82),
                      const SizedBox(height: 18),
                      Text(
                        'Seu cadastro esta pronto',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile == null
                            ? 'Agora voce pode baixar o APK do Driver e continuar a configuracao pelo aplicativo.'
                            : '${profile.displayName}, agora voce pode baixar o APK do Driver e continuar a configuracao pelo aplicativo.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      FutureBuilder<DriverDownloadLinks>(
                        future: _downloadLinksFuture,
                        builder: (context, snapshot) {
                          final links = snapshot.data;
                          final loading =
                              snapshot.connectionState ==
                              ConnectionState.waiting;
                          return Column(
                            children: [
                              FilledButton.icon(
                                onPressed: loading || links == null
                                    ? null
                                    : () => _downloadApk(links.mediafireApkUrl),
                                icon: const Icon(Icons.download_rounded),
                                label: Text(
                                  loading
                                      ? 'Preparando download'
                                      : 'Baixar pelo MediaFire',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: OmnyaVisualTokens.cyan,
                                  foregroundColor: const Color(0xFF03101D),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Instale apenas o arquivo baixado deste dominio oficial.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_downloadError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _downloadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadApk(String rawUrl) async {
    setState(() => _downloadError = null);
    final uri = Uri.parse(rawUrl);
    final resolved = uri.hasScheme ? uri : Uri.base.resolveUri(uri);
    final opened = await launchUrl(
      resolved,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() {
        _downloadError =
            'Nao consegui abrir o download agora. Tente novamente em alguns segundos.';
      });
    }
  }
}

class _LandingBackdrop extends StatelessWidget {
  const _LandingBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF02050D),
                  Color(0xFF06142A),
                  Color(0xFF03060F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _NeonGridScene()),
        child,
      ],
    );
  }
}

class _LandingNav extends StatelessWidget {
  const _LandingNav({required this.onDownload});

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: Row(
        children: [
          Image.asset(_driverLogoAsset, width: 38, height: 38),
          const SizedBox(width: 10),
          Text(
            'Driver',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onDownload, child: const Text('Download')),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.compact,
    required this.inviteSlug,
    required this.onDownload,
  });

  final bool compact;
  final String? inviteSlug;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final heroText = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (inviteSlug != null) _NeonPill(label: 'Convite de @$inviteSlug'),
        const SizedBox(height: 14),
        Text(
          'Controle sua rotina de entregas sem planilha',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 34 : 54,
            height: 1.04,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Registre jornadas, ganhos, plataformas, custos, metas e conquistas em um app feito para quem vive da rua.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Quero baixar o Driver'),
          style: FilledButton.styleFrom(
            minimumSize: Size(compact ? double.infinity : 280, 58),
            backgroundColor: OmnyaVisualTokens.cyan,
            foregroundColor: const Color(0xFF03101D),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 42 : 70),
        child: compact
            ? Column(
                children: [
                  heroText,
                  const SizedBox(height: 34),
                  const _DriverHologram(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: heroText),
                  const SizedBox(width: 48),
                  const Expanded(child: _DriverHologram()),
                ],
              ),
      ),
    );
  }
}

class _LandingTicker extends StatefulWidget {
  const _LandingTicker();

  static const _items = [
    'Jornada automatica',
    'Reserva de 30% configuravel',
    'Ranking entre entregadores',
    'Relatorio por plataforma',
    'Metas com aporte e retirada',
    'Missoes semanais com XP',
  ];

  @override
  State<_LandingTicker> createState() => _LandingTickerState();
}

class _LandingTickerState extends State<_LandingTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 34),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: OmnyaVisualTokens.cyan.withValues(alpha: 0.24),
          ),
        ),
        color: Colors.black.withValues(alpha: 0.22),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(-_controller.value * 0.5, 0),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var round = 0; round < 4; round++)
              for (final item in _LandingTicker._items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Text(
                        '-',
                        style: TextStyle(color: OmnyaVisualTokens.cyan),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DriverHologram extends StatefulWidget {
  const _DriverHologram();

  @override
  State<_DriverHologram> createState() => _DriverHologramState();
}

class _DriverHologramState extends State<_DriverHologram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final bob = math.sin(value * math.pi * 2) * 8;
          final glow = 0.22 + math.sin(value * math.pi * 2).abs() * 0.16;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: const Color(0xFF07111F).withValues(alpha: 0.72),
                border: Border.all(
                  color: OmnyaVisualTokens.cyan.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: OmnyaVisualTokens.cyan.withValues(alpha: glow),
                    blurRadius: 42,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HologramScanPainter(progress: value),
                    ),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateX(-0.12)
                      ..rotateY(math.sin(value * math.pi * 2) * 0.18),
                    child: Image.asset(
                      _driverLogoAsset,
                      width: 210,
                      height: 210,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            OmnyaVisualTokens.cyan.withValues(alpha: 0.86),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HologramScanPainter extends CustomPainter {
  const _HologramScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = OmnyaVisualTokens.electricBlue.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      final y = size.height * (i / 7);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final scanY = (size.height + 80) * progress - 40;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          OmnyaVisualTokens.cyan.withValues(alpha: 0.42),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 18, size.width, 36));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 18, size.width, 36), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _HologramScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = const [
      _StepData(
        title: 'Voce roda',
        text: 'Inicie automatico ou manual, o Driver acompanha tempo e km.',
        preview: 'Jornada iniciada - 00:42:10',
      ),
      _StepData(
        title: 'Voce classifica',
        text: 'Registre o que ganhou em cada plataforma, sem misturar tudo.',
        preview: 'iFood R\$ 84 - 6 entregas\nUber R\$ 52 - 4 entregas',
      ),
      _StepData(
        title: 'O Driver calcula',
        text: 'Combustivel, manutencao e despesas entram no seu lucro liquido.',
        preview: 'Liquido do dia: R\$ 198,40',
      ),
      _StepData(
        title: 'Voce evolui',
        text: 'Suba de nivel, ganhe medalhas e apareca no ranking.',
        preview: 'Nivel 7 - 1240 XP - #14 no ranking',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Um painel pra decidir melhor, nao so pra anotar',
          text:
              'O Driver organiza o que hoje fica espalhado entre apps de entrega, comprovante de posto e memoria.',
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: compact ? 1 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: compact ? 2.2 : 0.95,
          children: steps
              .asMap()
              .entries
              .map(
                (entry) => _StepCard(index: entry.key + 1, data: entry.value),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _FeatureData(
        icon: Icons.route_rounded,
        title: 'Jornadas e plataformas',
        text: 'Entenda quanto entrou por app, corrida, entrega e periodo.',
      ),
      _FeatureData(
        icon: Icons.savings_rounded,
        title: 'Metas e reservas',
        text: 'Separe dinheiro para pneu, oleo, documentos e emergencia.',
      ),
      _FeatureData(
        icon: Icons.build_rounded,
        title: 'Custos do veiculo',
        text:
            'Registre despesas, abastecimentos e manutencoes sem misturar tudo.',
      ),
      _FeatureData(
        icon: Icons.workspace_premium_rounded,
        title: 'Conquistas',
        text: 'Ganhe XP, acompanhe progresso e convide outros entregadores.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Recursos principais',
          text:
              'Tudo que o entregador precisa para registrar, comparar e evoluir sem depender de planilha.',
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: compact ? 1 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: compact ? 2.6 : 1.05,
          children: cards
              .map((item) => _FeatureCard(data: item))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.compact, required this.onDownload});

  final bool compact;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Planos para sua rotina',
          text:
              'Comece gratis com a base completa e evolua para relatorios, exportacoes e multiplos veiculos quando precisar.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _PlanCard(
              title: 'Gratuito',
              price: 'R\$ 0',
              items: const [
                'Plataformas ilimitadas',
                'Jornadas, despesas e metas',
                'Reserva automatica',
                'Conquistas e perfil publico opcional',
              ],
              highlighted: false,
              width: compact ? double.infinity : 360,
            ),
            _PlanCard(
              title: 'Premium',
              price: 'Opcional',
              items: const [
                'Multiplos veiculos',
                'Comparativos semanais, mensais e anuais',
                'Exportacao PDF e Excel',
                'Insights e relatorios completos',
              ],
              highlighted: true,
              width: compact ? double.infinity : 360,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Cadastrar e baixar'),
          style: FilledButton.styleFrom(minimumSize: const Size(260, 54)),
        ),
      ],
    );
  }
}

class _CommunitySection extends StatelessWidget {
  const _CommunitySection({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Voce nao roda sozinho',
          text:
              'Compare com outros entregadores, suba no ranking local e nacional, e desbloqueie medalhas conforme evolui.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _NeonPill(label: '+2.400 entregadores no ranking'),
            _NeonPill(label: 'XP por consistencia'),
            _NeonPill(label: 'Valores financeiros privados'),
          ],
        ),
      ],
    );

    final podium = OmnyaGlassCard(
      highlight: true,
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _PodiumDriver(position: 2, height: 92, label: 'Rota Sul'),
          _PodiumDriver(position: 1, height: 128, label: 'Top Dia'),
          _PodiumDriver(position: 3, height: 74, label: 'Sprint'),
        ],
      ),
    );

    return compact
        ? Column(children: [content, const SizedBox(height: 22), podium])
        : Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 28),
              Expanded(child: podium),
            ],
          );
  }
}

class _FaqSection extends StatefulWidget {
  const _FaqSection();

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  int _openIndex = 0;

  static const _items = [
    (
      'E seguro baixar fora da Play Store?',
      'Sim. O APK e assinado digitalmente e distribuido pelo canal oficial informado em driver.omnyatech.com.br. Quando publicarmos na Play Store, as atualizacoes passam a vir por la.',
    ),
    (
      'Por que preciso me cadastrar antes de baixar?',
      'O cadastro vincula o download a sua conta e preserva o convite de quem te indicou, quando existir.',
    ),
    (
      'O app cobra alguma coisa pra usar?',
      'Nao. O plano gratuito cobre jornadas, despesas, metas, plataformas ilimitadas e 1 veiculo ativo. Premium e opcional.',
    ),
    (
      'Meus ganhos ficam visiveis pra outros entregadores?',
      'Nao. O perfil publico mostra nivel, medalhas e ranking se voce ativar. Valores financeiros ficam privados.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Duvidas antes de baixar',
          text: 'Alguns pontos importantes para instalar com tranquilidade.',
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FaqItem(
              question: _items[i].$1,
              answer: _items[i].$2,
              open: _openIndex == i,
              onTap: () =>
                  setState(() => _openIndex = _openIndex == i ? -1 : i),
            ),
          ),
      ],
    );
  }
}

class _FinalDownloadBlock extends StatelessWidget {
  const _FinalDownloadBlock({required this.onDownload});

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: OmnyaGlassCard(
        highlight: true,
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Text(
              'Pronto para colocar ordem no corre?',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Crie sua conta, mantenha o convite vinculado e baixe o APK oficial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.74)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_for_offline_rounded),
              label: const Text('Download'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: OmnyaVisualTokens.cyan,
                foregroundColor: const Color(0xFF03101D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 18,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(_driverLogoAsset, width: 28, height: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Driver - Um produto OmnyaTech',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Text(
                'Instale apenas pelo link oficial exibido neste dominio.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.64)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: dark
          ? Colors.black.withValues(alpha: 0.24)
          : Colors.white.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

class _NeonGridScene extends StatefulWidget {
  const _NeonGridScene();

  @override
  State<_NeonGridScene> createState() => _NeonGridSceneState();
}

class _NeonGridSceneState extends State<_NeonGridScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          CustomPaint(painter: _NeonGridPainter(progress: _controller.value)),
    );
  }
}

class _NeonGridPainter extends CustomPainter {
  const _NeonGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.56;
    final bottom = size.height;
    final centerX = size.width / 2;
    final paint = Paint()
      ..color = OmnyaVisualTokens.cyan.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (var i = -10; i <= 10; i++) {
      final x = centerX + i * size.width / 12;
      canvas.drawLine(Offset(centerX, horizon), Offset(x, bottom), paint);
    }

    for (var i = 0; i < 18; i++) {
      final t = ((i + progress) / 18).clamp(0.0, 1.0);
      final y = horizon + math.pow(t, 2.2) * (bottom - horizon);
      final alpha = (0.32 * (1 - t) + 0.05).clamp(0.05, 0.32);
      paint.color = OmnyaVisualTokens.electricBlue.withValues(alpha: alpha);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;
}

class _StepData {
  const _StepData({
    required this.title,
    required this.text,
    required this.preview,
  });

  final String title;
  final String text;
  final String preview;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.data});

  final int index;
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: OmnyaVisualTokens.cyan.withValues(alpha: 0.18),
            child: Text(
              '$index',
              style: const TextStyle(
                color: OmnyaVisualTokens.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            data.text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OmnyaVisualTokens.cyan.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              data.preview,
              style: const TextStyle(
                color: OmnyaVisualTokens.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: OmnyaVisualTokens.cyan, size: 30),
          const Spacer(),
          Text(
            data.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            data.text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
          ),
        ],
      ),
    );
  }
}

class _PodiumDriver extends StatelessWidget {
  const _PodiumDriver({
    required this.position,
    required this.height,
    required this.label,
  });

  final int position;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: OmnyaVisualTokens.cyan.withValues(alpha: 0.18),
          child: Icon(
            position == 1
                ? Icons.workspace_premium_rounded
                : Icons.person_rounded,
            color: OmnyaVisualTokens.cyan,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 82,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            gradient: LinearGradient(
              colors: [
                OmnyaVisualTokens.electricBlue.withValues(alpha: 0.70),
                OmnyaVisualTokens.cyan.withValues(alpha: 0.24),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            '#$position',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.open,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          answer,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.items,
    required this.highlighted,
    required this.width,
  });

  final String title;
  final String price;
  final List<String> items;
  final bool highlighted;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OmnyaGlassCard(
        highlight: highlighted,
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NeonPill(label: highlighted ? 'Mais completo' : 'Para comecar'),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: OmnyaVisualTokens.cyan,
              ),
            ),
            const SizedBox(height: 14),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NeonPill extends StatelessWidget {
  const _NeonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: OmnyaVisualTokens.cyan.withValues(alpha: 0.46),
        ),
        color: OmnyaVisualTokens.cyan.withValues(alpha: 0.10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: OmnyaVisualTokens.cyan,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

bool shouldShowPublicLanding() {
  if (!kIsWeb) return false;
  final path = Uri.base.path;
  return path == '/' ||
      path == '/download' ||
      path == '/cadastro' ||
      path.startsWith('/convite/');
}

String? inviteSlugFromCurrentUri() {
  final uri = Uri.base;
  return ReferralService.extractReferralSlug(uri);
}
