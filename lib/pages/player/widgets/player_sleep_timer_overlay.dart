import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';

class SleepTimerOverlay extends ConsumerStatefulWidget {
  const SleepTimerOverlay({super.key});

  @override
  ConsumerState<SleepTimerOverlay> createState() => _SleepTimerOverlayState();
}

class _SleepTimerOverlayState extends ConsumerState<SleepTimerOverlay> {
  Timer? _timer;
  DateTime? _sleepEndTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncSleepTimer() {
    final playerState = ref.read(playerProvider);
    final settings = ref.read(settingsProvider);
    if (!playerState.isPlaying || settings.sleepTimerMinutes == 0) {
      _timer?.cancel();
      _timer = null;
      _sleepEndTime = null;
      if (mounted) setState(() {});
      return;
    }
    if (_timer != null && _timer!.isActive) return;
    if (settings.sleepTimerMinutes == -1) {
      _sleepEndTime = null;
    } else {
      _sleepEndTime = DateTime.now().add(
        Duration(minutes: settings.sleepTimerMinutes),
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), _onSleepTick);
    if (mounted) setState(() {});
  }

  void _onSleepTick(Timer t) {
    if (!mounted) return;
    final playerState = ref.read(playerProvider);
    final settings = ref.read(settingsProvider);
    if (!playerState.isPlaying || settings.sleepTimerMinutes == 0) {
      _timer?.cancel();
      _timer = null;
      _sleepEndTime = null;
      if (mounted) setState(() {});
      return;
    }
    if (settings.sleepTimerMinutes == -1) {
      final remaining = playerState.duration - playerState.position;
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        _timer = null;
        ref.read(playerProvider.notifier).stop();
      }
      if (mounted) setState(() {});
      return;
    }
    if (_sleepEndTime != null && DateTime.now().isAfter(_sleepEndTime!)) {
      _timer?.cancel();
      _timer = null;
      _sleepEndTime = null;
      ref.read(playerProvider.notifier).stop();
    }
    if (mounted) setState(() {});
  }

  void _cancelSleepTimer() {
    ref.read(settingsProvider.notifier).setSleepTimerMinutes(0);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(playerProvider);
    ref.watch(settingsProvider);
    ref.listen(playerProvider, (_, _) => _syncSleepTimer());
    ref.listen(settingsProvider, (_, _) => _syncSleepTimer());

    final playerState = ref.read(playerProvider);
    final settings = ref.read(settingsProvider);
    final active = playerState.isPlaying && settings.sleepTimerMinutes != 0;
    if (!active) {
      _syncSleepTimer();
      return const SizedBox.shrink();
    }
    if (_timer == null || !_timer!.isActive) _syncSleepTimer();

    Duration remaining = Duration.zero;
    if (settings.sleepTimerMinutes == -1) {
      remaining = playerState.duration - playerState.position;
    } else if (_sleepEndTime != null) {
      remaining = _sleepEndTime!.difference(DateTime.now());
      if (remaining.isNegative) remaining = Duration.zero;
    }

    final label = settings.sleepTimerMinutes == -1
        ? 'Sleep: End of episode'
        : 'Sleep: ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 56,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _cancelSleepTimer,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
