import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/desk_master.dart';
import '../client/booking_format.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/ui.dart';

/// Shop bottom-nav: register bay masters and issue login/password.
class ShopMastersRegisterScreen extends ConsumerStatefulWidget {
  const ShopMastersRegisterScreen({super.key});

  @override
  ConsumerState<ShopMastersRegisterScreen> createState() =>
      _ShopMastersRegisterScreenState();
}

class _ShopMastersRegisterScreenState
    extends ConsumerState<ShopMastersRegisterScreen> {
  final _name = TextEditingController();
  MasterSpecialty _specialty = MasterSpecialty.maintenance;
  StaffKind _kind = StaffKind.mechanic;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _persist(List<DeskMaster> masters) {
    final account = ref.read(shopAccountProvider);
    ref.read(shopAccountProvider.notifier).save(
          account.copyWith(
            deskMasters: masters,
            staffCount: masters.isEmpty ? account.staffCount : masters.length,
          ),
        );
  }

  void _registerMaster() {
    final s = ref.read(stringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.shopMasterName)),
      );
      return;
    }
    final account = ref.read(shopAccountProvider);
    final id = 'm_${DateTime.now().millisecondsSinceEpoch}';
    final login = issueMasterLogin(
      account.login.isEmpty ? 'sto' : account.login,
      id,
    );
    final password = issueMasterPassword();
    final master = DeskMaster(
      id: id,
      name: name,
      specialty: _specialty,
      login: login,
      password: password,
      kind: _kind,
    );
    _persist([master, ...account.deskMasters]);
    _name.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.masterIssueLogin}: $login / $password')),
    );
  }

  void _reissue(DeskMaster master) {
    final account = ref.read(shopAccountProvider);
    final next = master.copyWith(
      login: issueMasterLogin(
        account.login.isEmpty ? 'sto' : account.login,
        master.id,
      ),
      password: issueMasterPassword(),
    );
    _persist([
      for (final m in account.deskMasters) m.id == master.id ? next : m,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final palette = paletteOf(context);
    final masters = ref.watch(shopAccountProvider).deskMasters;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shopTabMasters),
        automaticallyImplyLeading: false,
        actions: const [AppBarTools(showWallet: false, showProfile: false)],
      ),
      body: ScreenCanvas(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(
              s.shopMastersRegisterLead,
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.shopMastersRegisterTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(labelText: s.shopMasterName),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<StaffKind>(
                      segments: [
                        ButtonSegment(
                          value: StaffKind.mechanic,
                          label: Text(s.staffKindMechanic),
                        ),
                        ButtonSegment(
                          value: StaffKind.receptionist,
                          label: Text(s.staffKindReception),
                        ),
                      ],
                      selected: {_kind},
                      onSelectionChanged: (v) => setState(() => _kind = v.first),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<MasterSpecialty>(
                      initialValue: _specialty,
                      decoration: InputDecoration(labelText: s.status),
                      items: [
                        for (final spec in MasterSpecialty.values)
                          DropdownMenuItem(
                            value: spec,
                            child: Text(specialtyLabel(s, spec)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _specialty = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _registerMaster,
                      icon: const Icon(CupertinoIcons.person_badge_plus),
                      label: Text(s.shopMastersRegisterCta),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.shopMastersListTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (masters.isEmpty)
              Text('—', style: TextStyle(color: palette.muted))
            else
              for (final m in masters)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name.isEmpty ? 'Master' : m.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${m.isReceptionist ? s.staffKindReception : s.staffKindMechanic} · ${specialtyLabel(s, m.specialty)}',
                          style: TextStyle(color: palette.muted),
                        ),
                        if (m.hasCredentials) ...[
                          const SizedBox(height: 8),
                          SelectableText(
                            '${s.login}: ${m.login}\n${s.password}: ${m.password}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: '${m.login}\n${m.password}',
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.copied)),
                                  );
                                },
                                icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
                                label: Text(s.copy),
                              ),
                              TextButton(
                                onPressed: () => _reissue(m),
                                child: Text(s.masterIssueLogin),
                              ),
                            ],
                          ),
                        ] else
                          TextButton(
                            onPressed: () => _reissue(m),
                            child: Text(s.masterIssueLogin),
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
