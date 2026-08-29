import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/design_skin.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/open_link.dart';
import '../../data/telegram_links.dart';
import '../../data/telegram_webapp.dart';
import '../../domain/models/client_loyalty.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

const _supportPhone = '+48221112233';
const _supportMail = 'hello@autoshift.pl';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();

  Uint8List? _avatarBytes(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final s = ref.read(stringsProvider);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 82,
      );
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      final session = ref.read(authProvider);
      if (session == null) {
        return;
      }
      ref.read(authProvider.notifier).updateSession(
            session.copyWith(avatarBase64: base64Encode(bytes)),
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profilePhotoError)),
      );
    }
  }

  Future<void> _copy(String value) async {
    final s = ref.read(stringsProvider);
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.profileCopied)),
    );
  }

  void _showPhotoSheet() {
    final s = ref.read(stringsProvider);
    final session = ref.read(authProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: Text(s.profileTakePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: Text(s.profileChoosePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (session?.avatarBase64 != null)
                ListTile(
                  leading: const Icon(CupertinoIcons.trash),
                  title: Text(s.profileRemovePhoto),
                  onTap: () {
                    Navigator.pop(context);
                    if (session != null) {
                      ref.read(authProvider.notifier).updateSession(
                            session.copyWith(clearAvatar: true),
                          );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeName() async {
    final s = ref.read(stringsProvider);
    final session = ref.read(authProvider);
    if (session == null) {
      return;
    }
    final controller = TextEditingController(text: session.displayName);
    final next = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s.profileName),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: s.displayName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.profileCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(s.profileSave),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (next == null || next.isEmpty || !mounted) {
      return;
    }
    ref.read(authProvider.notifier).updateSession(session.copyWith(displayName: next));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.profileNameChanged)));
  }

  Future<void> _changePassword() async {
    final s = ref.read(stringsProvider);
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    var error = '';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.profileChangePassword,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: current,
                    obscureText: true,
                    decoration: InputDecoration(labelText: s.profileCurrentPassword),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: next,
                    obscureText: true,
                    decoration: InputDecoration(labelText: s.profileNewPassword),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirm,
                    obscureText: true,
                    decoration: InputDecoration(labelText: s.profileConfirmPassword),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      if (next.text != confirm.text) {
                        setSheet(() => error = s.profilePasswordMismatch);
                        return;
                      }
                      if (next.text.length < 8) {
                        setSheet(() => error = s.passwordShort);
                        return;
                      }
                      final changed = ref.read(authProvider.notifier).changePassword(
                            current: current.text,
                            next: next.text,
                          );
                      if (!changed) {
                        setSheet(() => error = s.profilePasswordWrong);
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: Text(s.profileSave),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profilePasswordChanged)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final session = ref.watch(authProvider);
    final theme = ref.watch(themeProvider);
    final palette = paletteOf(context);
    final tokens = tokensOf(context);
    final avatar = _avatarBytes(session?.avatarBase64);
    final name = session?.displayName.isNotEmpty == true ? session!.displayName : s.welcome;

    Widget avatarBubble({double r = 44}) => GestureDetector(
          onTap: session == null ? null : _showPhotoSheet,
          child: Stack(
            children: [
              CircleAvatar(
                radius: r,
                backgroundColor: palette.carbon,
                backgroundImage: avatar == null ? null : MemoryImage(avatar),
                child: avatar == null
                    ? Icon(CupertinoIcons.person_fill, size: r * 0.9, color: palette.muted)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surface, width: 2),
                  ),
                  child: Icon(CupertinoIcons.camera_fill, size: 13, color: palette.onAccent),
                ),
              ),
            ],
          ),
        );

    Widget header;
    switch (tokens.profileLayout) {
      case ProfileHeaderLayout.centerStack:
        header = Center(
          child: Column(
            children: [
              avatarBubble(),
              const SizedBox(height: 12),
              Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: palette.text)),
              if (session != null) ...[
                const SizedBox(height: 4),
                Text(session.login, style: TextStyle(color: palette.muted, fontSize: 14)),
              ],
              TextButton(onPressed: session == null ? null : _showPhotoSheet, child: Text(s.profileChangePhoto)),
            ],
          ),
        );
      case ProfileHeaderLayout.leftBanner:
        header = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.carbon,
            border: Border.all(color: palette.stroke, width: tokens.borderWidth),
          ),
          child: Row(
            children: [
              avatarBubble(r: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: palette.text)),
                    if (session != null) Text(session.login, style: TextStyle(color: palette.muted)),
                  ],
                ),
              ),
            ],
          ),
        );
      case ProfileHeaderLayout.topStatsRow:
        header = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('USR', style: TextStyle(fontFamily: 'monospace', color: palette.accent, fontWeight: FontWeight.w800))),
                Text(session?.login ?? '—', style: TextStyle(fontFamily: 'monospace', color: palette.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: palette.text)),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: avatarBubble(r: 28)),
          ],
        );
      case ProfileHeaderLayout.splitHero:
        header = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: palette.text, height: 1.05)),
                  if (session != null) ...[
                    const SizedBox(height: 6),
                    Text(session.login, style: TextStyle(color: palette.muted)),
                  ],
                  TextButton(onPressed: session == null ? null : _showPhotoSheet, child: Text(s.profileChangePhoto)),
                ],
              ),
            ),
            avatarBubble(r: 40),
          ],
        );
      case ProfileHeaderLayout.minimalInline:
        header = ListTile(
          contentPadding: EdgeInsets.zero,
          leading: avatarBubble(r: 28),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: palette.text)),
          subtitle: Text(session?.login ?? '—', style: TextStyle(color: palette.muted)),
          trailing: IconButton(
            onPressed: session == null ? null : _showPhotoSheet,
            icon: Icon(CupertinoIcons.camera, color: palette.accent),
          ),
        );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const SizedBox.shrink(),
        actions: const [AppBarTools()],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, shellClearance(context, extra: 20)),
          children: [
            header,
            if (session != null) ...[
              const SizedBox(height: 16),
              _LoyaltyCard(login: session.login),
              const SizedBox(height: 12),
              _ReferralPromoCard(login: session.login, displayName: session.displayName),
            ],
            const SizedBox(height: 22),
            _SectionLabel(s.profileAccount),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(CupertinoIcons.person, color: palette.accent),
                    title: Text(s.profileName),
                    subtitle: Text(session?.displayName ?? '—'),
                    trailing: const Icon(CupertinoIcons.pencil, size: 18),
                    onTap: session == null ? null : _changeName,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.lock, color: palette.accent),
                    title: Text(s.profileChangePassword),
                    subtitle: Text(s.profileSecurity),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: session == null ? null : _changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(s.profileGarage),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(CupertinoIcons.play_circle_fill, color: palette.accent),
                    title: Text(s.guideReplay),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => context.push('/home/guide'),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.car_detailed, color: palette.accent),
                    title: Text(s.tabCar),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state = ClientTabs.car,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.square_grid_2x2, color: palette.accent),
                    title: Text(s.profileFindShop),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state = ClientTabs.shops,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.square_list_fill, color: palette.accent),
                    title: Text(s.tabCategories),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state = ClientTabs.categories,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.calendar, color: palette.accent),
                    title: Text(s.tabBookings),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state = ClientTabs.bookings,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.briefcase, color: palette.accent),
                    title: Text(s.tabRequests),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state =
                        ClientTabs.requests,
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.building_2_fill, color: palette.accent),
                    title: Text(s.businessAccountTitle),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => context.push('/home/business'),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.book_fill, color: palette.accent),
                    title: Text(s.tabServiceBook),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () => ref.read(clientTabProvider.notifier).state = ClientTabs.serviceBook,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(s.profileSupport),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(CupertinoIcons.phone, color: palette.accent),
                    title: Text(s.profileCall),
                    subtitle: const Text('+48 22 111 22 33'),
                    trailing: IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                      onPressed: () => _copy('+48 22 111 22 33'),
                    ),
                    onTap: () => openLink('tel:$_supportPhone'),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.mail, color: palette.accent),
                    title: Text(s.profileEmail),
                    subtitle: const Text(_supportMail),
                    trailing: IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                      onPressed: () => _copy(_supportMail),
                    ),
                    onTap: () => openLink('mailto:$_supportMail?subject=Ta4ka'),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.clock, color: palette.accent),
                    title: Text(s.profileHours),
                    subtitle: Text(s.profileHoursValue),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.question_circle, color: palette.accent),
                    title: Text(s.profileHelp),
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            child: Text(s.profileHelpBody, style: const TextStyle(height: 1.45, fontSize: 16)),
                          );
                        },
                      );
                    },
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  ListTile(
                    leading: Icon(CupertinoIcons.paperplane_fill, color: palette.accent),
                    title: Text(
                      TelegramWebApp.instance.active ? s.telegramConnected : s.telegramOpen,
                    ),
                    subtitle: Text(
                      TelegramWebApp.instance.active
                          ? (TelegramWebApp.instance.user?.username != null
                              ? '@${TelegramWebApp.instance.user!.username}'
                              : s.telegramMiniAppBadge)
                          : s.telegramOpenLead,
                    ),
                    trailing: TelegramWebApp.instance.active
                        ? Icon(CupertinoIcons.checkmark_alt, size: 18, color: palette.accent)
                        : const Icon(CupertinoIcons.chevron_forward, size: 16),
                    onTap: TelegramWebApp.instance.active || !hasTelegramBot
                        ? null
                        : () => openTelegramMiniApp(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(s.profileLook),
            Card(
              child: Column(
                children: [
                  _ThemeRow(
                    selected: theme == AppVisualTheme.guy,
                    icon: CupertinoIcons.moon_fill,
                    label: s.themeGuy,
                    swatch: const Color(0xFF050506),
                    ring: const Color(0xFF4DA3FF),
                    onTap: () => ref.read(themeProvider.notifier).setTheme(AppVisualTheme.guy),
                  ),
                  Divider(height: 0.5, color: palette.stroke),
                  _ThemeRow(
                    selected: theme == AppVisualTheme.girl,
                    icon: CupertinoIcons.sun_max_fill,
                    label: s.themeGirl,
                    swatch: const Color(0xFFF7E6EB),
                    ring: const Color(0xFF9A3F58),
                    onTap: () => ref.read(themeProvider.notifier).setTheme(AppVisualTheme.girl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                context.go('/');
              },
              child: Text(s.logout),
            ),
            const SizedBox(height: 16),
            Text(
              s.profileVersion,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyCard extends ConsumerWidget {
  const _LoyaltyCard({required this.login});

  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final lang = ref.watch(localeProvider);
    final uk = lang == AppLang.uk;
    ref.watch(clientLoyaltyProvider);
    final loyalty = ref.read(clientLoyaltyProvider.notifier).of(login);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LVL ${loyalty.level}',
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loyalty.title(uk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                Text(
                  '${loyalty.cashbackPercent.toStringAsFixed(loyalty.cashbackPercent == loyalty.cashbackPercent.roundToDouble() ? 0 : 1)}%',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.loyaltyCashbackLead, style: TextStyle(color: palette.muted, fontSize: 13, height: 1.35)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: loyalty.progressToNext,
                minHeight: 8,
                backgroundColor: palette.carbon,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loyalty.level >= 10
                  ? s.loyaltyMaxLevel
                  : s.loyaltyXpProgress(loyalty.xpIntoLevel, loyalty.xpForNext),
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _ShareAppTile(login: login),
            const SizedBox(height: 14),
            Text(s.loyaltyHowTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final a in loyaltyActions.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        '+${a.xp}',
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        uk ? a.titleUk : a.titleEn,
                        style: TextStyle(color: palette.muted, fontSize: 13, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareAppTile extends ConsumerWidget {
  const _ShareAppTile({required this.login});

  final String login;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    return Material(
      color: palette.carbon,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final session = ref.read(authProvider);
          final account = ref.read(referralHubProvider.notifier).ensureAccount(
                login: login,
                displayName: session?.displayName ?? '',
              );
          Clipboard.setData(ClipboardData(text: s.loyaltyShareCopy(account.inviteCode)));
          ref.read(clientLoyaltyProvider.notifier).addXp(login, 40, kind: 'share');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.loyaltyShareDone)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(CupertinoIcons.share, color: palette.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.loyaltyShareCta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.loyaltyShareHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.loyaltyShareXp,
                  style: TextStyle(
                    color: palette.onAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralPromoCard extends ConsumerWidget {
  const _ReferralPromoCard({required this.login, required this.displayName});

  final String login;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    ref.watch(referralHubProvider);
    final account = ref.read(referralHubProvider.notifier).ensureAccount(
          login: login,
          displayName: displayName,
        );

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/referral'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.accent.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.accent.withValues(alpha: 0.14),
                palette.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(CupertinoIcons.gift_fill, color: palette.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.referralTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.referralProfileSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: palette.carbon,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: palette.stroke),
                            ),
                            child: Text(
                              account.inviteCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Text(
                            s.referralLevelsBadge,
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_forward, size: 16, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.selected,
    required this.icon,
    required this.label,
    required this.swatch,
    required this.ring,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color swatch;
  final Color ring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: selected ? ring : palette.muted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (selected) Icon(CupertinoIcons.checkmark, color: ring, size: 20),
          ],
        ),
      ),
    );
  }
}
