// coverage:ignore-file
import 'package:window_manager/window_manager.dart';

import 'title_bar.dart';

class WindowManagerActions implements WindowActions {
  const WindowManagerActions();

  @override
  Future<void> minimize() => windowManager.minimize();

  @override
  Future<void> maximizeOrRestore() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Future<void> close() => windowManager.close();

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  void dragMove() => windowManager.startDragging();
}
