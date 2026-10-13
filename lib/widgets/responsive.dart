import 'package:flutter/widgets.dart';

const double kDesktopBreakpoint = 900;
const double kDesktopNarrowBreakpoint = 620;

bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

int gridColumnsForWidth(double width) {
  if (width >= 1600) return 8;
  if (width >= 1300) return 7;
  if (width >= 1050) return 6;
  if (width >= 800) return 5;
  if (width >= 560) return 4;
  return 3;
}
