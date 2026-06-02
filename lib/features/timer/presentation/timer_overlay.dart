import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';

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

    return FloatingActionButton(
      onPressed: () => _showTimerSheet(context),
      backgroundColor: timerState.isRunning
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primary,
      child: timerState.isRunning
          ? Text(
              _formatDuration(
                timerState.mode == TimerMode.timer
                    ? timerState.remaining
                    : timerState.elapsed,
              ),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )
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

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 32),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatDurationLong(
                timerState.mode == TimerMode.timer
                    ? timerState.remaining
                    : timerState.elapsed,
              ),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (timerState.mode == TimerMode.timer) ...[
            Wrap(
              spacing: 8,
              children: [30, 60, 90, 120, 180].map((seconds) {
                return ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: timerState.targetDuration?.inSeconds == seconds,
                  onSelected: (_) {
                    notifier.setTargetDuration(Duration(seconds: seconds));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                iconSize: 32,
                onPressed: timerState.isRunning ? notifier.pause : notifier.start,
                icon: Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                iconSize: 32,
                onPressed: notifier.reset,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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
}
