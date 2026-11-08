import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

/// The window's atmosphere: near-black with two accent glows, so the floating
/// pills read like they sit on a wallpaper rather than a form.
class TricksterBackdrop extends StatelessWidget {
  const TricksterBackdrop({
    required this.accent,
    required this.child,
    super.key,
  });

  final WallpaperAccent accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff09090c),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -220,
            left: -160,
            child: _Glow(
              color: accent.color.withValues(alpha: 0.16),
              size: 620,
            ),
          ),
          Positioned(
            bottom: -260,
            right: -180,
            child: _Glow(
              color: accent.color.withValues(alpha: 0.09),
              size: 700,
            ),
          ),
          Positioned(
            top: 180,
            right: -260,
            child: _Glow(
              color: ShellTelemetryColors.nominal.withValues(alpha: 0.035),
              size: 520,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trickster's card: accent-tinted vertical gradient, a soft rim, a top
/// highlight, and a drop shadow.
class TricksterPanel extends StatelessWidget {
  const TricksterPanel({
    required this.accent,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.highlighted = false,
    super.key,
  });

  final WallpaperAccent accent;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final top = highlighted
        ? Color.lerp(accent.cardFillTop(), accent.color, 0.12)!
        : accent.cardFillTop();
    final bottom = highlighted
        ? Color.lerp(accent.cardFill(), accent.color, 0.08)!
        : accent.cardFill();
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top.withValues(alpha: 0.94), bottom.withValues(alpha: 0.90)],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: accent.color.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: Container(
                height: 1,
                color: ShellMediaColors.lightForeground.withValues(alpha: 0.06),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A small capsule for one stat, in the strip's pill grammar.
class TricksterChip extends StatelessWidget {
  const TricksterChip({
    required this.accent,
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final WallpaperAccent accent;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.cardFillTop().withValues(alpha: 0.82),
            accent.cardFill().withValues(alpha: 0.72),
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: accent.color.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ShellText.systemBarCaption.copyWith(
              color: accent.captionColor(),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: ShellText.systemBarValue.copyWith(
              fontSize: 12,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill button with an icon, matching the strip's action cards.
class TricksterButton extends StatelessWidget {
  const TricksterButton({
    required this.accent,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final WallpaperAccent accent;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          mouseCursor: onPressed == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(
            accent.color.withValues(alpha: 0.08),
          ),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.cardFillTop().withValues(alpha: 0.90),
                  accent.cardFill().withValues(alpha: 0.84),
                ],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              border: Border.all(color: accent.color.withValues(alpha: 0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: accent.captionColor()),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: ShellText.systemBarCaption.copyWith(
                    color: accent.captionColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The square cousin of [TricksterButton]: one icon in a glass capsule.
class TricksterIconButton extends StatelessWidget {
  const TricksterIconButton({
    required this.accent,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final WallpaperAccent accent;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        enabled: onPressed != null,
        child: ExcludeSemantics(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              mouseCursor: onPressed == null
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStatePropertyAll(
                accent.color.withValues(alpha: 0.08),
              ),
              onTap: onPressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.cardFillTop().withValues(alpha: 0.90),
                      accent.cardFill().withValues(alpha: 0.84),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.color.withValues(alpha: 0.16),
                  ),
                ),
                child: Center(
                  child: loading
                      ? SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent.color,
                          ),
                        )
                      : Icon(icon, size: 15, color: accent.captionColor()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The strip's staggered entrance: a short lift and fade, offset per module.
class TricksterEntrance extends StatefulWidget {
  const TricksterEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<TricksterEntrance> createState() => _TricksterEntranceState();
}

class _TricksterEntranceState extends State<TricksterEntrance>
    with SingleTickerProviderStateMixin {
  static const double _travel = 10.0;
  static const Duration _stagger = Duration(milliseconds: 55);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.cardSettle,
  );
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(_stagger * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Motion.standard,
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - t) * _travel),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// The allowance ring, animated between reads.
class TricksterGauge extends StatelessWidget {
  const TricksterGauge({
    required this.accent,
    required this.percent,
    this.limited = false,
    this.size = 76,
    super.key,
  });

  final WallpaperAccent accent;
  final double percent;
  final bool limited;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = limited ? ShellTelemetryColors.danger : accent.color;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
        duration: Motion.workspaceSwitch,
        curve: Motion.standard,
        builder: (context, value, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _GaugePainter(fraction: value, color: color),
              ),
              Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: ShellText.systemBarValue.copyWith(
                    fontSize: 12,
                    color: ShellMediaColors.lightForeground,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(5.0, size.shortestSide / 13);
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (fraction <= 0) {
      return;
    }
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

/// The window's one icon mark: a terminal glyph in an accent-tinted capsule.
class TricksterMark extends StatelessWidget {
  const TricksterMark({required this.accent, this.size = 40, super.key});

  final WallpaperAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: accent.color.withValues(alpha: 0.22)),
      ),
      child: Icon(
        LucideIcons.squareTerminal,
        size: size * 0.46,
        color: accent.captionColor(),
      ),
    );
  }
}
