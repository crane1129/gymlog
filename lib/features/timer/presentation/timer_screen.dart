import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import 'timer_overlay.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.timer),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SegmentedButton<TimerMode>(
                  segments: [
                    ButtonSegment(
                      value: TimerMode.stopwatch,
                      label: Text(l10n.stopwatch),
                      icon: const Icon(Icons.timer),
                    ),
                    ButtonSegment(
                      value: TimerMode.timer,
                      label: Text(l10n.timer),
                      icon: const Icon(Icons.hourglass_bottom),
                    ),
                  ],
                  selected: {timerState.mode},
                  onSelectionChanged: (selected) {
                    notifier.setMode(selected.first);
                  },
                ),
                const SizedBox(height: 40),
                _buildCircularTimer(timerState, theme, l10n),
                const SizedBox(height: 32),
                if (timerState.mode == TimerMode.timer) ...[
                  _buildPresetChips(timerState, notifier, theme),
                  const SizedBox(height: 28),
                ],
                _buildControlRow(timerState, notifier, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(
    TimerState timerState,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final progress = _calculateProgress(timerState);
    final progressColor = _getProgressColor(timerState, theme);
    final textColor = _getTextColor(timerState, theme);
    final trackColor = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 260),
            painter: _CircularTimerPainter(
              progress: progress,
              trackColor: trackColor,
              progressColor: progressColor,
              strokeWidth: 10,
              isCompleted: timerState.isCompleted,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timerState.mode == TimerMode.stopwatch
                    ? l10n.stopwatch
                    : l10n.timer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatDurationLong(
                    timerState.mode == TimerMode.timer
                        ? timerState.remaining
                        : timerState.elapsed,
                  ),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (timerState.mode == TimerMode.stopwatch)
                Text(
                  '${timerState.elapsed.inMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                )
              else if (timerState.targetDuration != null)
                Text(
                  _formatSeconds(timerState.targetDuration!.inSeconds),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips(
    TimerState timerState,
    TimerNotifier notifier,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [30, 60, 90, 120, 180, 300].map((seconds) {
        final isSelected = timerState.targetDuration?.inSeconds == seconds;
        return FilterChip(
          label: Text(_formatSeconds(seconds)),
          selected: isSelected,
          onSelected: (_) {
            notifier.setTargetDuration(Duration(seconds: seconds));
          },
          showCheckmark: false,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlRow(
    TimerState timerState,
    TimerNotifier notifier,
    ThemeData theme,
  ) {
    final IconData playIcon;
    final VoidCallback playAction;
    final Color playColor;

    if (timerState.isCompleted) {
      playIcon = Icons.replay;
      playAction = notifier.reset;
      playColor = AppColors.secondary;
    } else if (timerState.isRunning) {
      playIcon = Icons.pause;
      playAction = notifier.pause;
      playColor = theme.colorScheme.secondary;
    } else {
      playIcon = Icons.play_arrow;
      playAction = notifier.start;
      playColor = theme.colorScheme.primary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: notifier.reset,
          icon: const Icon(Icons.refresh),
          iconSize: 24,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
        const SizedBox(width: 32),
        ElevatedButton(
          onPressed: playAction,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            minimumSize: const Size(72, 72),
            backgroundColor: playColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: playColor.withValues(alpha: 0.4),
          ),
          child: Icon(playIcon, size: 32),
        ),
        const SizedBox(width: 32),
        const SizedBox(width: 48, height: 48),
      ],
    );
  }

  double _calculateProgress(TimerState state) {
    if (state.mode == TimerMode.timer) {
      if (state.targetDuration == null ||
          state.targetDuration!.inMilliseconds == 0) {
        return 0.0;
      }
      return (state.elapsed.inMilliseconds /
              state.targetDuration!.inMilliseconds)
          .clamp(0.0, 1.0);
    }
    return (state.elapsed.inMilliseconds % 60000) / 60000;
  }

  Color _getProgressColor(TimerState state, ThemeData theme) {
    if (state.isCompleted) return AppColors.secondary;
    if (!state.isRunning && state.elapsed != Duration.zero) {
      return theme.colorScheme.primary.withValues(alpha: 0.5);
    }
    return theme.colorScheme.primary;
  }

  Color _getTextColor(TimerState state, ThemeData theme) {
    if (state.isCompleted) return AppColors.secondary;
    if (state.isRunning) return theme.colorScheme.primary;
    if (!state.isRunning && state.elapsed != Duration.zero) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }
    return theme.colorScheme.onSurface;
  }

  String _formatDurationLong(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds.$tenths';
  }

  String _formatSeconds(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
    }
    return '${seconds}s';
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool isCompleted;

  _CircularTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    if (isCompleted) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

    final endAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    final dotPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, strokeWidth / 2 + 1.5, dotPaint);

    if (!isCompleted) {
      final dotGlow = Paint()
        ..color = progressColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(dotCenter, strokeWidth / 2 + 3, dotGlow);
    }
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isCompleted != isCompleted;
  }
}
