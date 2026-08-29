import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/shop_brand.dart';
import '../widgets/shop_mark.dart';
import '../widgets/ui.dart';

class ShopDesignScreen extends ConsumerStatefulWidget {
  const ShopDesignScreen({super.key});

  @override
  ConsumerState<ShopDesignScreen> createState() => _ShopDesignScreenState();
}

class _ShopDesignScreenState extends ConsumerState<ShopDesignScreen> {
  late int _variant;
  late int _font;
  late final TextEditingController _word;

  @override
  void initState() {
    super.initState();
    final account = ref.read(shopAccountProvider);
    _variant = account.logoVariant.clamp(0, 11);
    _font = account.titleFont.clamp(0, 4);
    _word = TextEditingController(text: account.logoWord);
  }

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  ShopBrand _brand() {
    final account = ref.read(shopAccountProvider);
    return ShopBrand.resolve(
      name: account.shopName,
      seed: account.catalogShopId,
      sphereIds: account.sphereIds,
      workIds: account.offeredWorkIds,
      variant: _variant,
      font: _font,
      word: _word.text,
    );
  }

  void _save() {
    ref.read(shopAccountProvider.notifier).patch(
          logoVariant: _variant,
          titleFont: _font,
          logoWord: _word.text.trim(),
        );
    final s = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.shopDesignSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final account = ref.watch(shopAccountProvider);
    final brand = _brand();
    final labels = [
      s.shopLogoCrest,
      s.shopLogoSeal,
      s.shopLogoLetter,
      s.shopLogoSign,
      s.shopLogoPulse,
      s.shopLogoHex,
      s.shopLogoDiamond,
      s.shopLogoWing,
    ];
    final fonts = [s.shopFontClassic, s.shopFontAvenir, s.shopFontSerif, s.shopFontTech, s.shopFontFutura];

    return Scaffold(
      appBar: AppBar(title: Text(s.shopDesignTitle)),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(s.shopDesignLead, style: TextStyle(color: palette.muted, height: 1.4)),
            const SizedBox(height: 18),
            ColoredBox(
              color: ShopBrand.canvas,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                child: Column(
                  children: [
                    ShopMarkLive(brand: brand, size: 148, play: ShopMarkPlay.loop),
                    const SizedBox(height: 16),
                    Text(
                      account.shopName.isEmpty ? 'СТО' : account.shopName,
                      textAlign: TextAlign.center,
                      style: shopTitleStyle(brand, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.shopLogoWord, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _word,
              maxLength: 4,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: s.shopLogoWordHint,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(s.shopDesignLogo, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
            const SizedBox(height: 8),
            ShopLogoPicker(
              selected: _variant,
              brandAt: (i) => ShopBrand.resolve(
                name: account.shopName,
                seed: account.catalogShopId,
                sphereIds: account.sphereIds,
                workIds: account.offeredWorkIds,
                variant: i,
                font: _font,
                word: _word.text,
              ),
              onSelect: (i) => setState(() => _variant = i),
              labels: labels,
            ),
            const SizedBox(height: 20),
            Text(s.shopDesignFont, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < fonts.length; i++)
                  ChoiceChip(
                    label: Text(fonts[i]),
                    selected: _font == i,
                    onSelected: (_) => setState(() => _font = i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              account.shopName.isEmpty ? 'СТО' : account.shopName,
              style: shopTitleStyle(brand, size: 20, color: palette.text),
            ),
            const SizedBox(height: 22),
            Text(
              s.nearestShops,
              style: TextStyle(fontWeight: FontWeight.w700, color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.stroke),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ShopMark(brand: brand, t: 1, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.shopName.isEmpty ? 'СТО' : account.shopName,
                            style: shopTitleStyle(brand, size: 16, color: palette.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.address.isEmpty ? account.city : account.address,
                            style: TextStyle(color: palette.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(CupertinoIcons.checkmark_alt),
              label: Text(s.shopSaveDesk),
            ),
          ],
        ),
      ),
    );
  }
}
