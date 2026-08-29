import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/auto_spheres.dart';
import '../../data/demo_staff.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/desk_master.dart';
import '../../domain/models/shop_account.dart';
import '../../domain/models/shop_brand.dart';
import '../widgets/shop_mark.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';
import '../workshop/shop_desk_seed.dart';

/// First step: manager or master.
class ShopRoleGateScreen extends ConsumerWidget {
  const ShopRoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.forAutoservices),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                HeroPanel(
                  icon: CupertinoIcons.person_2_fill,
                  title: s.shopRolePickTitle,
                  subtitle: s.shopMastersRegisterLead,
                ),
                const SizedBox(height: 16),
                const _DemoAccountsCard(),
                const SizedBox(height: 24),
                _RoleCard(
                  icon: CupertinoIcons.building_2_fill,
                  title: s.shopRoleOwner,
                  onTap: () => context.push('/auth/shop/manager'),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: CupertinoIcons.person_crop_rectangle,
                  title: s.shopRoleReception,
                  onTap: () => context.push('/auth/shop/master?kind=reception'),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: CupertinoIcons.wrench_fill,
                  title: s.shopRoleMaster,
                  onTap: () => context.push('/auth/shop/master'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(CupertinoIcons.chevron_forward),
        onTap: onTap,
      ),
    );
  }
}

class ShopAuthScreen extends ConsumerStatefulWidget {
  const ShopAuthScreen({super.key, this.asMaster = false, this.asReception = false});

  final bool asMaster;
  final bool asReception;

  @override
  ConsumerState<ShopAuthScreen> createState() => _ShopAuthScreenState();
}

class _ShopAuthScreenState extends ConsumerState<ShopAuthScreen> {
  final _shop = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController(text: 'Warsaw');
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _word = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  final _spheres = <String>{'diag', 'chassis', 'engine', 'service'};
  int _logoVariant = 0;

  @override
  void dispose() {
    _shop.dispose();
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _login.dispose();
    _password.dispose();
    _word.dispose();
    super.dispose();
  }

  void _enterMaster() {
    final s = ref.read(stringsProvider);
    final login = _login.text.trim();
    final pass = _password.text;
    if (login.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.loginError)));
      return;
    }
    final masters = [
      ...ref.read(shopAccountProvider).deskMasters,
      ...DemoStaff.masters,
    ];
    DeskMaster? hit;
    for (final m in masters) {
      if (m.login.trim() == login && m.password == pass) {
        hit = m;
        break;
      }
    }
    hit ??= DemoStaff.matchStaff(login, pass);
    if (hit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.shopRoleMasterHint)),
      );
      return;
    }
    final wantReception = widget.asReception || hit.isReceptionist;
    if (wantReception && !hit.isReceptionist) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.shopRoleReception)),
      );
      return;
    }
    if (!wantReception && hit.isReceptionist) {
      // Receptionist account opened via master button → still go to staff.
    }
    if (hit.isReceptionist) {
      ref.read(authProvider.notifier).signIn(
            AuthSession(
              displayName: hit.name.trim().isEmpty ? login : hit.name.trim(),
              login: login,
              role: 'receptionist',
              password: pass,
            ),
          );
      context.go('/staff');
      return;
    }
    ref.read(authProvider.notifier).signIn(
          AuthSession(
            displayName: hit.name.trim().isEmpty ? login : hit.name.trim(),
            login: login,
            role: 'master',
            password: pass,
          ),
        );
    context.go('/master');
  }

  Future<void> _enterManager() async {
    final s = ref.read(stringsProvider);
    final login = _login.text.trim();
    if (login.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.loginError)));
      return;
    }
    if (_register) {
      if (_password.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.passwordShort)));
        return;
      }
      if (_shop.text.trim().isEmpty ||
          _address.text.trim().isEmpty ||
          _phone.text.trim().isEmpty ||
          _spheres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.shopNeedData)));
        return;
      }
    }
    final demoAdmin = DemoStaff.isShopAdmin(login, _password.text);
    if (!_register && !demoAdmin) {
      final saved = ref.read(shopAccountProvider);
      if (saved.login.isNotEmpty && saved.login != login) {
        // still allow local prototype login
      }
    }
    final previous = ref.read(shopAccountProvider);
    final name = _name.text.trim().isEmpty ? login : _name.text.trim();
    final shopName = _shop.text.trim().isEmpty
        ? (previous.shopName.isNotEmpty ? previous.shopName : (demoAdmin ? DemoStaff.shopName : name))
        : _shop.text.trim();
    final masterLogin = '${login}_m1';
    const masterPass = DemoStaff.masterPassword;
    var deskMasters = DemoStaff.hydrate(previous).deskMasters;
    if (_register) {
      deskMasters = [
        DeskMaster(
          id: 'auto_m1',
          name: name,
          login: masterLogin,
          password: masterPass,
          yearsExperience: 6,
        ),
        ...deskMasters.where((m) => m.login != masterLogin),
      ];
    }
    ref.read(authProvider.notifier).signIn(
          AuthSession(
            displayName: name,
            login: login,
            role: 'shop_admin',
            password: _password.text,
          ),
        );
    ref.read(shopAccountProvider.notifier).save(
          ShopAccount(
            login: login,
            shopName: shopName,
            city: _city.text.trim().isEmpty ? previous.city : _city.text.trim(),
            address:
                _address.text.trim().isEmpty ? previous.address : _address.text.trim(),
            phone: _phone.text.trim().isEmpty ? previous.phone : _phone.text.trim(),
            sphereIds: _register
                ? _spheres.toList()
                : (previous.sphereIds.isEmpty ? _spheres.toList() : previous.sphereIds),
            offeredWorkIds: previous.offeredWorkIds,
            customServices: previous.customServices,
            about: previous.about,
            staffCount: previous.staffCount,
            positioning: previous.positioning,
            priceGrade: previous.priceGrade,
            dailyLoadPercent: previous.dailyLoadPercent,
            partsDelivery: previous.partsDelivery,
            cameraConnected: demoAdmin ? true : previous.cameraConnected,
            liveOn: demoAdmin ? true : previous.liveOn,
            commissionDebtUah: previous.commissionDebtUah,
            lastSettledAt: previous.lastSettledAt,
            paymentRequisites: previous.paymentRequisites,
            forceUnblocked: previous.forceUnblocked,
            hoursText: previous.hoursText,
            openHour: previous.openHour,
            closeHour: previous.closeHour,
            catalogShopId: previous.catalogShopId,
            deskMasters: deskMasters,
            mapaHelpOptIn: previous.mapaHelpOptIn,
            mapaHelpPaused: previous.mapaHelpPaused,
            logoVariant: _register ? _logoVariant : previous.logoVariant,
            titleFont: previous.titleFont,
            logoWord: _register ? _word.text.trim() : previous.logoWord,
          ),
        );
    seedDeskBookingsIfEmpty(
      ref.read(ordersProvider.notifier),
      ref.read(ordersProvider),
    );
    if (_register && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.shopCreate),
          content: Text(s.shopMasterIssued(masterLogin, masterPass)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.shopSignIn),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    context.go('/staff');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final asMaster = widget.asMaster;
    final asReception = widget.asReception;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asReception
              ? s.shopRoleReception
              : (asMaster ? s.shopRoleMaster : s.shopLoginTitle),
        ),
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                HeroPanel(
                  icon: asReception
                      ? CupertinoIcons.person_crop_rectangle
                      : (asMaster
                          ? CupertinoIcons.wrench_fill
                          : CupertinoIcons.building_2_fill),
                  title: asReception
                      ? s.shopRoleReception
                      : (asMaster ? s.shopRoleMaster : s.shopLoginTitle),
                  subtitle: asMaster || asReception
                      ? s.shopRoleMasterHint
                      : s.shopDeskLead,
                ),
                const SizedBox(height: 20),
                if (!asMaster && !asReception)
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(s.signIn)),
                      ButtonSegment(value: true, label: Text(s.register)),
                    ],
                    selected: {_register},
                    onSelectionChanged: (value) =>
                        setState(() => _register = value.first),
                  ),
                if (!asMaster && !asReception) const SizedBox(height: 16),
                _DemoAccountsCard(
                  onFillAdmin: asMaster || asReception
                      ? null
                      : () {
                          _login.text = DemoStaff.shopLogin;
                          _password.text = DemoStaff.shopPassword;
                          setState(() {});
                        },
                  onFillMaster: asMaster || asReception
                      ? () {
                          _login.text = widget.asReception
                              ? DemoStaff.receptionLogin
                              : DemoStaff.masterLogin;
                          _password.text = widget.asReception
                              ? DemoStaff.receptionPassword
                              : DemoStaff.masterPassword;
                          setState(() {});
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!asMaster && !asReception && _register) ...[
                          TextField(
                            controller: _shop,
                            decoration: InputDecoration(labelText: s.shopName),
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _name,
                            decoration: InputDecoration(labelText: s.displayName),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _city,
                            decoration: InputDecoration(labelText: s.shopCity),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _address,
                            decoration: InputDecoration(labelText: s.shopAddress),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(labelText: s.shopPhone),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          Text(s.shopServices, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(s.shopServicesHint, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sphere in autoSpheres.take(16))
                                FilterChip(
                                  label: Text(sphere.title.of(lang)),
                                  selected: _spheres.contains(sphere.id),
                                  onSelected: (on) {
                                    setState(() {
                                      if (on) {
                                        _spheres.add(sphere.id);
                                      } else {
                                        _spheres.remove(sphere.id);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(s.shopLogoPick, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ColoredBox(
                            color: ShopBrand.canvas,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                              child: Column(
                                children: [
                                  ShopMarkLive(
                                    brand: ShopBrand.resolve(
                                      name: _shop.text,
                                      seed: _shop.text.isEmpty ? 'sto' : _shop.text,
                                      sphereIds: _spheres.toList(),
                                      variant: _logoVariant,
                                      word: _word.text,
                                    ),
                                    size: 132,
                                    play: ShopMarkPlay.loop,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _shop.text.trim().isEmpty ? 'СТО' : _shop.text.trim(),
                                    textAlign: TextAlign.center,
                                    style: shopTitleStyle(
                                      ShopBrand.resolve(
                                        name: _shop.text,
                                        seed: _shop.text.isEmpty ? 'sto' : _shop.text,
                                        sphereIds: _spheres.toList(),
                                        variant: _logoVariant,
                                        word: _word.text,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _word,
                            maxLength: 4,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: s.shopLogoWord,
                              counterText: '',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          ShopLogoPicker(
                            selected: _logoVariant,
                            brandAt: (i) => ShopBrand.resolve(
                              name: _shop.text,
                              seed: _shop.text.isEmpty ? 'sto' : _shop.text,
                              sphereIds: _spheres.toList(),
                              variant: i,
                              word: _word.text,
                            ),
                            onSelect: (i) => setState(() => _logoVariant = i),
                            labels: [
                              s.shopLogoCrest,
                              s.shopLogoSeal,
                              s.shopLogoLetter,
                              s.shopLogoSign,
                              s.shopLogoPulse,
                              s.shopLogoHex,
                              s.shopLogoDiamond,
                              s.shopLogoWing,
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _login,
                          decoration: InputDecoration(
                            labelText: s.login,
                            prefixIcon: const Icon(CupertinoIcons.person),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          onSubmitted: (_) =>
                              asMaster || asReception ? _enterMaster() : _enterManager(),
                          decoration: InputDecoration(
                            labelText: s.password,
                            prefixIcon: const Icon(CupertinoIcons.lock),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: asMaster || asReception
                                ? _enterMaster
                                : _enterManager,
                            child: Text(
                              asMaster || asReception
                                  ? s.signIn
                                  : (_register ? s.shopCreate : s.shopSignIn),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountsCard extends ConsumerWidget {
  const _DemoAccountsCard({this.onFillAdmin, this.onFillMaster});

  final VoidCallback? onFillAdmin;
  final VoidCallback? onFillMaster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.demoAccountsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(s.demoAdminHint, style: TextStyle(color: palette.muted, height: 1.35)),
            Text(s.demoMasterHint, style: TextStyle(color: palette.muted, height: 1.35)),
            if (onFillAdmin != null || onFillMaster != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (onFillAdmin != null)
                    TextButton(onPressed: onFillAdmin, child: Text(s.demoFill)),
                  if (onFillMaster != null)
                    TextButton(onPressed: onFillMaster, child: Text(s.demoFill)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

