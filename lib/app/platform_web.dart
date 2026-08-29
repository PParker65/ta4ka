import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Mobile browsers get the lightweight web car; desktop browsers get full 3D.
bool isMobileWeb(BuildContext context) {
  if (!kIsWeb) {
    return false;
  }
  return MediaQuery.sizeOf(context).shortestSide < 620;
}
