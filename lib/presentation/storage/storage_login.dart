import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preview_context.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/demo_staff.dart';
import '../../data/local_accounts.dart';
import '../../data/shop_auth_api.dart';
import '../../data/storage_cloud_api.dart';
import '../../domain/models/auth_session.dart';
import '../auth/register_notice.dart';
import '../widgets/language_switcher.dart';
import '../widgets/theme_switcher.dart';
import 'storage_l10n.dart';

class StorageLoginPanel extends ConsumerStatefulWidget {
  const StorageLoginPanel({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<StorageLoginPanel> createState() => _StorageLoginPanelState();
}

class _StorageLoginPanelState extends ConsumerState<StorageLoginPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _shop = TextEditingController();
  var _register = false;
  var _obscure = true;
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    _shop.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _storageAuthMessage(
    AppStrings s,
    StorageCloudException e, {
    required bool registering,
  }) {
    if (e.exists) return s.accountExists;
    switch (e.code) {
      case 'unauthorized':
        return registering ? s.shopAuthOffline : s.shopAuthUnauthorized;
      case 'email':
        return s.shopEmailInvalid;
      case 'weak':
        return s.passwordShort;
      case 'shop':
        return s.shopNameHint;
      default:
        return s.shopAuthOffline;
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final s = ref.read(stringsProvider);
    final login = _email.text.trim();
    final pass = _password.text;
    if (login.isEmpty || pass.isEmpty) {
      _toast(s.loginError);
      return;
    }
    if (_register) {
      final shop = _shop.text.trim();
      if (shop.isEmpty) {
        _toast(s.shopNameHint);
        return;
      }
      if (!isShopEmail(login)) {
        _toast(s.shopEmailInvalid);
        return;
      }
      if (pass.length < 8) {
        _toast(s.passwordShort);
        return;
      }
      if (pass != _password2.text) {
        _toast(s.passwordMismatch);
        return;
      }
      setState(() => _busy = true);
      try {
        if (useStorageCloud()) {
          final cloud = await StorageCloudApi.instance.register(
            email: login,
            password: pass,
            shopName: shop,
          );
          if (!mounted) return;
          _enter(
            cloud.shopName.isEmpty ? shop : cloud.shopName,
            cloud.email,
            'storage',
            pass,
            token: cloud.token,
            shopName: cloud.shopName.isEmpty ? shop : cloud.shopName,
          );
          if (!mounted) return;
          await showRegisterPersistNotice(context, s);
        } else {
          final account = await LocalAccountStore.instance.register(
            email: login,
            password: pass,
            displayName: shop,
            shopName: shop,
            role: 'storage',
          );
          if (!mounted) return;
          _enter(account.resolvedShopName, account.email, account.role, pass,
              shopName: account.resolvedShopName);
          if (!mounted) return;
          await showRegisterPersistNotice(context, s);
        }
      } on StorageCloudException catch (e) {
        if (e.exists && mounted) setState(() => _register = false);
        _toast(_storageAuthMessage(s, e, registering: true));
      } on LocalAccountException catch (e) {
        if (e.code == 'exists') {
          if (mounted) setState(() => _register = false);
          _toast(s.accountExists);
        } else {
          _toast(s.shopEmailInvalid);
        }
      } catch (_) {
        _toast(s.shopAuthOffline);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (DemoStaff.isShopAdmin(login, pass)) {
      _enter('AutoShift', DemoStaff.shopLogin, 'shop_admin', pass);
      return;
    }
    final staff = DemoStaff.matchStaff(login, pass);
    if (staff != null) {
      _enter(
        staff.name,
        staff.login,
        staff.isReceptionist ? 'receptionist' : 'master',
        pass,
      );
      return;
    }
    if (DemoStaff.isReviewerClient(login, pass)) {
      _enter(DemoStaff.clientName, DemoStaff.clientLogin, 'client', pass);
      return;
    }

    setState(() => _busy = true);
    try {
      if (useStorageCloud()) {
        final cloud = await StorageCloudApi.instance.login(
          email: login,
          password: pass,
        );
        if (!mounted) return;
        _enter(
          cloud.shopName.isEmpty ? cloud.email : cloud.shopName,
          cloud.email,
          'storage',
          pass,
          token: cloud.token,
          shopName: cloud.shopName,
        );
        return;
      }
      final account = await LocalAccountStore.instance.authenticate(login, pass);
      if (account != null) {
        _enter(account.resolvedShopName, account.email, account.role, pass,
            shopName: account.resolvedShopName);
        return;
      }
      _toast(s.shopAuthUnauthorized);
    } on StorageCloudException catch (e) {
      _toast(_storageAuthMessage(s, e, registering: false));
    } catch (_) {
      _toast(s.shopAuthOffline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enter(
    String name,
    String login,
    String role,
    String password, {
    String token = '',
    String shopName = '',
  }) {
    ref.read(authProvider.notifier).signIn(
          AuthSession(
            displayName: name,
            login: login,
            role: role,
            password: password,
            token: token,
            shopName: shopName.isEmpty ? name : shopName,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StorageL10n(ref.watch(localeProvider));
    final palette = paletteOf(context);
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: widget.embedded
          ? AppBar(
              title: Text(l10n.deskLoginTitle),
              actions: const [LanguageSwitcher(), AppBarTools(showWallet: false, showProfile: false)],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                if (!widget.embedded)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isKolesaSaveHost() ? 'KOLESA SAVE' : 'AUTOSHIFT',
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.2,
                          ),
                        ),
                      ),
                      const LanguageSwitcher(),
                      const ThemeSwitcher(),
                    ],
                  ),
                const SizedBox(height: 22),
                Text(
                  l10n.deskLoginTitle,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deskLoginLead,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l10n.signIn)),
                    ButtonSegment(value: true, label: Text(l10n.register)),
                  ],
                  selected: {_register},
                  onSelectionChanged: _busy
                      ? null
                      : (value) => setState(() => _register = value.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(CupertinoIcons.at),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: _register ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_register) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(CupertinoIcons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      ),
                    ),
                  ),
                ),
                if (_register) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password2,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.passwordAgain,
                      prefixIcon: const Icon(CupertinoIcons.lock_shield),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _shop,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.shopName,
                      hintText: l10n.shopNameHint,
                      prefixIcon: const Icon(CupertinoIcons.wrench),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_register ? l10n.register : l10n.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
