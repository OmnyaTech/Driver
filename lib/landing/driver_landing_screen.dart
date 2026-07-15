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
                    ],
                  ),
                ),
                _SectionBand(child: _FeatureSection(compact: compact)),
                _SectionBand(
                  dark: true,
                  child: _PlanSection(
                    compact: compact,
                    onDownload: () => _openDownload(context, inviteSlug),
                  ),
                ),
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
                    OmnyaGlassCard(
                      highlight: true,
                      borderRadius: 18,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: OmnyaVisualTokens.cyan,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cadastre-se para liberar o APK',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Depois de criar a conta, confirme o e-mail se o Driver solicitar. Em seguida, volte para esta tela ou entre no site para baixar o APK oficial.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.76),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: math
                          .max(720, MediaQuery.sizeOf(context).height - 120)
                          .toDouble(),
                      child: const LoginScreen(startInSignUp: true),
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
                          final mediafireUrl = links?.mediafireApkUrl;

                          return Column(
                            children: [
                              FilledButton.icon(
                                onPressed: loading || links == null
                                    ? null
                                    : () => _downloadApk(links.officialApkUrl),
                                icon: const Icon(Icons.download_rounded),
                                label: Text(
                                  loading
                                      ? 'Preparando download'
                                      : 'Baixar APK do Driver',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                ),
                              ),
                              if (mediafireUrl != null) ...[
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _downloadApk(mediafireUrl),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text('Mediafire'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.32,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        if (inviteSlug != null) _NeonPill(label: 'Convite @$inviteSlug'),
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
          title: 'Um painel para decidir melhor',
          text:
              'O Driver organiza os numeros que normalmente ficam espalhados entre apps, recibos, conversas e memoria.',
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
          title: 'Comece sem Play Store',
          text:
              'Enquanto o app nao esta publicado na loja, o download oficial fica disponivel pelo cadastro no site.',
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
                '3 plataformas ativas',
                'Jornadas, despesas e metas',
                'Reserva automatica',
                'Conquistas e perfil publico opcional',
              ],
              highlighted: false,
              width: compact ? double.infinity : 360,
            ),
            _PlanCard(
              title: 'Premium',
              price: 'Ilimitado',
              items: const [
                'Plataformas ilimitadas',
                'Historico e relatorios expandidos',
                'Controles avancados',
                'Mais progresso em missoes',
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

class _DriverHologram extends StatelessWidget {
  const _DriverHologram();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 3600),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          final bob = math.sin(value * math.pi * 2) * 10;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(-0.18)
              ..rotateY(math.sin(value * math.pi * 2) * 0.12)
              ..translateByDouble(0, bob, 0, 1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OmnyaVisualTokens.cyan.withValues(alpha: 0.42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: OmnyaVisualTokens.electricBlue.withValues(
                      alpha: 0.36,
                    ),
                    blurRadius: 80,
                    spreadRadius: 8,
                  ),
                ],
                gradient: RadialGradient(
                  colors: [
                    OmnyaVisualTokens.cyan.withValues(alpha: 0.32),
                    OmnyaVisualTokens.electricBlue.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 170,
                  height: 170,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    color: const Color(0xFF061226).withValues(alpha: 0.82),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Image.asset(_driverLogoAsset),
                ),
              ),
            ),
          );
        },
      ),
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
