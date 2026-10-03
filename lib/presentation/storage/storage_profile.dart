import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/storage_cloud_api.dart';
import '../../domain/models/auth_session.dart';
import 'storage_l10n.dart';

Future<void> openStorageProfile(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const StorageProfileSheet(),
  );
}

class StorageProfileSheet extends ConsumerStatefulWidget {
  const StorageProfileSheet({super.key});

  @override
  ConsumerState<StorageProfileSheet> createState() => _StorageProfileSheetState();
}

class _StorageProfileSheetState extends ConsumerState<StorageProfileSheet> {
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  var _obscure = true;
  var _busy = false;
  String? _status;
  var _statusError = false;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  void _showStatus(String text, {required bool error}) {
    if (!mounted) return;
    setState(() {
      _status = text;
      _statusError = error;
    });
  }

  Future<void> _changePassword(AuthSession session, StorageL10n l10n) async {
    if (_busy) return;
    final old = _old.text;
    final next = _next.text;
    if (old.isEmpty || next.isEmpty) {
      _showStatus(l10n.needPassword, error: true);
      return;
    }
    if (next.length < 8) {
      _showStatus(l10n.passwordShort, error: true);
      return;
    }
    if (next != _again.text) {
      _showStatus(l10n.passwordMismatch, error: true);
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final token = session.token.trim();
      final cloud = useStorageCloud() || token.isNotEmpty;
      if (cloud) {
        if (token.isEmpty) {
          _showStatus(l10n.passwordFailed, error: true);
          return;
        }
        await StorageCloudApi.instance.changePassword(
          token: token,
          oldPassword: old,
          newPassword: next,
        );
      } else if (session.password.isNotEmpty && session.password != old) {
        _showStatus(l10n.wrongPassword, error: true);
        return;
      }
      ref.read(authProvider.notifier).signIn(session.copyWith(password: next));
      _old.clear();
      _next.clear();
      _again.clear();
      _showStatus(l10n.passwordChanged, error: false);
    } on StorageCloudException catch (e) {
      final text = e.unauthorized
          ? l10n.wrongPassword
          : (e.code == 'weak' ? l10n.passwordShort : l10n.passwordFailed);
      _showStatus(text, error: true);
    } catch (_) {
      _showStatus(l10n.passwordFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StorageL10n(ref.watch(localeProvider));
    final session = ref.watch(authProvider);
    final palette = paletteOf(context);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final storedShop = session.shopName.trim().isNotEmpty
        ? session.shopName.trim()
        : (session.displayName.trim().isNotEmpty && !session.displayName.contains('@')
            ? session.displayName.trim()
            : '');
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profile,
              style: TextStyle(
                color: palette.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (storedShop.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.wrench),
                title: Text(l10n.shopName),
                subtitle: Text(storedShop),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.at),
              title: Text(l10n.email),
              subtitle: Text(session.login),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.changePassword,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _old,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                prefixIcon: const Icon(CupertinoIcons.lock),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _next,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                prefixIcon: const Icon(CupertinoIcons.lock_shield),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _again,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.passwordAgain,
                prefixIcon: const Icon(CupertinoIcons.lock_shield),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 14),
              Text(
                _status!,
                style: TextStyle(
                  color: _statusError ? palette.danger : const Color(0xFF1B7F4E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: const ButtonStyle(
                alignment: Alignment.center,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
              ),
              onPressed: _busy ? null : () => _changePassword(session, l10n),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        l10n.changePassword,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: const ButtonStyle(
                alignment: Alignment.center,
                padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).signOut();
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.square_arrow_right, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.logout,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
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
