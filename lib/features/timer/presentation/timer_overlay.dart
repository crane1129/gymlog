import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';

enum TimerMode { stopwatch, timer }

class TimerState {
  final TimerMode mode;
  final Duration elapsed;
  final Duration? targetDuration;
  final bool isRunning;

  const TimerState({
    this.mode = TimerMode.stopwatch,
    this.elapsed = Duration.zero,
    this.targetDuration,
    this.isRunning = false,
  });

  TimerState copyWith({
    TimerMode? mode,
    Duration? elapsed,
    Duration? targetDuration,
    bool? isRunning,
    bool clearTarget = false,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      elapsed: elapsed ?? this.elapsed,
      targetDuration: clearTarget ? null : (targetDuration ?? this.targetDuration),
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Duration get remaining {
    if (targetDuration == null) return Duration.zero;
    final diff = targetDuration! - elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isCompleted => mode == TimerMode.timer && remaining == Duration.zero && targetDuration != null;
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsedBeforePause = Duration.zero;

  TimerNotifier() : super(const TimerState());

  void setMode(TimerMode mode) {
    _stopTimer();
    _elapsedBeforePause = Duration.zero;
    state = TimerState(mode: mode);
  }

  void setTargetDuration(Duration duration) {
    state = state.copyWith(targetDuration: duration);
  }

  void start() {
    if (state.isRunning) return;

    _startTime = DateTime.now();
    state = state.copyWith(isRunning: true);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_startTime == null) return;

      final currentElapsed = DateTime.now().difference(_startTime!) + _elapsedBeforePause;
      state = state.copyWith(elapsed: currentElapsed);

      if (state.mode == TimerMode.timer && state.isCompleted) {
        _stopTimer();
        state = state.copyWith(isRunning: false);
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;

    _elapsedBeforePause = state.elapsed;
    _stopTimer();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _stopTimer();
    _elapsedBeforePause = Duration.zero;
    state = TimerState(
      mode: state.mode,
      targetDuration: state.targetDuration,
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});

class TimerFloatingButton extends ConsumerWidget {
  const TimerFloatingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);

    final Color bgColor;
    if (timerState.isCompleted) {
      bgColor = AppColors.secondary;
    } else if (timerState.isRunning) {
      bgColor = Theme.of(context).colorScheme.secondary;
    } else {
      bgColor = Theme.of(context).colorScheme.primary;
    }

    return FloatingActionButton(
      onPressed: () => _showTimerSheet(context),
      backgroundColor: bgColor,
      child: timerState.isRunning
          ? Text(
              _formatDuration(
                timerState.mode == TimerMode.timer
                    ? timerState.remaining
                    : timerState.elapsed,
              ),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )
          : timerState.isCompleted
              ? const Icon(Icons.check)
              : const Icon(Icons.timer),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TimerSheet(),
    );
  }
}

class TimerSheet extends ConsumerWidget {
  const TimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final progress = _calculateProgress(timerState);
    final progressColor = _getProgressColor(timerState, theme);
    final textColor = _getTextColor(timerState, theme);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 28),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 24),
          if (timerState.mode == TimerMode.timer) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [30, 60, 90, 120, 180].map((seconds) {
                final isSelected =
                    timerState.targetDuration?.inSeconds == seconds;
                return FilterChip(
                  label: Text(_formatSeconds(seconds)),
                  selected: isSelected,
                  onSelected: (_) {
                    notifier.setTargetDuration(Duration(seconds: seconds));
                  },
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  selectedColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          _buildControlRow(timerState, notifier, theme),
          const SizedBox(height: 8),
        ],
      ),
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
          iconSize: 22,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton(
          onPressed: playAction,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            minimumSize: const Size(56, 56),
            backgroundColor: playColor,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: playColor.withValues(alpha: 0.4),
          ),
          child: Icon(playIcon, size: 28),
        ),
        const SizedBox(width: 24),
        const SizedBox(width: 40, height: 40),
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
