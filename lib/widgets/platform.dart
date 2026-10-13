import 'package:flutter/foundation.dart';

import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart' as impl;

bool get isDesktopPlatform => !kIsWeb && impl.isDesktopOs;
bool get isMobilePlatform => !kIsWeb && impl.isMobileOs;
