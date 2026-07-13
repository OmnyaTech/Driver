import 'dart:math' as math;

import 'package:flutter/material.dart';

class OmnyaVisualTokens {
  const OmnyaVisualTokens._();

  static const electricBlue = Color(0xFF0500FF);
  static const omnyaPrimary = Color(0xFF0000CD);
  static const omnyaPrimaryDark = Color(0xFF00009E);
  static const omnyaPrimaryLight = Color(0xFFD9D9F8);
  static const neonBlue = Color(0xFF2C6CFF);
  static const cyan = Color(0xFF00E5FF);
  static const violet = Color(0xFF6C4DFF);
  static const income = Color(0xFF1FAE6B);
  static const expense = Color(0xFFE5484D);
  static const reserved = Color(0xFF6C63FF);
  static const neutralData = Color(0xFFF2A93B);
  static const graphite = Color(0xFF111724);
  static const deepSpace = Color(0xFF050811);
  static const cardDark = Color(0xFF121825);
  static const cardLight = Color(0xFFFFFFFF);
  static const gold = Color(0xFFFFC857);
  static const silver = Color(0xFFC9D4E5);
  static const bronze = Color(0xFFC98752);
}

class OmnyaAnimatedEntrance extends StatelessWidget {
  const OmnyaAnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayed = delay == Duration.zero
            ? value
            : ((value * (520 + delay.inMilliseconds) - delay.inMilliseconds) /
                      520)
                  .clamp(0.0, 1.0);
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - delayed)),
            child: Transform.scale(
              scale: 0.98 + (delayed * 0.02),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class OmnyaAtmosphere extends StatelessWidget {
  const OmnyaAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF040711),
                        Color(0xFF07101E),
                        Color(0xFF03050C),
                      ]
                    : const [
                        Color(0xFFF9FBFF),
                        Color(0xFFF2F6FF),
                        Color(0xFFEFF3FF),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _OmnyaAtmospherePainter(isDark: isDark)),
        ),
        child,
      ],
    );
  }
}

class OmnyaGlassCard extends StatelessWidget {
  const OmnyaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.highlight = false,
    this.borderRadius = 24,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;
  final double borderRadius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final borderColor = highlight
        ? OmnyaVisualTokens.neonBlue.withValues(alpha: isDark ? 0.58 : 0.38)
        : Theme.of(
            context,
          ).dividerColor.withValues(alpha: isDark ? 0.86 : 0.65);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  OmnyaVisualTokens.cardDark.withValues(alpha: 0.96),
                  const Color(0xFF0C1220).withValues(alpha: 0.92),
                ]
              : [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF5F7FF).withValues(alpha: 0.92),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: (glowColor ?? OmnyaVisualTokens.electricBlue)
                      .withValues(alpha: highlight ? 0.18 : 0.035),
                  blurRadius: highlight ? 26 : 14,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

class OmnyaHeroCard extends StatelessWidget {
  const OmnyaHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 30,
    this.compact = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: OmnyaVisualTokens.electricBlue.withValues(alpha: 0.25),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: compact
                      ? const [
                          Color(0xFF0F1423),
                          Color(0xFF111A35),
                          Color(0xFF0500FF),
                        ]
                      : const [
                          Color(0xFF090C16),
                          Color(0xFF12244E),
                          Color(0xFF0500FF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _OmnyaHeroGridPainter())),
          Positioned(
            right: -62,
            top: -72,
            child: _GlowOrb(
              color: OmnyaVisualTokens.cyan.withValues(alpha: 0.26),
              size: compact ? 160 : 220,
            ),
          ),
          Positioned(
            left: -54,
            bottom: -84,
            child: _GlowOrb(
              color: OmnyaVisualTokens.violet.withValues(alpha: 0.22),
              size: compact ? 140 : 200,
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class OmnyaGlowChip extends StatelessWidget {
  const OmnyaGlowChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? OmnyaVisualTokens.electricBlue.withValues(alpha: 0.26)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? OmnyaVisualTokens.cyan.withValues(alpha: 0.55)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 7)],
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: content,
    );
  }
}

class OmnyaMetricTile extends StatelessWidget {
  const OmnyaMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.detail,
    this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: OmnyaVisualTokens.cyan),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class OmnyaCard extends StatelessWidget {
  const OmnyaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return OmnyaGlassCard(
      padding: padding,
      borderRadius: 18,
      highlight: highlight,
      onTap: onTap,
      child: child,
    );
  }
}

class OmnyaEmptyState extends StatelessWidget {
  const OmnyaEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OmnyaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: OmnyaVisualTokens.omnyaPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: OmnyaVisualTokens.neonBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 5),
                Text(message, style: theme.textTheme.bodyMedium),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OmnyaProgressRing extends StatelessWidget {
  const OmnyaProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 96,
    this.color = OmnyaVisualTokens.neonBlue,
  });

  final double value;
  final Widget child;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _OmnyaProgressRingPainter(
          value: value.clamp(0, 1),
          color: color,
          trackColor: Theme.of(context).dividerColor.withValues(alpha: 0.38),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class OmnyaMiniBars extends StatelessWidget {
  const OmnyaMiniBars({super.key, required this.values, this.height = 88});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _OmnyaMiniBarsPainter(
          values: values,
          gridColor: Theme.of(context).dividerColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _OmnyaAtmospherePainter extends CustomPainter {
  const _OmnyaAtmospherePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = isDark
        ? OmnyaVisualTokens.neonBlue.withValues(alpha: 0.08)
        : OmnyaVisualTokens.neonBlue.withValues(alpha: 0.05);
    final grid = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = size.height * 0.35; y < size.height; y += 54) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), grid);
    }
    for (var x = -size.width; x < size.width * 2; x += 72) {
      canvas.drawLine(
        Offset(x, size.height * 0.32),
        Offset(x + size.width * 0.34, size.height),
        grid,
      );
    }

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              OmnyaVisualTokens.electricBlue.withValues(
                alpha: isDark ? 0.18 : 0.08,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.88, size.height * 0.12),
              radius: size.width * 0.38,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      size.width * 0.38,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _OmnyaAtmospherePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _OmnyaHeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final dy = size.height * (i / 6);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy + 26), paint);
    }
    for (var i = 0; i < 8; i++) {
      final dx = size.width * (i / 7);
      canvas.drawLine(Offset(dx, 0), Offset(dx - 42, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OmnyaProgressRingPainter extends CustomPainter {
  const _OmnyaProgressRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 10) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.45), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OmnyaProgressRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _OmnyaMiniBarsPainter extends CustomPainter {
  const _OmnyaMiniBarsPainter({required this.values, required this.gridColor});

  final List<double> values;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.38)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;
    final maxValue = math.max(1, values.reduce(math.max));
    final spacing = size.width / (values.length * 2 + 1);
    final barWidth = spacing.clamp(5, 16).toDouble();
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [OmnyaVisualTokens.cyan, OmnyaVisualTokens.electricBlue],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxValue).clamp(0.06, 1.0);
      final left = spacing + (i * spacing * 2);
      final top = size.height * (1 - normalized);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, size.height - top),
        const Radius.circular(999),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OmnyaMiniBarsPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.gridColor != gridColor;
  }
}
