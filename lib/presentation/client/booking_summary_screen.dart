import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/cupertino.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/currency/uah.dart';
import '../../data/dto/job_dto.dart';
import '../../data/shop_seed.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/shop_models.dart';
import '../widgets/ui.dart';
import 'booking_format.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  late final TextEditingController _plate;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final FocusNode _yearFocus;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _useWallet = true;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bookingProvider);
    _plate = TextEditingController(text: draft.plate);
    _brand = TextEditingController(text: draft.brand);
    _model = TextEditingController(text: draft.model);
    _year = TextEditingController(text: draft.year);
    _yearFocus = FocusNode();
  }

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _yearFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<bool?> _showRegSheet() {
    final phoneCtrl = TextEditingController();
    final s = ref.read(stringsProvider);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(CupertinoIcons.phone, size: 28, color: paletteOf(ctx).accent),
              const SizedBox(height: 12),
              Text(
                s.phone,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: paletteOf(ctx).text,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.phone,
                  prefixIcon: const Icon(CupertinoIcons.phone),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final phone = phoneCtrl.text.trim();
                  if (phone.isEmpty) {
                    return;
                  }
                  ref.read(authProvider.notifier).signIn(
                        AuthSession(
                          displayName: phone,
                          login: phone,
                          role: 'client',
                          password: 'auto_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      );
                  Navigator.of(ctx).pop(true);
                },
                child: Text(s.confirm),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final session = ref.read(authProvider);
    if (session == null || session.login.isEmpty) {
      final registered = await _showRegSheet();
      if (registered != true) {
        return;
      }
    }
    final draft = ref.read(bookingProvider);
    final shop = shopById(draft.shopId ?? '');
    final slot = draft.slot;
    if (shop == null || slot == null || draft.workIds.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    ref.read(bookingProvider.notifier).setCar(
          plate: _plate.text.trim().toUpperCase(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: _year.text.trim(),
        );
    final works = [for (final id in draft.workIds) workById(id)];
    final total = works.fold<int>(0, (sum, work) => sum + work.priceStandard);
    if (_useWallet && total > 0) {
      ref.read(tapWalletProvider.notifier).payUah(total);
    }
    final order = WorkOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plate: _plate.text.trim().toUpperCase(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      year: int.tryParse(_year.text.trim()) ?? 0,
      mileage: 0,
      vin: '',
      category: works.first.category,
      lines: [
        for (final work in works)
          OrderLine(
            workId: work.id,
            title: work.title,
            tier: PriceTier.standard,
            priceUah: work.priceStandard,
            minutes: work.minutes,
          ),
      ],
      status: JobStatus.created,
      createdAt: DateTime.now(),
      masterId: slot.masterId,
      shopId: shop.id,
      clientLogin: ref.read(authProvider)?.login ?? '',
      scheduledAt: slot.start,
    );
    ref.read(ordersProvider.notifier).save(order);
    ref.read(takenSlotsProvider.notifier).state = {
      ...ref.read(takenSlotsProvider),
      slotKey(shop.id, slot.masterId, slot.start),
    };
    try {
      await ref.read(jobsApiProvider).create(
            JobCreateRequest(
              shopId: shop.id,
              slotId: slotKey(shop.id, slot.masterId, slot.start),
              plate: order.plate,
              brand: order.brand,
              model: order.model,
              year: order.year,
              symptomId: 'unknown',
              wantId: 'repair',
              tier: 'standard',
            ),
          );
    } catch (_) {}
    if (!mounted) {
      return;
    }
    final s = ref.read(stringsProvider);
    ref.read(bookingProvider.notifier).resetBooking();
    ref.read(clientTabProvider.notifier).state = ClientTabs.car;
    ref.read(bookingsPulseProvider.notifier).state = true;
    ref.read(carSearchClearTickProvider.notifier).state++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.bookingDone)),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final draft = ref.watch(bookingProvider);
    final shop = shopById(draft.shopId ?? '');
    final slot = draft.slot;
    if (shop == null || slot == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(s.needSlot)));
    }
    final works = [for (final id in draft.workIds) workById(id)];
    final total = works.fold<int>(0, (sum, work) => sum + work.priceStandard);
    final minutes = works.fold<int>(0, (sum, work) => sum + work.minutes);
    ShopMaster? master;
    for (final item in shop.masters) {
      if (item.id == slot.masterId) {
        master = item;
      }
    }

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: palette.bg.withValues(alpha: palette.isDark ? 0.42 : 0.88),
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        title: Text(s.carShort),
      ),
      body: ScreenCanvas(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: shellListPadding(
            context,
            top: 8,
            extra: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.carbon,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.stroke),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopCoverBanner(shopId: shop.id, height: 72),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    shop.name.of(lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.text,
                    ),
                  ),
                  Text(shop.address.of(lang), style: TextStyle(color: palette.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    formatWhen(slot.start, lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: palette.accent,
                    ),
                  ),
                  Text(
                    master == null
                        ? s.anyMaster
                        : '${master.name.of(lang)} — ${specialtyLabel(s, master.specialty)}',
                    style: TextStyle(color: palette.text, fontSize: 12),
                  ),
                  if (draft.partsFromShop != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      draft.partsFromShop == true
                          ? s.partsSourceShop
                          : s.partsSourceOwn,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                    ],
                  ),
                ),
              ],
            ),
          ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final work in works)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(work.title.of(lang))),
                            Text(formatUah(work.priceStandard)),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.preTotal,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          formatUah(total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(formatEta(minutes, s), style: TextStyle(color: palette.muted)),
                    const SizedBox(height: 12),
                    _WalletPayBlock(
                      totalUah: total,
                      useWallet: _useWallet,
                      onChanged: (value) => setState(() => _useWallet = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.carShort,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _plate,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) => _dismissKeyboard(),
                        decoration: InputDecoration(
                          labelText: s.plate,
                          hintText: s.plateHint,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? s.requiredField : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _brand,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) => _dismissKeyboard(),
                        decoration: InputDecoration(labelText: s.brand),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? s.requiredField : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _model,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) => _dismissKeyboard(),
                        decoration: InputDecoration(labelText: s.model),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? s.requiredField : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _year,
                        focusNode: _yearFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(labelText: s.year),
                        onTapOutside: (_) => _dismissKeyboard(),
                        onChanged: (value) {
                          if (value.length == 4) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _dismissKeyboard();
                            });
                          }
                        },
                        onEditingComplete: _dismissKeyboard,
                        onFieldSubmitted: (_) => _dismissKeyboard(),
                        validator: (value) =>
                            value == null || value.trim().length != 4 ? s.requiredField : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                child: Text(s.confirmBooking, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}

class _WalletPayBlock extends ConsumerWidget {
  const _WalletPayBlock({
    required this.totalUah,
    required this.useWallet,
    required this.onChanged,
  });

  final int totalUah;
  final bool useWallet;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final wallet = ref.watch(tapWalletProvider);
    final palette = paletteOf(context);
    if (wallet.balanceUsdCents <= 0) {
      return const SizedBox.shrink();
    }
    final preview = wallet.spendUah(useWallet ? totalUah : 0);
    final cover = useWallet ? preview.appliedUah : 0;
    final due = (totalUah - cover).clamp(0, totalUah);
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: useWallet,
          onChanged: onChanged,
          title: Text(s.tapWalletPay, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            s.tapWalletCover(wallet.balanceLabel, formatUah(wallet.balanceUah)),
            style: TextStyle(color: palette.muted, fontSize: 13),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                s.tapWalletToPay,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              formatUah(due),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: due == 0 ? palette.accent : palette.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
