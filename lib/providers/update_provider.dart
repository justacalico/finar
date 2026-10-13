import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/update/app_update.dart';
import '../core/update/version_checker.dart';
import '../core/utils/version_utils.dart';

sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.update);
  final AppUpdate update;
}

class UpdateFailed extends UpdateState {
  const UpdateFailed();
}

final updateCheckerProvider =
    Provider<UpdateChecker>((ref) => UpdateChecker(client: http.Client()));

final updateProvider =
    NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateIdle();

  Future<void> check(String currentVersion) async {
    if (state is UpdateChecking) return;
    state = const UpdateChecking();
    try {
      final update = await ref
          .read(updateCheckerProvider)
          .check(Version.tryParse(currentVersion) ?? const Version(0, 0, 0));
      state =
          update == null ? const UpdateUpToDate() : UpdateAvailable(update);
    } catch (_) {
      state = const UpdateFailed();
    }
  }
}
