import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_lang.dart';
import '../core/l10n/app_strings.dart';
import '../core/network/api_client.dart';
import '../core/network/network_status.dart';
import '../data/crm_repository.dart';
import '../data/crm_store.dart';
import '../data/demo_staff.dart';
import '../data/ai_triage_api.dart';
import '../data/jobs_api.dart';
import '../data/auto_spheres.dart';
import '../data/shop_seed.dart';
import '../domain/models/auth_session.dart';
import '../domain/models/crm_models.dart';
import '../domain/models/desk_master.dart';
import '../domain/models/client_loyalty.dart';
import '../domain/models/platform_features.dart';
import '../domain/models/referral.dart';
import '../domain/models/shop_account.dart';
import '../domain/models/shop_models.dart';
import '../domain/models/tap_wallet.dart';
import '../domain/shop_commission.dart';
import 'design_skin.dart';
import 'theme.dart';

final designSkinProvider = StateProvider<DesignSkin>((ref) {
  // Mobile APK ships classic Fluent chrome; skins stay web/compare-only.
  if (!kIsWeb) {
    return DesignSkin.fluent;
  }
  final fromUrl = Uri.base.queryParameters['skin'];
  return DesignSkinX.fromCode(fromUrl);
});

final storeProvider = Provider<CrmStore>((ref) {
  throw UnimplementedError('storeProvider must be overridden');
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Mobile: true when Wi‑Fi or mobile data can reach the GLB CDN.
final glbOnlineProvider = StreamProvider<bool>((ref) {
  return watchInternetForGlbModels();
});

final repositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository(ref.watch(storeProvider));
});

final localeProvider =
    StateNotifierProvider<LocaleController, AppLang>((ref) {
  final repo = ref.watch(repositoryProvider);
  return LocaleController(repo);
});

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(localeProvider));
});

final themeProvider =
    StateNotifierProvider<ThemeController, AppVisualTheme>((ref) {
  final repo = ref.watch(repositoryProvider);
  return ThemeController(repo);
});

class ThemeController extends StateNotifier<AppVisualTheme> {
  ThemeController(this._repo) : super(_repo.loadTheme());

  final CrmRepository _repo;

  void setTheme(AppVisualTheme theme) {
    state = theme;
    _repo.saveTheme(theme);
  }

  void toggle() {
    setTheme(
      state == AppVisualTheme.guy ? AppVisualTheme.girl : AppVisualTheme.guy,
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthController, AuthSession?>((ref) {
  final repo = ref.watch(repositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AuthSession?> {
  AuthController(this._repo) : super(_repo.loadSession());

  final CrmRepository _repo;

  void signIn(AuthSession session) {
    _repo.saveSession(session);
    state = session;
  }

  void updateSession(AuthSession session) => signIn(session);

  bool changePassword({required String current, required String next}) {
    final session = state;
    if (session == null) {
      return false;
    }
    if (session.password.isNotEmpty && session.password != current) {
      return false;
    }
    if (next.length < 8) {
      return false;
    }
    signIn(session.copyWith(password: next));
    return true;
  }

  void signOut() {
    _repo.saveSession(null);
    state = null;
  }
}

final shopAccountProvider =
    StateNotifierProvider<ShopAccountController, ShopAccount>((ref) {
  return ShopAccountController(ref.watch(repositoryProvider));
});

class ShopAccountController extends StateNotifier<ShopAccount> {
  ShopAccountController(this._repo)
      : super(DemoStaff.hydrate(_repo.loadShopAccount())) {
    final stored = _repo.loadShopAccount();
    if (stored == null || stored.login.isEmpty || stored.deskMasters.isEmpty) {
      _repo.saveShopAccount(state);
    }
  }

  final CrmRepository _repo;

  void save(ShopAccount account) {
    _repo.saveShopAccount(account);
    state = account;
  }

  void patch({
    String? login,
    String? shopName,
    String? city,
    String? address,
    String? phone,
    List<String>? sphereIds,
    List<String>? offeredWorkIds,
    List<String>? customServices,
    String? about,
    int? staffCount,
    String? positioning,
    String? priceGrade,
    int? dailyLoadPercent,
    bool? partsDelivery,
    bool? cameraConnected,
    bool? liveOn,
    int? commissionDebtUah,
    DateTime? lastSettledAt,
    bool clearSettled = false,
    String? paymentRequisites,
    bool? forceUnblocked,
    String? hoursText,
    int? openHour,
    int? closeHour,
    String? catalogShopId,
    List<DeskMaster>? deskMasters,
    int? logoVariant,
    int? titleFont,
    String? logoWord,
  }) {
    save(
      state.copyWith(
        login: login,
        shopName: shopName,
        city: city,
        address: address,
        phone: phone,
        sphereIds: sphereIds,
        offeredWorkIds: offeredWorkIds,
        customServices: customServices,
        about: about,
        staffCount: staffCount,
        positioning: positioning,
        priceGrade: priceGrade,
        dailyLoadPercent: dailyLoadPercent,
        partsDelivery: partsDelivery,
        cameraConnected: cameraConnected,
        liveOn: liveOn,
        commissionDebtUah: commissionDebtUah,
        lastSettledAt: lastSettledAt,
        clearSettled: clearSettled,
        paymentRequisites: paymentRequisites,
        forceUnblocked: forceUnblocked,
        hoursText: hoursText,
        openHour: openHour,
        closeHour: closeHour,
        catalogShopId: catalogShopId,
        deskMasters: deskMasters,
        logoVariant: logoVariant,
        titleFont: titleFont,
        logoWord: logoWord,
      ),
    );
  }

  /// Accrue 5% platform fee after a completed booking.
  void accrueCommission(int totalUah) {
    final fee = ShopCommission.feeFromTotalUah(totalUah);
    if (fee <= 0) {
      return;
    }
    save(
      state.copyWith(
        commissionDebtUah: state.commissionDebtUah + fee,
        forceUnblocked: false,
      ),
    );
  }

  /// Mark monthly settlement paid (clears debt, unblocks).
  void markCommissionPaid() {
    save(
      state.copyWith(
        commissionDebtUah: 0,
        lastSettledAt: DateTime.now(),
        forceUnblocked: false,
      ),
    );
  }
}

class ShopTabs {
  static const today = 0;
  static const bookings = 1;
  static const chat = 2;
  static const ops = 3;
  static const requests = 4;
  static const masters = 5;
  static const desk = 6;
}

final shopTabProvider = StateProvider<int>((ref) => ShopTabs.today);

/// 1 = new section from the right (iOS push), -1 = from the left. 0 = by tab order.
final sectionSlideDirProvider = StateProvider<int>((ref) => 0);

final tapWalletProvider =
    StateNotifierProvider<TapWalletController, TapWalletState>((ref) {
  return TapWalletController(ref.watch(repositoryProvider));
});

class TapWalletController extends StateNotifier<TapWalletState> {
  TapWalletController(this._repo) : super(_repo.loadTapWallet());

  final CrmRepository _repo;

  void smash() {
    state = state.smash();
    _persist();
  }

  int clearSphere(String sphereId, int need) {
    final result = state.clearSphere(sphereId, need);
    state = result.wallet;
    _persist();
    return result.paidCents;
  }

  int payUah(int uah) {
    final result = state.spendUah(uah);
    if (result.appliedUah <= 0) {
      return 0;
    }
    state = result.wallet;
    _persist();
    return result.appliedUah;
  }

  void _persist() {
    _repo.saveTapWallet(state);
  }
}

final jobsApiProvider = Provider<JobsApi>((ref) {
  return createJobsApi(ref.watch(apiClientProvider));
});

final aiTriageApiProvider = Provider<AiTriageApi>((ref) {
  return createAiTriageApi(ref.watch(apiClientProvider));
});

class ClientTabs {
  static const feed = 0;
  static const shops = 1;
  static const car = 2;
  static const categories = 3;
  static const help = 4;
  static const bookings = 5;
  static const requests = 6;
  static const auction = 7;
  static const serviceBook = 8;
  static const profile = 9;
  static const usa = 10;
}

final clientTabProvider = StateProvider<int>((ref) => ClientTabs.car);

/// Bump on every Стрічка open / re-tap so the feed reshuffles by city.
final feedShuffleTickProvider = StateProvider<int>((ref) => 0);

/// Last city the client used in catalog / geo (feed ranks clips by this).
final clientCityIdProvider = StateProvider<String>((ref) => 'warsaw');

/// True while the Auto tab is showing the 3D car (not the brand-icon grid).
final carBrandPickedProvider = StateProvider<bool>((ref) => false);

/// Bump from shell / Telegram back to return to the brand-icon grid.
final carBrandClearTickProvider = StateProvider<int>((ref) => 0);

extension SelectClientTab on WidgetRef {
  void selectClientTab(int tab) {
    if (tab == ClientTabs.feed) {
      read(feedShuffleTickProvider.notifier).state++;
    }
    if (tab == ClientTabs.bookings) {
      read(bookingsPulseProvider.notifier).state = false;
    }
    read(clientTabProvider.notifier).state = tab;
  }
}

/// After a booking, the calendar tab pulses until the client opens it.
final bookingsPulseProvider = StateProvider<bool>((ref) => false);

/// Bump to wipe the car-tab search field (shell keeps that screen mounted).
final carSearchClearTickProvider = StateProvider<int>((ref) => 0);

final takenSlotsProvider = StateProvider<Set<String>>((ref) => {});

class BookingDraft {
  const BookingDraft({
    this.shopId,
    this.sphereId,
    this.workIds = const {},
    this.date,
    this.masterId = '',
    this.slot,
    this.plate = '',
    this.brand = '',
    this.model = '',
    this.year = '',
    this.feedShopId,
    this.partsFromShop,
  });

  final String? shopId;
  final String? sphereId;
  final Set<String> workIds;
  final DateTime? date;
  final String masterId;
  final ShopTimeSlot? slot;
  final String plate;
  final String brand;
  final String model;
  final String year;
  final String? feedShopId;
  /// null = not chosen; true = shop supplies; false = client brings own.
  final bool? partsFromShop;

  BookingDraft copyWith({
    String? shopId,
    String? sphereId,
    bool clearSphere = false,
    Set<String>? workIds,
    DateTime? date,
    String? masterId,
    ShopTimeSlot? slot,
    bool clearSlot = false,
    String? plate,
    String? brand,
    String? model,
    String? year,
    String? feedShopId,
    bool clearFeedShop = false,
    bool? partsFromShop,
    bool clearParts = false,
  }) {
    return BookingDraft(
      shopId: shopId ?? this.shopId,
      sphereId: clearSphere ? null : (sphereId ?? this.sphereId),
      workIds: workIds ?? this.workIds,
      date: date ?? this.date,
      masterId: masterId ?? this.masterId,
      slot: clearSlot ? null : (slot ?? this.slot),
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      feedShopId: clearFeedShop ? null : (feedShopId ?? this.feedShopId),
      partsFromShop: clearParts ? null : (partsFromShop ?? this.partsFromShop),
    );
  }
}

final sceneSphereIdProvider = StateProvider<String?>((ref) => null);

final bookingProvider =
    StateNotifierProvider<BookingController, BookingDraft>((ref) {
  return BookingController();
});

class BookingController extends StateNotifier<BookingDraft> {
  BookingController() : super(const BookingDraft());

  void openShop(String shopId, {bool fullMenu = true}) {
    final offered = shopById(shopId)?.workIds.toSet() ?? {};
    final sphereWorks = fullMenu
        ? null
        : sphereById(state.sphereId ?? '')?.workIds.toSet();
    final allowed = sphereWorks == null || sphereWorks.isEmpty
        ? offered
        : offered.intersection(sphereWorks);
    final keep = state.workIds.where(allowed.contains).toSet();
    if (state.shopId == shopId && !fullMenu) {
      if (keep.length != state.workIds.length) {
        state = state.copyWith(workIds: keep);
      }
      return;
    }
    state = BookingDraft(
      shopId: shopId,
      sphereId: fullMenu ? null : state.sphereId,
      workIds: keep,
      plate: state.plate,
      brand: state.brand,
      model: state.model,
      year: state.year,
    );
  }

  void setPartsFromShop(bool value) {
    state = state.copyWith(partsFromShop: value);
  }

  void toggleWork(String workId) {
    final next = Set<String>.from(state.workIds);
    if (!next.add(workId)) {
      next.remove(workId);
    }
    state = state.copyWith(workIds: next);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, clearSlot: true);
  }

  void setMaster(String masterId) {
    state = state.copyWith(masterId: masterId, clearSlot: true);
  }

  void setSlot(ShopTimeSlot slot) {
    state = state.copyWith(slot: slot, date: DateTime(slot.start.year, slot.start.month, slot.start.day));
  }

  void setCar({
    String? plate,
    String? brand,
    String? model,
    String? year,
  }) {
    state = state.copyWith(plate: plate, brand: brand, model: model, year: year);
  }

  void pickSphere(String sphereId) {
    state = BookingDraft(
      sphereId: sphereId,
      plate: state.plate,
      brand: state.brand,
      model: state.model,
      year: state.year,
      feedShopId: state.feedShopId,
    );
  }

  void setSuggestedWorks(Set<String> workIds) {
    state = state.copyWith(workIds: workIds, clearSlot: true);
  }

  void watchShop(String shopId) {
    state = state.copyWith(feedShopId: shopId);
  }

  void clearFeedFilter() {
    state = state.copyWith(clearFeedShop: true);
  }

  void resetBooking() {
    state = BookingDraft(
      sphereId: state.sphereId,
      plate: state.plate,
      brand: state.brand,
      model: state.model,
      year: state.year,
    );
  }
}

class LocaleController extends StateNotifier<AppLang> {
  LocaleController(this._repo) : super(_repo.loadLang());

  final CrmRepository _repo;

  void setLang(AppLang lang) {
    state = lang;
    _repo.saveLang(lang);
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersController, List<WorkOrder>>((ref) {
  return OrdersController(ref.watch(repositoryProvider));
});

class OrdersController extends StateNotifier<List<WorkOrder>> {
  OrdersController(this._repo) : super(_repo.loadOrders());

  final CrmRepository _repo;

  void save(WorkOrder order) {
    _repo.upsertOrder(order);
    state = _repo.loadOrders();
  }

  void remove(String id) {
    _repo.deleteOrder(id);
    state = _repo.loadOrders();
  }

  WorkOrder? byId(String id) {
    for (final order in state) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  void addChat(String orderId, ServiceChatMessage message, {List<ServiceChatMessage>? seed}) {
    final order = byId(orderId);
    if (order == null) {
      return;
    }
    final base = order.chat.isNotEmpty ? order.chat : (seed ?? const []);
    save(order.copyWith(chat: [...base, message]));
  }
}

final ratingsProvider =
    StateNotifierProvider<RatingsController, List<Rating>>((ref) {
  return RatingsController(ref.watch(repositoryProvider));
});

class RatingsController extends StateNotifier<List<Rating>> {
  RatingsController(this._repo) : super(_repo.loadRatings());

  final CrmRepository _repo;

  void add(Rating rating) {
    _repo.addRating(rating);
    state = _repo.loadRatings();
  }
}

final blacklistProvider =
    StateNotifierProvider<BlacklistController, List<BlacklistEntry>>((ref) {
  return BlacklistController(ref.watch(repositoryProvider));
});

class BlacklistController extends StateNotifier<List<BlacklistEntry>> {
  BlacklistController(this._repo) : super(_repo.loadBlacklist());

  final CrmRepository _repo;

  void add(BlacklistEntry entry) {
    _repo.saveBlacklist([entry, ...state]);
    state = _repo.loadBlacklist();
  }

  void remove(String id) {
    _repo.saveBlacklist([for (final e in state) if (e.id != id) e]);
    state = _repo.loadBlacklist();
  }

  List<BlacklistEntry> forClient(String rawKey) {
    final key = normalizeClientKey(rawKey);
    if (key.isEmpty) {
      return const [];
    }
    return [for (final e in state) if (e.clientKey == key) e];
  }
}

final openJobsProvider =
    StateNotifierProvider<OpenJobsController, List<OpenJobRequest>>((ref) {
  return OpenJobsController(ref.watch(repositoryProvider));
});

class OpenJobsController extends StateNotifier<List<OpenJobRequest>> {
  OpenJobsController(this._repo) : super(_repo.loadOpenJobs());

  final CrmRepository _repo;

  void upsert(OpenJobRequest job) {
    final next = [
      job,
      for (final item in state)
        if (item.id != job.id) item,
    ];
    _repo.saveOpenJobs(next);
    state = _repo.loadOpenJobs();
  }

  void addBid(String jobId, OpenJobBid bid) {
    OpenJobRequest? target;
    for (final item in state) {
      if (item.id == jobId) {
        target = item;
        break;
      }
    }
    if (target == null || target.status != OpenJobStatus.open) {
      return;
    }
    final bids = [
      bid,
      for (final b in target.bids)
        if (b.shopId != bid.shopId) b,
    ];
    upsert(target.copyWith(bids: bids));
  }

  void award(String jobId, String bidId, String orderId) {
    OpenJobRequest? target;
    for (final item in state) {
      if (item.id == jobId) {
        target = item;
        break;
      }
    }
    if (target == null) {
      return;
    }
    OpenJobBid? bid;
    for (final b in target.bids) {
      if (b.id == bidId) {
        bid = b;
        break;
      }
    }
    if (bid == null) {
      return;
    }
    upsert(
      target.copyWith(
        status: OpenJobStatus.awarded,
        awardedBidId: bid.id,
        awardedShopId: bid.shopId,
        orderId: orderId,
      ),
    );
  }

  /// When linked order is finished → request leaves active list (journal via bookings).
  void syncWithOrders(List<WorkOrder> orders) {
    var changed = false;
    final next = <OpenJobRequest>[];
    for (final job in state) {
      if (job.status == OpenJobStatus.awarded &&
          job.orderId != null &&
          job.orderId!.isNotEmpty) {
        WorkOrder? order;
        for (final o in orders) {
          if (o.id == job.orderId) {
            order = o;
            break;
          }
        }
        if (order != null && order.status == JobStatus.ready) {
          next.add(job.copyWith(status: OpenJobStatus.closed));
          changed = true;
          continue;
        }
      }
      next.add(job);
    }
    if (changed) {
      _repo.saveOpenJobs(next);
      state = _repo.loadOpenJobs();
    }
  }
}

final auctionsProvider =
    StateNotifierProvider<AuctionsController, List<VehicleAuction>>((ref) {
  return AuctionsController(ref.watch(repositoryProvider));
});

class AuctionDraft {
  const AuctionDraft({
    this.orderId = '',
    this.plate = '',
    this.vin = '',
    this.brand = '',
    this.model = '',
    this.estimateUah = 0,
    this.shopId = '',
  });

  final String orderId;
  final String plate;
  final String vin;
  final String brand;
  final String model;
  final int estimateUah;
  final String shopId;
}

final auctionDraftProvider = StateProvider<AuctionDraft?>((ref) => null);

class AuctionsController extends StateNotifier<List<VehicleAuction>> {
  AuctionsController(this._repo) : super(_repo.loadAuctions()) {
    _seedBotsIfEmpty();
    _expireIfNeeded();
  }

  final CrmRepository _repo;

  void _persist(List<VehicleAuction> next) {
    _repo.saveAuctions(next);
    state = _repo.loadAuctions();
  }

  void _seedBotsIfEmpty() {
    final rich = state.where((a) => a.isBot && a.photoUrls.length >= 3).toList();
    if (rich.length >= 5) {
      return;
    }
    final now = DateTime.now();
    final keep = [for (final a in state) if (!a.isBot) a];
    final bots = <VehicleAuction>[
      _bot(
        now,
        id: 'bot-m2',
        title: 'BMW M2 Competition · кузов',
        brand: 'BMW',
        model: 'M2',
        year: '2023',
        details:
            'Синій M2 після удару ззаду. Задня панель, бампер, підлога багажника. Документи чисті, двигун і коробка без зауважень.',
        damage: 'Задня частина / багажник, лёгкий перекіс лонжерона',
        sellReason: 'Ремонт кузова дорожчий за ринкову вигоду — продаж «як є».',
        mileageKm: 28400,
        start: 0,
        hours: 3,
        startPrice: 420000,
        buyNow: 560000,
        photoSeed: 'bmw-m2',
        photoCount: 4,
      ),
      _bot(
        now,
        id: 'bot-golf',
        title: 'VW Golf 7 GTI · АКПП',
        brand: 'Volkswagen',
        model: 'Golf 7 GTI',
        year: '2018',
        details:
            'Живий Golf 7 GTI: двигун тягне, кузов рівний. DSG «мертва» — потрібен ремонт або заміна. Ідеально перекупу / розбору / майстру АКПП.',
        damage: 'АКПП DSG DQ250 — пробуксовка, помилки мехатроніка',
        sellReason: 'Кошторис коробки ≈ ціна авто — виставляємо на аукціон.',
        mileageKm: 142500,
        start: 0,
        hours: 2,
        startPrice: 185000,
        buyNow: 245000,
        photoSeed: 'golf-gti7',
        photoCount: 5,
      ),
      _bot(
        now,
        id: 'bot-octavia',
        title: 'Skoda Octavia A7 · після ДТП',
        brand: 'Skoda',
        model: 'Octavia',
        year: '2016',
        details:
            'Передня частина після ДТП, подушка водія спрацювала. Рама під перевірку. Документи в порядку.',
        damage: 'Перед: капот, крило, радіатор, подушка SRS',
        sellReason: 'Страхова не покриває повний ремонт — продаж з аукціону.',
        mileageKm: 198200,
        start: 20,
        hours: 4,
        startPrice: 98000,
        buyNow: 135000,
        photoSeed: 'octavia-a7',
        photoCount: 3,
      ),
      _bot(
        now,
        id: 'bot-passat',
        title: 'Passat B8 · мотор',
        brand: 'Volkswagen',
        model: 'Passat',
        year: '2017',
        details:
            'Капремонт двигуна дорожчий за сенс. Кузов і салон живі. Лотове авто для моторного цеху.',
        damage: 'Двигун 2.0 TDI — стук вкладишів, тиск масла',
        sellReason: 'Ремонт мотора не окупається — «як є».',
        mileageKm: 231000,
        start: 0,
        hours: 5,
        startPrice: 156000,
        buyNow: 210000,
        photoSeed: 'passat-b8',
        photoCount: 4,
      ),
      _bot(
        now,
        id: 'bot-focus',
        title: 'Ford Focus 3 · електроніка',
        brand: 'Ford',
        model: 'Focus',
        year: '2015',
        details:
            'Блок BCM / проводка. Авто не заводиться стабільно. На запчастини або відновлювачу електрики.',
        damage: 'Електрика: BCM, джгут салону, іммобілайзер',
        sellReason: 'Діагностика затягнулась — швидкий продаж на аукціоні.',
        mileageKm: 167800,
        start: 45,
        hours: 3,
        startPrice: 62000,
        buyNow: 89000,
        photoSeed: 'focus-mk3',
        photoCount: 3,
      ),
      _bot(
        now,
        id: 'bot-tesla',
        title: 'Tesla Model 3 · батарея',
        brand: 'Tesla',
        model: 'Model 3',
        year: '2020',
        details:
            'Деградація батареї, запас ходу падає. Кузов чистий. Аукціон для EV-майстрів.',
        damage: 'HV батарея — деградація >28%, коди BMS',
        sellReason: 'Заміна батареї нерентабельна для власника.',
        mileageKm: 89400,
        start: 0,
        hours: 6,
        startPrice: 510000,
        buyNow: 680000,
        photoSeed: 'tesla-m3',
        photoCount: 5,
      ),
    ];
    _persist([...bots, ...keep]);
  }

  VehicleAuction _bot(
    DateTime now, {
    required String id,
    required String title,
    required String brand,
    required String model,
    required String year,
    required String details,
    required String damage,
    required String sellReason,
    required int mileageKm,
    required int start,
    required int hours,
    required int startPrice,
    required int buyNow,
    required String photoSeed,
    required int photoCount,
  }) {
    final starts = now.add(Duration(minutes: start));
    return VehicleAuction(
      id: id,
      ownerLogin: 'bot_$id',
      ownerLabel: 'Ta4ka Market',
      title: title,
      details: details,
      damage: damage,
      sellReason: sellReason,
      mileageKm: mileageKm,
      createdAt: now,
      startsAt: starts,
      endsAt: starts.add(Duration(hours: hours)),
      brand: brand,
      model: model,
      year: year,
      estimateUah: startPrice + 80000,
      buyNowUah: buyNow,
      isBot: true,
      photoUrls: [
        for (var i = 1; i <= photoCount; i++)
          'https://picsum.photos/seed/$photoSeed-$i/900/560',
      ],
      bids: [
        AuctionBid(
          id: '$id-seed',
          buyerId: 'bot-buyer-1',
          buyerName: 'Bot · Перекуп #1',
          amountUah: startPrice,
          at: now,
        ),
      ],
    );
  }

  void _expireIfNeeded() {
    final now = DateTime.now();
    var changed = false;
    final next = <VehicleAuction>[];
    for (final a in state) {
      if (a.status == AuctionStatus.live &&
          a.hasStarted &&
          now.isAfter(a.endsAt)) {
        final top = a.topBid;
        if (top != null) {
          next.add(a.copyWith(status: AuctionStatus.sold, winningBidId: top.id));
        } else {
          next.add(a.copyWith(status: AuctionStatus.expired));
        }
        changed = true;
      } else {
        next.add(a);
      }
    }
    if (changed) {
      _persist(next);
    }
  }

  void upsert(VehicleAuction auction) {
    _persist([
      auction,
      for (final item in state)
        if (item.id != auction.id) item,
    ]);
  }

  /// Soft-close: bid under 1 min → at least +1 min; under 3 sec → +2 min.
  void addBid(String auctionId, AuctionBid bid) {
    _expireIfNeeded();
    VehicleAuction? target;
    for (final item in state) {
      if (item.id == auctionId) {
        target = item;
        break;
      }
    }
    if (target == null || !target.isLive) {
      return;
    }
    final top = target.topBid?.amountUah ?? 0;
    if (bid.amountUah <= top) {
      return;
    }
    final now = DateTime.now();
    final left = target.endsAt.difference(now);
    var endsAt = target.endsAt;
    if (left.inSeconds <= 3) {
      endsAt = now.add(const Duration(minutes: 2));
    } else if (left.inMinutes < 1) {
      endsAt = now.add(const Duration(minutes: 1));
    }
    final bids = [
      bid,
      for (final b in target.bids)
        if (b.buyerId != bid.buyerId) b,
    ];
    upsert(target.copyWith(bids: bids, endsAt: endsAt));
  }

  void acceptTop(String auctionId) {
    VehicleAuction? target;
    for (final item in state) {
      if (item.id == auctionId) {
        target = item;
        break;
      }
    }
    final top = target?.topBid;
    if (target == null || top == null) {
      return;
    }
    upsert(target.copyWith(status: AuctionStatus.sold, winningBidId: top.id));
  }

  /// Instant purchase at buy-now price (Copart-style).
  void buyNow(String auctionId, AuctionBid buyer) {
    _expireIfNeeded();
    VehicleAuction? target;
    for (final item in state) {
      if (item.id == auctionId) {
        target = item;
        break;
      }
    }
    if (target == null || !target.hasBuyNow) {
      return;
    }
    final bid = AuctionBid(
      id: buyer.id,
      buyerId: buyer.buyerId,
      buyerName: buyer.buyerName,
      amountUah: target.buyNowUah,
      at: DateTime.now(),
      note: buyer.note.isEmpty ? 'Buy Now' : buyer.note,
    );
    upsert(
      target.copyWith(
        bids: [bid, ...target.bids],
        status: AuctionStatus.sold,
        winningBidId: bid.id,
      ),
    );
  }

  void cancel(String auctionId) {
    VehicleAuction? target;
    for (final item in state) {
      if (item.id == auctionId) {
        target = item;
        break;
      }
    }
    if (target == null || target.status != AuctionStatus.live) {
      return;
    }
    upsert(target.copyWith(status: AuctionStatus.cancelled));
  }

  /// Simulated rival bid from a market bot.
  void placeBotBid(String auctionId) {
    VehicleAuction? target;
    for (final item in state) {
      if (item.id == auctionId) {
        target = item;
        break;
      }
    }
    if (target == null || !target.isLive) {
      return;
    }
    final top = target.topBid?.amountUah ?? 50000;
    final n = (target.bids.length % 5) + 1;
    addBid(
      auctionId,
      AuctionBid(
        id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
        buyerId: 'bot-buyer-$n',
        buyerName: 'Bot · Перекуп #$n',
        amountUah: top + 1500 + (n * 250),
        at: DateTime.now(),
      ),
    );
  }
}

final garageCarsProvider =
    StateNotifierProvider<GarageCarsController, List<GarageCar>>((ref) {
  final login = ref.watch(authProvider)?.login ?? '';
  return GarageCarsController(ref.watch(repositoryProvider), login);
});

class GarageCarsController extends StateNotifier<List<GarageCar>> {
  GarageCarsController(this._repo, this._login)
      : super(_login.isEmpty ? const [] : _repo.loadGarageCars(_login));

  final CrmRepository _repo;
  final String _login;

  bool get isBusiness => state.length > 2;

  void add(GarageCar car) {
    if (_login.isEmpty) {
      return;
    }
    final next = [car, ...state];
    _repo.saveGarageCars(_login, next);
    state = _repo.loadGarageCars(_login);
  }

  void remove(String id) {
    if (_login.isEmpty) {
      return;
    }
    final next = [for (final c in state) if (c.id != id) c];
    _repo.saveGarageCars(_login, next);
    state = _repo.loadGarageCars(_login);
  }
}

final businessInvoicesProvider =
    StateNotifierProvider<BusinessInvoicesController, List<BusinessInvoice>>(
        (ref) {
  final login = ref.watch(authProvider)?.login ?? '';
  return BusinessInvoicesController(ref.watch(repositoryProvider), login);
});

class BusinessInvoicesController extends StateNotifier<List<BusinessInvoice>> {
  BusinessInvoicesController(this._repo, this._login)
      : super(_login.isEmpty ? const [] : _repo.loadBusinessInvoices(_login));

  final CrmRepository _repo;
  final String _login;

  void createBundle(List<GarageCar> cars, int totalUah) {
    if (_login.isEmpty || cars.length <= 2) {
      return;
    }
    final invoice = BusinessInvoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerLogin: _login,
      createdAt: DateTime.now(),
      totalUah: totalUah,
      carIds: [for (final c in cars) c.id],
      lineLabels: [
        for (final c in cars) '${c.brand} ${c.model} · ${c.plate}',
      ],
    );
    final next = [invoice, ...state];
    _repo.saveBusinessInvoices(_login, next);
    state = _repo.loadBusinessInvoices(_login);
  }
}

List<WorkOrder> ordersForVin(List<WorkOrder> orders, String vinRaw) {
  final vin = normalizeVin(vinRaw);
  if (vin.isEmpty) {
    return const [];
  }
  return [
    for (final order in orders)
      if (normalizeVin(order.vin) == vin && order.status != JobStatus.cancelled)
        order,
  ];
}

final partsRequestsProvider =
    StateNotifierProvider<PartsRequestsController, List<PartsRequest>>((ref) {
  return PartsRequestsController(ref.watch(repositoryProvider));
});

class PartsRequestsController extends StateNotifier<List<PartsRequest>> {
  PartsRequestsController(this._repo) : super(_repo.loadPartsRequests());

  final CrmRepository _repo;

  void upsert(PartsRequest item) {
    final next = [
      item,
      for (final e in state)
        if (e.id != item.id) e,
    ];
    _repo.savePartsRequests(next);
    state = _repo.loadPartsRequests();
  }

  void setStatus(String id, PartsRequestStatus status) {
    PartsRequest? target;
    for (final e in state) {
      if (e.id == id) {
        target = e;
        break;
      }
    }
    if (target == null) {
      return;
    }
    upsert(target.copyWith(status: status));
  }
}

final mapaReportsProvider =
    StateNotifierProvider<MapaReportsController, MapaReportsState>((ref) {
  return MapaReportsController(ref.watch(repositoryProvider));
});

class MapaReportsState {
  const MapaReportsState({this.reports = const []});
  final List<MapaHelpReport> reports;
  Set<String> get bannedShopIds => {for (final r in reports) r.shopId};
}

class MapaReportsController extends StateNotifier<MapaReportsState> {
  MapaReportsController(this._repo)
      : super(MapaReportsState(reports: _repo.loadMapaReports()));

  final CrmRepository _repo;

  void add(MapaHelpReport report) {
    final next = [report, ...state.reports];
    _repo.saveMapaReports(next);
    state = MapaReportsState(reports: _repo.loadMapaReports());
  }
}

class MasterTabs {
  static const jobs = 0;
  static const parts = 1;
  static const me = 2;
}

final masterTabProvider = StateProvider<int>((ref) => MasterTabs.jobs);

class KioskDraft {
  const KioskDraft({
    this.step = 0,
    this.plate = '',
    this.brand = '',
    this.model = '',
    this.mileage = '',
    this.vin = '',
    this.year = '',
    this.symptom,
    this.want,
    this.category,
    this.selected = const {},
    this.inspection = const VehicleInspection(),
  });

  final int step;
  final String plate;
  final String brand;
  final String model;
  final String mileage;
  final String vin;
  final String year;
  final String? symptom;
  final String? want;
  final RepairCategory? category;
  final Map<String, SelectedWork> selected;
  final VehicleInspection inspection;

  KioskDraft copyWith({
    int? step,
    String? plate,
    String? brand,
    String? model,
    String? mileage,
    String? vin,
    String? year,
    String? symptom,
    String? want,
    RepairCategory? category,
    Map<String, SelectedWork>? selected,
    VehicleInspection? inspection,
  }) {
    return KioskDraft(
      step: step ?? this.step,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      symptom: symptom ?? this.symptom,
      want: want ?? this.want,
      category: category ?? this.category,
      selected: selected ?? this.selected,
      inspection: inspection ?? this.inspection,
    );
  }
}

final kioskProvider =
    StateNotifierProvider<KioskController, KioskDraft>((ref) {
  return KioskController(ref.watch(repositoryProvider));
});

class KioskController extends StateNotifier<KioskDraft> {
  KioskController(this._repo) : super(const KioskDraft());

  final CrmRepository _repo;

  void setStep(int step) => state = state.copyWith(step: step);

  void setIdentity({
    String? plate,
    String? brand,
    String? model,
    String? mileage,
    String? vin,
    String? year,
  }) {
    state = state.copyWith(
      plate: plate,
      brand: brand,
      model: model,
      mileage: mileage,
      vin: vin,
      year: year,
    );
  }

  void setSymptom(String id, RepairCategory category) {
    state = state.copyWith(symptom: id, category: category);
  }

  void setWant(String id) {
    state = state.copyWith(want: id);
  }

  void setCategory(RepairCategory category) {
    state = state.copyWith(category: category, selected: {});
  }

  void selectWork(ServiceWork work, PriceTier tier) {
    final remembered = _repo.rememberedPrice(work.id, tier);
    final price = remembered ?? work.priceFor(tier);
    _repo.rememberPrice(work.id, tier, price);
    final next = Map<String, SelectedWork>.from(state.selected);
    next[work.id] = SelectedWork(work: work, tier: tier, priceUah: price);
    state = state.copyWith(selected: next);
  }

  void selectOnlyWork(ServiceWork work, PriceTier tier) {
    final remembered = _repo.rememberedPrice(work.id, tier);
    final price = remembered ?? work.priceFor(tier);
    _repo.rememberPrice(work.id, tier, price);
    state = state.copyWith(
      selected: {
        work.id: SelectedWork(work: work, tier: tier, priceUah: price),
      },
    );
  }

  void removeWork(String workId) {
    final next = Map<String, SelectedWork>.from(state.selected)..remove(workId);
    state = state.copyWith(selected: next);
  }

  int? remembered(String workId, PriceTier tier) =>
      _repo.rememberedPrice(workId, tier);

  void setInspection(VehicleInspection inspection) {
    state = state.copyWith(inspection: inspection);
  }

  void reset() => state = const KioskDraft();
}

final clientLoyaltyProvider =
    StateNotifierProvider<ClientLoyaltyController, Map<String, ClientLoyalty>>(
  (ref) => ClientLoyaltyController(ref.watch(repositoryProvider)),
);

class ClientLoyaltyController extends StateNotifier<Map<String, ClientLoyalty>> {
  ClientLoyaltyController(this._repo) : super(_repo.loadClientLoyalty());

  final CrmRepository _repo;

  void _persist(Map<String, ClientLoyalty> next) {
    _repo.saveClientLoyalty(next);
    state = _repo.loadClientLoyalty();
  }

  ClientLoyalty of(String login) {
    final existing = state[login];
    if (existing != null) return existing;
    // Fresh account starts at L1 with a welcome boost so UI isn't empty.
    final seeded = const ClientLoyalty(xp: 40, shareCount: 0);
    _persist({...state, login: seeded});
    return seeded;
  }

  void addXp(String login, int xp, {String kind = ''}) {
    final cur = of(login);
    var next = cur.copyWith(xp: cur.xp + xp);
    if (kind == 'share') {
      next = next.copyWith(shareCount: cur.shareCount + 1);
    } else if (kind == 'invite') {
      next = next.copyWith(inviteCount: cur.inviteCount + 1);
    } else if (kind == 'booking') {
      next = next.copyWith(bookingCount: cur.bookingCount + 1);
    } else if (kind == 'referral') {
      next = next.copyWith(referralShopCount: cur.referralShopCount + 1);
    }
    _persist({...state, login: next});
  }
}

final referralHubProvider =
    StateNotifierProvider<ReferralController, ReferralHub>((ref) {
  return ReferralController(ref.watch(repositoryProvider));
});

class ReferralController extends StateNotifier<ReferralHub> {
  ReferralController(this._repo) : super(_repo.loadReferralHub());

  final CrmRepository _repo;

  void _persist(ReferralHub hub) {
    _repo.saveReferralHub(hub);
    state = _repo.loadReferralHub();
  }

  /// Ensures a personal referral cabinet exists for this login.
  ReferralAccount ensureAccount({
    required String login,
    String displayName = '',
  }) {
    final existing = state.of(login);
    if (existing != null) {
      if (displayName.isNotEmpty && existing.displayName != displayName) {
        final next = existing.copyWith(displayName: displayName);
        _persist(state.upsert(next));
        return next;
      }
      return existing;
    }
    final seeded = ReferralAccount(
      ownerLogin: login,
      inviteCode: ReferralHub.codeFor(login),
      displayName: displayName,
      shops: [
        ReferralShopLink(
          id: 'demo-$login-1',
          shopName: 'Ta4ka Demo · ходова',
          city: 'Warsaw',
          level: 1,
          status: ReferralShopStatus.approved,
          connectedAt: DateTime.now().subtract(const Duration(days: 40)),
          managerName: 'Oleg',
          monthTurnoverUah: 186000,
          photoUrl: 'https://picsum.photos/seed/ref-shop-1/640/400',
          note: 'Підключено: показ додатку + реєстрація admin',
        ),
        ReferralShopLink(
          id: 'demo-$login-2',
          shopName: 'NordLift Express',
          city: 'Warsaw',
          level: 2,
          status: ReferralShopStatus.approved,
          connectedAt: DateTime.now().subtract(const Duration(days: 18)),
          managerName: 'Iryna',
          monthTurnoverUah: 92000,
          photoUrl: 'https://picsum.photos/seed/ref-shop-2/640/400',
          note: 'L2 — партнер по вашому коду',
        ),
      ],
    );
    _persist(state.upsert(seeded));
    return seeded;
  }

  void saveRequisites({
    required String login,
    required String fullName,
    required String iban,
    required String phone,
    required String payoutRequisites,
  }) {
    final acc = ensureAccount(login: login);
    _persist(
      state.upsert(
        acc.copyWith(
          fullName: fullName,
          iban: iban,
          phone: phone,
          payoutRequisites: payoutRequisites,
        ),
      ),
    );
  }

  void submitShop({
    required String login,
    required String shopName,
    required String city,
    required String managerName,
    required String photoUrl,
    String note = '',
  }) {
    final acc = ensureAccount(login: login);
    final link = ReferralShopLink(
      id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
      shopName: shopName.trim(),
      city: city.trim(),
      level: 1,
      status: ReferralShopStatus.pending,
      connectedAt: DateTime.now(),
      managerName: managerName.trim(),
      photoUrl: photoUrl.trim(),
      note: note.trim(),
      monthTurnoverUah: 0,
    );
    _persist(state.upsert(acc.copyWith(shops: [link, ...acc.shops])));
  }

  void setShopStatus({
    required String login,
    required String shopId,
    required ReferralShopStatus status,
  }) {
    final acc = state.of(login);
    if (acc == null) return;
    _persist(
      state.upsert(
        acc.copyWith(
          shops: [
            for (final s in acc.shops)
              if (s.id == shopId) s.copyWith(status: status) else s,
          ],
        ),
      ),
    );
  }
}
