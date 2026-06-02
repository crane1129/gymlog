import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatDurationLong(
                      timerState.mode == TimerMode.timer
                          ? timerState.remaining
                          : timerState.elapsed,
                    ),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: timerState.isRunning
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (timerState.mode == TimerMode.timer) ...[
                Text(
                  l10n.timer,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [30, 60, 90, 120, 180, 300].map((seconds) {
                    final isSelected = timerState.targetDuration?.inSeconds == seconds;
                    return ChoiceChip(
                      label: Text(_formatSeconds(seconds)),
                      selected: isSelected,
                      onSelected: (_) {
                        notifier.setTargetDuration(Duration(seconds: seconds));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'timer_play',
                    onPressed: timerState.isRunning ? notifier.pause : notifier.start,
                    backgroundColor: timerState.isRunning
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    child: Icon(
                      timerState.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'timer_reset',
                    onPressed: notifier.reset,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurface,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatSeconds(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
    }
    return '${seconds}s';
  }
}
