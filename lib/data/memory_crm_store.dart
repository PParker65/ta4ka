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

class MemoryCrmStore implements CrmStore {
  AppLang _lang = AppLang.uk;
  AppVisualTheme _theme = AppVisualTheme.guy;
  AuthSession? _session;
  ShopAccount? _shopAccount;
  TapWalletState _wallet = const TapWalletState();
  ReferralHub _referrals = const ReferralHub();
  Map<String, ClientLoyalty> _loyalty = {};
  final Map<String, int> _prices = {};
  final Map<String, WorkOrder> _orders = {};
  final Map<String, Rating> _ratings = {};
  List<BlacklistEntry> _blacklist = [];
  List<OpenJobRequest> _openJobs = [];
  List<VehicleAuction> _auctions = [];
  final Map<String, List<GarageCar>> _garage = {};
  final Map<String, List<BusinessInvoice>> _invoices = {};
  List<PartsRequest> _partsRequests = [];
  List<MapaHelpReport> _mapaReports = [];

  @override
  Future<void> init() async {}

  @override
  AppLang loadLang() => _lang;

  @override
  void saveLang(AppLang lang) => _lang = lang;

  @override
  AppVisualTheme loadTheme() => _theme;

  @override
  void saveTheme(AppVisualTheme theme) => _theme = theme;

  @override
  AuthSession? loadSession() => _session;

  @override
  void saveSession(AuthSession? session) => _session = session;

  @override
  ShopAccount? loadShopAccount() => _shopAccount;

  @override
  void saveShopAccount(ShopAccount? account) => _shopAccount = account;

  @override
  TapWalletState loadTapWallet() => _wallet;

  @override
  void saveTapWallet(TapWalletState wallet) => _wallet = wallet;

  @override
  ReferralHub loadReferralHub() => _referrals;

  @override
  void saveReferralHub(ReferralHub hub) => _referrals = hub;

  @override
  Map<String, ClientLoyalty> loadClientLoyalty() => Map.unmodifiable(_loyalty);

  @override
  void saveClientLoyalty(Map<String, ClientLoyalty> map) {
    _loyalty = {...map};
  }

  @override
  int? rememberedPrice(String workId, PriceTier tier) =>
      _prices['$workId|${tier.name}'];

  @override
  void rememberPrice(String workId, PriceTier tier, int priceUah) {
    _prices['$workId|${tier.name}'] = priceUah;
  }

  @override
  List<WorkOrder> loadOrders() {
    final items = _orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  void upsertOrder(WorkOrder order) {
    _orders[order.id] = order;
  }

  @override
  void deleteOrder(String id) {
    _orders.remove(id);
  }

  @override
  List<Rating> loadRatings() {
    final items = _ratings.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  void addRating(Rating rating) {
    _ratings[rating.id] = rating;
  }

  @override
  List<BlacklistEntry> loadBlacklist() => List.unmodifiable(_blacklist);

  @override
  void saveBlacklist(List<BlacklistEntry> items) {
    _blacklist = [...items];
  }

  @override
  List<OpenJobRequest> loadOpenJobs() => List.unmodifiable(_openJobs);

  @override
  void saveOpenJobs(List<OpenJobRequest> items) {
    _openJobs = [...items];
  }

  @override
  List<VehicleAuction> loadAuctions() => List.unmodifiable(_auctions);

  @override
  void saveAuctions(List<VehicleAuction> items) {
    _auctions = [...items];
  }

  @override
  List<GarageCar> loadGarageCars(String ownerLogin) =>
      List.unmodifiable(_garage[ownerLogin] ?? const []);

  @override
  void saveGarageCars(String ownerLogin, List<GarageCar> cars) {
    _garage[ownerLogin] = [...cars];
  }

  @override
  List<BusinessInvoice> loadBusinessInvoices(String ownerLogin) =>
      List.unmodifiable(_invoices[ownerLogin] ?? const []);

  @override
  void saveBusinessInvoices(String ownerLogin, List<BusinessInvoice> items) {
    _invoices[ownerLogin] = [...items];
  }

  @override
  List<PartsRequest> loadPartsRequests() => List.unmodifiable(_partsRequests);

  @override
  void savePartsRequests(List<PartsRequest> items) {
    _partsRequests = [...items];
  }

  @override
  List<MapaHelpReport> loadMapaReports() => List.unmodifiable(_mapaReports);

  @override
  void saveMapaReports(List<MapaHelpReport> items) {
    _mapaReports = [...items];
  }
}

CrmStore createStore({bool memory = false}) => MemoryCrmStore();
