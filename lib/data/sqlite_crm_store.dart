import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

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

class SqliteCrmStore implements CrmStore {
  SqliteCrmStore({this.memory = false});

  final bool memory;
  Database? _db;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Database is not initialized');
    }
    return database;
  }

  @override
  Future<void> init() async {
    if (memory) {
      _db = sqlite3.openInMemory();
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _db = sqlite3.open(p.join(dir.path, 'autoservice_crm.db'));
      } catch (_) {
        _db = sqlite3.openInMemory();
      }
    }
    db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS price_memory (
        work_id TEXT NOT NULL,
        tier TEXT NOT NULL,
        price_uah INTEGER NOT NULL,
        PRIMARY KEY (work_id, tier)
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS work_orders (
        id TEXT PRIMARY KEY,
        plate TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL DEFAULT 0,
        mileage INTEGER NOT NULL,
        vin TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        box_id TEXT,
        master_id TEXT,
        created_at INTEGER NOT NULL,
        inspection_json TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS order_lines (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        work_id TEXT NOT NULL,
        title_uk TEXT NOT NULL,
        title_en TEXT NOT NULL,
        title_ru TEXT NOT NULL,
        tier TEXT NOT NULL,
        price_uah INTEGER NOT NULL,
        minutes INTEGER NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS ratings (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        master_id TEXT NOT NULL,
        stars INTEGER NOT NULL,
        quality INTEGER NOT NULL DEFAULT 0,
        politeness INTEGER NOT NULL DEFAULT 0,
        punctuality INTEGER NOT NULL DEFAULT 0,
        cleanliness INTEGER NOT NULL DEFAULT 0,
        comment TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    try {
      db.execute(
        'ALTER TABLE work_orders ADD COLUMN year INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
    try {
      db.execute(
        "ALTER TABLE work_orders ADD COLUMN shop_id TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {}
    try {
      db.execute('ALTER TABLE work_orders ADD COLUMN scheduled_at INTEGER');
    } catch (_) {}
    try {
      db.execute(
        'ALTER TABLE order_lines ADD COLUMN approved INTEGER NOT NULL DEFAULT 1',
      );
    } catch (_) {}
    try {
      db.execute(
        'ALTER TABLE order_lines ADD COLUMN extra INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
    try {
      db.execute('ALTER TABLE work_orders ADD COLUMN chat_json TEXT');
    } catch (_) {}
    try {
      db.execute(
        "ALTER TABLE work_orders ADD COLUMN client_login TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {}
    try {
      db.execute('ALTER TABLE work_orders ADD COLUMN meta_json TEXT');
    } catch (_) {}
    for (final column in [
      'quality INTEGER NOT NULL DEFAULT 0',
      'politeness INTEGER NOT NULL DEFAULT 0',
      'punctuality INTEGER NOT NULL DEFAULT 0',
      'cleanliness INTEGER NOT NULL DEFAULT 0',
    ]) {
      try {
        db.execute('ALTER TABLE ratings ADD COLUMN $column');
      } catch (_) {}
    }
  }

  String? _setting(String key) {
    final rows = db.select('SELECT value FROM settings WHERE key = ?', [key]);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String;
  }

  void _setSetting(String key, String value) {
    db.execute(
      'INSERT OR REPLACE INTO settings(key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  @override
  AppLang loadLang() {
    return AppLangX.fromCode(_setting('lang') ?? 'uk');
  }

  @override
  void saveLang(AppLang lang) {
    _setSetting('lang', lang.code);
  }

  @override
  AppVisualTheme loadTheme() {
    return AppVisualThemeX.fromCode(_setting('theme'));
  }

  @override
  void saveTheme(AppVisualTheme theme) {
    _setSetting('theme', theme.code);
  }

  @override
  AuthSession? loadSession() {
    final raw = _setting('session');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void saveSession(AuthSession? session) {
    if (session == null) {
      db.execute('DELETE FROM settings WHERE key = ?', ['session']);
      return;
    }
    _setSetting('session', jsonEncode(session.toJson()));
  }

  @override
  ShopAccount? loadShopAccount() {
    final raw = _setting('shop_account');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return ShopAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  void saveShopAccount(ShopAccount? account) {
    if (account == null) {
      db.execute('DELETE FROM settings WHERE key = ?', ['shop_account']);
      return;
    }
    _setSetting('shop_account', jsonEncode(account.toJson()));
  }

  @override
  TapWalletState loadTapWallet() {
    final raw = _setting('tap_wallet');
    if (raw == null || raw.isEmpty) {
      return const TapWalletState();
    }
    try {
      return TapWalletState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TapWalletState();
    }
  }

  @override
  void saveTapWallet(TapWalletState wallet) {
    _setSetting('tap_wallet', jsonEncode(wallet.toJson()));
  }

  @override
  ReferralHub loadReferralHub() {
    final raw = _setting('referral_hub');
    if (raw == null || raw.isEmpty) {
      return const ReferralHub();
    }
    try {
      return ReferralHub.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const ReferralHub();
    }
  }

  @override
  void saveReferralHub(ReferralHub hub) {
    _setSetting('referral_hub', jsonEncode(hub.toJson()));
  }

  @override
  Map<String, ClientLoyalty> loadClientLoyalty() {
    final raw = _setting('client_loyalty');
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return {
        for (final e in map.entries)
          '${e.key}': ClientLoyalty.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  @override
  void saveClientLoyalty(Map<String, ClientLoyalty> map) {
    _setSetting(
      'client_loyalty',
      jsonEncode({for (final e in map.entries) e.key: e.value.toJson()}),
    );
  }

  @override
  int? rememberedPrice(String workId, PriceTier tier) {
    final rows = db.select(
      'SELECT price_uah FROM price_memory WHERE work_id = ? AND tier = ?',
      [workId, tier.name],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['price_uah'] as int;
  }

  @override
  void rememberPrice(String workId, PriceTier tier, int priceUah) {
    db.execute(
      'INSERT OR REPLACE INTO price_memory(work_id, tier, price_uah) VALUES (?, ?, ?)',
      [workId, tier.name, priceUah],
    );
  }

  @override
  List<WorkOrder> loadOrders() {
    final orderRows = db.select(
      'SELECT * FROM work_orders ORDER BY created_at DESC',
    );
    return [for (final row in orderRows) _orderFromRow(row)];
  }

  @override
  void upsertOrder(WorkOrder order) {
    db.execute(
      '''INSERT OR REPLACE INTO work_orders(
           id, plate, brand, model, year, mileage, vin, category, status,
           box_id, master_id, shop_id, client_login, scheduled_at, created_at, inspection_json,
           chat_json, meta_json
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        order.id,
        order.plate,
        order.brand,
        order.model,
        order.year,
        order.mileage,
        order.vin,
        order.category.name,
        order.status.name,
        order.boxId,
        order.masterId,
        order.shopId,
        order.clientLogin,
        order.scheduledAt?.millisecondsSinceEpoch,
        order.createdAt.millisecondsSinceEpoch,
        jsonEncode(inspectionToJson(order.inspection)),
        jsonEncode([for (final item in order.chat) item.toJson()]),
        jsonEncode({
          'draftEstimate': [for (final e in order.draftEstimate) e.toJson()],
          'defectPhotos': [for (final e in order.defectPhotos) e.toJson()],
          'commissionBaseUah': order.commissionBaseUah,
        }),
      ],
    );
    db.execute('DELETE FROM order_lines WHERE order_id = ?', [order.id]);
    for (var i = 0; i < order.lines.length; i++) {
      final line = order.lines[i];
      db.execute(
        '''INSERT INTO order_lines(
             id, order_id, work_id, title_uk, title_en, title_ru,
             tier, price_uah, minutes, approved, extra
           ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          '${order.id}_$i',
          order.id,
          line.workId,
          line.title.uk,
          line.title.en,
          line.title.ru,
          line.tier.name,
          line.priceUah,
          line.minutes,
          line.approved ? 1 : 0,
          line.extra ? 1 : 0,
        ],
      );
    }
  }

  @override
  void deleteOrder(String id) {
    db.execute('DELETE FROM order_lines WHERE order_id = ?', [id]);
    db.execute('DELETE FROM work_orders WHERE id = ?', [id]);
  }

  @override
  List<Rating> loadRatings() {
    final rows = db.select('SELECT * FROM ratings ORDER BY created_at DESC');
    return [
      for (final row in rows)
        Rating(
          id: row['id'] as String,
          orderId: row['order_id'] as String,
          masterId: row['master_id'] as String,
          quality: (row['quality'] as int?) ?? (row['stars'] as int? ?? 5),
          politeness: (row['politeness'] as int?) ?? (row['stars'] as int? ?? 5),
          punctuality:
              (row['punctuality'] as int?) ?? (row['stars'] as int? ?? 5),
          cleanliness:
              (row['cleanliness'] as int?) ?? (row['stars'] as int? ?? 5),
          comment: row['comment'] as String,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        ),
    ];
  }

  @override
  void addRating(Rating rating) {
    db.execute(
      '''INSERT OR REPLACE INTO ratings(
           id, order_id, master_id, stars, quality, politeness, punctuality,
           cleanliness, comment, created_at
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        rating.id,
        rating.orderId,
        rating.masterId,
        rating.stars,
        rating.quality,
        rating.politeness,
        rating.punctuality,
        rating.cleanliness,
        rating.comment,
        rating.createdAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  List<BlacklistEntry> loadBlacklist() {
    return _decodeList('platform_blacklist', BlacklistEntry.fromJson);
  }

  @override
  void saveBlacklist(List<BlacklistEntry> items) {
    _encodeList('platform_blacklist', [for (final e in items) e.toJson()]);
  }

  @override
  List<OpenJobRequest> loadOpenJobs() {
    return _decodeList('platform_open_jobs', OpenJobRequest.fromJson);
  }

  @override
  void saveOpenJobs(List<OpenJobRequest> items) {
    _encodeList('platform_open_jobs', [for (final e in items) e.toJson()]);
  }

  @override
  List<VehicleAuction> loadAuctions() {
    return _decodeList('platform_auctions', VehicleAuction.fromJson);
  }

  @override
  void saveAuctions(List<VehicleAuction> items) {
    _encodeList('platform_auctions', [for (final e in items) e.toJson()]);
  }

  @override
  List<GarageCar> loadGarageCars(String ownerLogin) {
    return _decodeList('garage_$ownerLogin', GarageCar.fromJson);
  }

  @override
  void saveGarageCars(String ownerLogin, List<GarageCar> cars) {
    _encodeList('garage_$ownerLogin', [for (final e in cars) e.toJson()]);
  }

  @override
  List<BusinessInvoice> loadBusinessInvoices(String ownerLogin) {
    return _decodeList('biz_inv_$ownerLogin', BusinessInvoice.fromJson);
  }

  @override
  void saveBusinessInvoices(String ownerLogin, List<BusinessInvoice> items) {
    _encodeList('biz_inv_$ownerLogin', [for (final e in items) e.toJson()]);
  }

  @override
  List<PartsRequest> loadPartsRequests() {
    return _decodeList('platform_parts_requests', PartsRequest.fromJson);
  }

  @override
  void savePartsRequests(List<PartsRequest> items) {
    _encodeList(
      'platform_parts_requests',
      [for (final e in items) e.toJson()],
    );
  }

  @override
  List<MapaHelpReport> loadMapaReports() {
    return _decodeList('platform_mapa_reports', MapaHelpReport.fromJson);
  }

  @override
  void saveMapaReports(List<MapaHelpReport> items) {
    _encodeList(
      'platform_mapa_reports',
      [for (final e in items) e.toJson()],
    );
  }

  List<T> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _setting(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return const [];
      }
      return [
        for (final item in parsed)
          fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _encodeList(String key, List<Map<String, dynamic>> items) {
    _setSetting(key, jsonEncode(items));
  }

  WorkOrder _orderFromRow(Row row) {
    final id = row['id'] as String;
    final lineRows = db.select(
      'SELECT * FROM order_lines WHERE order_id = ?',
      [id],
    );
    return WorkOrder(
      id: id,
      plate: row['plate'] as String,
      brand: row['brand'] as String,
      model: row['model'] as String,
      year: (row['year'] as int?) ?? 0,
      mileage: row['mileage'] as int,
      vin: row['vin'] as String,
      category: RepairCategory.values.byName(row['category'] as String),
      status: JobStatus.values.byName(row['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      boxId: row['box_id'] as String?,
      masterId: row['master_id'] as String?,
      shopId: (row['shop_id'] as String?) ?? '',
      clientLogin: (row['client_login'] as String?) ?? '',
      scheduledAt: row['scheduled_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['scheduled_at'] as int),
      inspection: inspectionFromJson(
        jsonDecode(row['inspection_json'] as String) as Map<String, dynamic>,
      ),
      chat: _chatFromRow(row),
      draftEstimate: _metaDraft(row),
      defectPhotos: _metaDefects(row),
      commissionBaseUah: _metaCommissionBase(row),
      lines: [
        for (final line in lineRows)
          OrderLine(
            workId: line['work_id'] as String,
            title: L(
              line['title_uk'] as String,
              line['title_en'] as String,
              line['title_ru'] as String,
            ),
            tier: PriceTier.values.byName(line['tier'] as String),
            priceUah: line['price_uah'] as int,
            minutes: line['minutes'] as int,
            approved: (line['approved'] as int?) != 0,
            extra: (line['extra'] as int?) == 1,
          ),
      ],
    );
  }

  List<ServiceChatMessage> _chatFromRow(Row row) {
    try {
      final raw = row['chat_json'] as String?;
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return const [];
      }
      return [
        for (final item in parsed)
          ServiceChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _metaMap(Row row) {
    try {
      final raw = row['meta_json'] as String?;
      if (raw == null || raw.isEmpty) {
        return const {};
      }
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
    } catch (_) {}
    return const {};
  }

  List<DraftEstimateLine> _metaDraft(Row row) {
    final meta = _metaMap(row);
    return [
      for (final item in meta['draftEstimate'] as List<dynamic>? ?? const [])
        DraftEstimateLine.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  List<MarkedDefectPhoto> _metaDefects(Row row) {
    final meta = _metaMap(row);
    return [
      for (final item in meta['defectPhotos'] as List<dynamic>? ?? const [])
        MarkedDefectPhoto.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  int _metaCommissionBase(Row row) {
    return (_metaMap(row)['commissionBaseUah'] as num?)?.toInt() ?? 0;
  }
}

CrmStore createStore({bool memory = false}) => SqliteCrmStore(memory: memory);
