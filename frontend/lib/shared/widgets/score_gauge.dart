import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:gap/gap.dart';

/// A circular gauge widget that displays credit scores with animation.
///
/// Features:
/// - Animated score changes with smooth transitions
/// - Color-coded gradient arc based on score range
/// - Support for N/A state when score is null
/// - Bureau branding with logo and name
/// - Optional score label (Poor, Fair, Good, Excellent)
class ScoreGauge extends StatefulWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.bureauName,
    required this.bureauLogo,
    this.size = 120,
    this.showLabel = false,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  final int? score;
  final String bureauName;
  final IconData bureauLogo;
  final double size;
  final bool showLabel;
  final Duration animationDuration;

  /// Get the score label based on the score value
  static String getScoreLabel(int? score) {
    if (score == null) return 'Unknown';
    if (score < 580) return 'Poor';
    if (score < 670) return 'Fair';
    if (score < 740) return 'Good';
    if (score < 800) return 'Very Good';
    return 'Excellent';
  }

  /// Get the score color based on the score value
  static Color getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score < 580) return Colors.red;
    if (score < 670) return Colors.orange;
    if (score < 740) return Colors.amber;
    if (score < 800) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _previousScore;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _previousScore = 0;
    if (widget.score != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _previousScore = oldWidget.score ?? 0;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final animatedScore = widget.score != null
                ? (_previousScore! +
                        (_animation.value *
                            (widget.score! - _previousScore!)))
                    .round()
                : null;

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _ScoreGaugePainter(
                  score: animatedScore,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  scoreColor: ScoreGauge.getScoreColor(animatedScore),
                  animationValue: _animation.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (animatedScore != null) ...[
                        Text(
                          animatedScore.toString(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ScoreGauge.getScoreColor(animatedScore),
                          ),
                        ),
                        if (widget.showLabel)
                          Text(
                            ScoreGauge.getScoreLabel(animatedScore),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ScoreGauge.getScoreColor(animatedScore),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ] else ...[
                        Icon(
                          Icons.help_outline,
                          size: 32,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        Text(
                          'N/A',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const Gap(12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.bureauLogo,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const Gap(4),
            Text(
              widget.bureauName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  _ScoreGaugePainter({
    required this.score,
    required this.backgroundColor,
    required this.scoreColor,
    this.animationValue = 1.0,
  });

  final int? score;
  final Color backgroundColor;
  final Color scoreColor;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 12.0;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degreeToRadian(135),
      _degreeToRadian(270),
      false,
      backgroundPaint,
    );

    // Score arc
    if (score != null) {
      final scorePaint = Paint()
        ..shader = SweepGradient(
          startAngle: _degreeToRadian(135),
          endAngle: _degreeToRadian(405),
          colors: const [
            Colors.red,
            Colors.orange,
            Colors.amber,
            Colors.lightGreen,
            Colors.green,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Calculate the sweep angle based on score (300-850 range)
      final normalizedScore = ((score! - 300) / 550).clamp(0.0, 1.0);
      final sweepAngle = 270 * normalizedScore;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degreeToRadian(135),
        _degreeToRadian(sweepAngle),
        false,
        scorePaint,
      );
    }
  }

  double _degreeToRadian(double degree) {
    return degree * (math.pi / 180);
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.scoreColor != scoreColor;
  }
}
