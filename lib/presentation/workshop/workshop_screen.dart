import 'package:flutter/material.dart';

import 'shop_shell.dart';

class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShopShell(child: ShopTabsHost());
}
