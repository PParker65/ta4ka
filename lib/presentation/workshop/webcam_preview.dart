import 'webcam_preview_stub.dart'
    if (dart.library.html) 'webcam_preview_web.dart' as impl;

import 'package:flutter/widgets.dart';

Future<bool> attachShopWebcam() => impl.attachShopWebcam();

void detachShopWebcam() => impl.detachShopWebcam();

Widget? shopWebcamView() => impl.shopWebcamView();
