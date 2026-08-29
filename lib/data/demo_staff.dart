import '../domain/models/crm_models.dart';
import '../domain/models/desk_master.dart';
import '../domain/models/shop_account.dart';

/// Built-in desk so admin / master / PC / Android all share the same logins.
abstract final class DemoStaff {
  static const shopLogin = 'admin';
  static const shopPassword = 'admin1234';
  static const shopName = 'Ta4ka Warsaw';

  static const masterLogin = 'master';
  static const masterPassword = 'master1234';
  static const masterName = 'Adam Nowak';

  static const receptionLogin = 'reception';
  static const receptionPassword = 'reception1234';
  static const receptionName = 'Anna Kowalska';

  static List<DeskMaster> get masters => [
        const DeskMaster(
          id: 'demo_master',
          name: masterName,
          specialty: MasterSpecialty.electrician,
          pace: MasterPace.fast,
          yearsExperience: 9,
          login: masterLogin,
          password: masterPassword,
        ),
        const DeskMaster(
          id: 'demo_reception',
          name: receptionName,
          specialty: MasterSpecialty.maintenance,
          pace: MasterPace.careful,
          yearsExperience: 6,
          login: receptionLogin,
          password: receptionPassword,
          kind: StaffKind.receptionist,
        ),
      ];

  static ShopAccount get shop => ShopAccount(
        login: shopLogin,
        shopName: shopName,
        city: 'Warsaw',
        address: 'ul. Marszałkowska 1',
        phone: '+48 22 000 00 00',
        sphereIds: const ['diag', 'chassis', 'engine', 'service'],
        about: 'Demo Ta4ka desk — admin / master / cameras.',
        staffCount: 2,
        cameraConnected: true,
        liveOn: true,
        catalogShopId: 'pitlane',
        deskMasters: masters,
      );

  static bool isShopAdmin(String login, String password) =>
      login.trim() == shopLogin && password == shopPassword;

  static DeskMaster? matchStaff(String login, String password) {
    final l = login.trim();
    for (final m in masters) {
      if (m.login == l && m.password == password) {
        return m;
      }
    }
    return null;
  }

  static ShopAccount hydrate(ShopAccount? stored) {
    if (stored == null || stored.login.isEmpty) {
      return shop;
    }
    final have = {for (final m in stored.deskMasters) m.login};
    final extra = [for (final m in masters) if (!have.contains(m.login)) m];
    if (extra.isEmpty) {
      return stored;
    }
    return stored.copyWith(deskMasters: [...extra, ...stored.deskMasters]);
  }
}
