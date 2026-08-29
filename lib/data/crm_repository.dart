import '../app/theme.dart';
import '../core/l10n/app_lang.dart';
import '../domain/models/auth_session.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/platform_features.dart';
import '../domain/models/referral.dart';
import '../domain/models/client_loyalty.dart';
import '../domain/models/shop_account.dart';
import '../domain/models/tap_wallet.dart';
import 'crm_store.dart';

class CrmRepository {
  CrmRepository(this._store);

  final CrmStore _store;

  AppLang loadLang() => _store.loadLang();

  void saveLang(AppLang lang) => _store.saveLang(lang);

  AppVisualTheme loadTheme() => _store.loadTheme();

  void saveTheme(AppVisualTheme theme) => _store.saveTheme(theme);

  AuthSession? loadSession() => _store.loadSession();

  void saveSession(AuthSession? session) => _store.saveSession(session);

  ShopAccount? loadShopAccount() => _store.loadShopAccount();

  void saveShopAccount(ShopAccount? account) => _store.saveShopAccount(account);

  TapWalletState loadTapWallet() => _store.loadTapWallet();

  void saveTapWallet(TapWalletState wallet) => _store.saveTapWallet(wallet);

  int? rememberedPrice(String workId, PriceTier tier) =>
      _store.rememberedPrice(workId, tier);

  void rememberPrice(String workId, PriceTier tier, int priceUah) {
    _store.rememberPrice(workId, tier, priceUah);
  }

  List<WorkOrder> loadOrders() => _store.loadOrders();

  void upsertOrder(WorkOrder order) => _store.upsertOrder(order);

  void deleteOrder(String id) => _store.deleteOrder(id);

  List<Rating> loadRatings() => _store.loadRatings();

  void addRating(Rating rating) => _store.addRating(rating);

  List<BlacklistEntry> loadBlacklist() => _store.loadBlacklist();

  void saveBlacklist(List<BlacklistEntry> items) => _store.saveBlacklist(items);

  List<OpenJobRequest> loadOpenJobs() => _store.loadOpenJobs();

  void saveOpenJobs(List<OpenJobRequest> items) => _store.saveOpenJobs(items);

  List<VehicleAuction> loadAuctions() => _store.loadAuctions();

  void saveAuctions(List<VehicleAuction> items) => _store.saveAuctions(items);

  List<GarageCar> loadGarageCars(String ownerLogin) =>
      _store.loadGarageCars(ownerLogin);

  void saveGarageCars(String ownerLogin, List<GarageCar> cars) =>
      _store.saveGarageCars(ownerLogin, cars);

  List<BusinessInvoice> loadBusinessInvoices(String ownerLogin) =>
      _store.loadBusinessInvoices(ownerLogin);

  void saveBusinessInvoices(String ownerLogin, List<BusinessInvoice> items) =>
      _store.saveBusinessInvoices(ownerLogin, items);

  List<PartsRequest> loadPartsRequests() => _store.loadPartsRequests();

  void savePartsRequests(List<PartsRequest> items) =>
      _store.savePartsRequests(items);

  List<MapaHelpReport> loadMapaReports() => _store.loadMapaReports();

  void saveMapaReports(List<MapaHelpReport> items) =>
      _store.saveMapaReports(items);

  ReferralHub loadReferralHub() => _store.loadReferralHub();

  void saveReferralHub(ReferralHub hub) => _store.saveReferralHub(hub);

  Map<String, ClientLoyalty> loadClientLoyalty() => _store.loadClientLoyalty();

  void saveClientLoyalty(Map<String, ClientLoyalty> map) =>
      _store.saveClientLoyalty(map);
}
