import 'dart:io';

import '../app/performance.dart';

/// Galaxy Z Fold / flagship tablets start balanced so the GLB can spin smoothly.
/// Mid phones stay on saver via [PerfProfile] frame adapter if needed.
PerfProfile bootstrapPerfProfile() {
  if (Platform.isAndroid) {
    return PerfProfile.balanced;
  }
  if (Platform.isIOS) {
    return PerfProfile.balanced;
  }
  return PerfProfile.balanced;
}
