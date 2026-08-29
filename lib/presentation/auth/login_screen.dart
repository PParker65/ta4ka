import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/car_brands.dart';
import '../../data/telegram_links.dart';
import '../../data/telegram_webapp.dart';
import '../../domain/models/auth_session.dart';
import '../widgets/ios_section_switcher.dart';
import '../widgets/telegram_host.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import 'brand_pick_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _brandQuery = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  CarBrand? _brand;
  int _step = 0;
  int _dir = 1;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _brandQuery.addListener(() => setState(() {}));
    _phone.addListener(() => setState(() {}));
    _name.addListener(() => setState(() {}));
    _login.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _brandQuery.dispose();
    _phone.dispose();
    _name.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() {
      _dir = step > _step ? 1 : -1;
      _step = step;
    });
  }

  void _onBrand(CarBrand brand) {
    ref.read(bookingProvider.notifier).setCar(
          brand: brand.name.en,
        );
    setState(() => _brand = brand);
    _go(1);
  }

  void _confirmCar() {
    final s = ref.read(stringsProvider);
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.requiredField)),
      );
      return;
    }
    ref.read(bookingProvider.notifier).setCar(
          brand: _brand?.name.en,
        );
    final session = ref.read(authProvider);
    if (session != null && session.login.isNotEmpty && session.password.isNotEmpty) {
      context.go('/home');
      return;
    }
    if (_login.text.trim().isEmpty) {
      _login.text = phone;
    }
    _go(2);
  }

  void _register() {
    final s = ref.read(stringsProvider);
    if (_name.text.trim().isEmpty || _login.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.requiredField)),
      );
      return;
    }
    if (_password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.passwordShort)),
      );
      return;
    }
    ref.read(authProvider.notifier).signIn(
          AuthSession(
            displayName: _name.text.trim(),
            login: _login.text.trim(),
            role: 'client',
            password: _password.text,
          ),
        );
    ref.read(kioskProvider.notifier).reset();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        leading: _step == 0
            ? null
            : IconButton(
                onPressed: () => _go(_step - 1),
                icon: const Icon(CupertinoIcons.back),
              ),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: Column(
          children: [
            Expanded(
              child: IosSectionSwitcher(
                index: _step,
                direction: _dir,
                children: [
                  BrandPickPanel(
                    query: _brandQuery,
                    lang: lang,
                    strings: s,
                    onConfirm: _onBrand,
                  ),
                  _CarConfirmStep(
                    brand: _brand,
                    lang: lang,
                    strings: s,
                    phone: _phone,
                    onConfirm: _confirmCar,
                  ),
                  _RegisterStep(
                    strings: s,
                    name: _name,
                    login: _login,
                    password: _password,
                    obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onRegister: _register,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    if (TelegramWebApp.instance.active &&
                        TelegramWebApp.instance.user != null)
                      TextButton(
                        onPressed: () {
                          signInFromTelegram(ref);
                          context.go('/home');
                        },
                        child: Text(
                          s.telegramContinueAs(
                            TelegramWebApp.instance.user!.displayName,
                          ),
                          style: TextStyle(fontSize: 12, color: palette.accent),
                        ),
                      )
                    else if (hasTelegramBot)
                      TextButton.icon(
                        onPressed: () => openTelegramMiniApp(),
                        icon: Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 16,
                          color: palette.muted,
                        ),
                        label: Text(
                          s.telegramOpen,
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/auth/shop'),
                      child: Text(
                        s.forAutoservices,
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarConfirmStep extends StatelessWidget {
  const _CarConfirmStep({
    required this.brand,
    required this.lang,
    required this.strings,
    required this.phone,
    required this.onConfirm,
  });

  final CarBrand? brand;
  final AppLang lang;
  final AppStrings strings;
  final TextEditingController phone;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phoneLayout = isPhoneLayout(context);
    final s = strings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(phoneLayout ? 20 : 24, 12, phoneLayout ? 20 : 24, 24),
          child: GlassPanel(
            padding: EdgeInsets.all(phoneLayout ? 20 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(CupertinoIcons.number, size: 28, color: palette.text),
                const SizedBox(height: 12),
                Text(
                  s.plateTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: phoneLayout ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (brand != null) brand!.name.of(lang),
                    s.plateLead,
                  ].join('\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onConfirm(),
                  decoration: InputDecoration(
                    labelText: s.phone,
                    prefixIcon: const Icon(CupertinoIcons.phone),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onConfirm,
                  child: Text(s.confirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterStep extends StatelessWidget {
  const _RegisterStep({
    required this.strings,
    required this.name,
    required this.login,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.onRegister,
  });

  final AppStrings strings;
  final TextEditingController name;
  final TextEditingController login;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final phoneLayout = isPhoneLayout(context);
    final s = strings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(phoneLayout ? 20 : 24, 12, phoneLayout ? 20 : 24, 24),
          child: GlassPanel(
            padding: EdgeInsets.all(phoneLayout ? 20 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(CupertinoIcons.person_add, size: 28, color: palette.text),
                const SizedBox(height: 12),
                Text(
                  s.registerDetailsTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: phoneLayout ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.registerDetailsLead,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.displayName,
                    prefixIcon: const Icon(CupertinoIcons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: login,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.login,
                    prefixIcon: const Icon(CupertinoIcons.at),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  onSubmitted: (_) => onRegister(),
                  decoration: InputDecoration(
                    labelText: s.password,
                    prefixIcon: const Icon(CupertinoIcons.lock),
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRegister,
                  child: Text(s.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
