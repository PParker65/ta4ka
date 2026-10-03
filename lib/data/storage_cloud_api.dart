import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../app/preview_context.dart';
import '../domain/models/wheel_storage.dart';

const kStorageCloudTokenKey = 'kolesasave_api_token_v1';

class StorageCloudException implements Exception {
  const StorageCloudException(this.code, {this.status = 0});

  final String code;
  final int status;

  bool get exists => code == 'exists' || status == 409;

  bool get unauthorized => code == 'unauthorized' || status == 401;

  @override
  String toString() => 'StorageCloudException($code,$status)';
}

class StorageCloudSession {
  const StorageCloudSession({
    required this.token,
    required this.email,
    required this.shopName,
  });

  final String token;
  final String email;
  final String shopName;
}

class StorageLotsPayload {
  const StorageLotsPayload({
    this.lots = const [],
    this.pricePerDayGrosze = 0,
    this.sectorCount = kDefaultSectors,
    this.shopJournalHydrated = '',
  });

  final List<WheelLot> lots;
  final int pricePerDayGrosze;
  final int sectorCount;
  final String shopJournalHydrated;

  Map<String, dynamic> toJson() => {
        'lots': lots.map((lot) => lot.toJson()).toList(),
        'pricePerDayGrosze': pricePerDayGrosze,
        'sectorCount': sectorCount,
        'shopJournalHydrated': shopJournalHydrated,
      };

  factory StorageLotsPayload.fromJson(Map<String, dynamic> json) {
    final raw = json['lots'];
    final lots = <WheelLot>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final lot = WheelLot.fromJson(Map<String, dynamic>.from(item));
        if (lot.id.isEmpty) continue;
        lots.add(lot);
      }
    }
    final rawSectors = json['sectorCount'];
    final sectors = rawSectors is num
        ? rawSectors.toInt()
        : (rawSectors is String ? int.tryParse(rawSectors) : null);
    return StorageLotsPayload(
      lots: lots,
      pricePerDayGrosze: (json['pricePerDayGrosze'] as num?)?.toInt() ?? 0,
      sectorCount: clampSectorCount(sectors),
      shopJournalHydrated: json['shopJournalHydrated'] as String? ?? '',
    );
  }
}

bool useStorageCloud([Uri? uri]) => isKolesaSaveHost(uri);

class StorageCloudApi {
  StorageCloudApi({Dio? dio, String? origin})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'accept': 'application/json',
                  'content-type': 'application/json',
                },
              ),
            ),
        origin = origin ?? _defaultOrigin();

  final Dio _dio;
  final String origin;

  static final StorageCloudApi instance = StorageCloudApi();

  static String _defaultOrigin() {
    if (kIsWeb) {
      try {
        final here = Uri.base.origin;
        if (here.isNotEmpty && isKolesaSaveHost(Uri.base)) return here;
      } catch (_) {}
    }
    return 'https://kolesasave.com';
  }

  Future<StorageCloudSession> register({
    required String email,
    required String password,
    required String shopName,
  }) {
    return _auth('/api/register', {
      'email': email.trim().toLowerCase(),
      'password': password,
      'shopName': shopName.trim(),
    });
  }

  Future<StorageCloudSession> login({
    required String email,
    required String password,
  }) {
    return _auth('/api/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _send(
      'POST',
      '/api/password',
      data: {'old': oldPassword, 'new': newPassword},
      token: token,
    );
  }

  Future<bool> ping(String token) async {
    try {
      await _send('GET', '/api/me', token: token);
      return true;
    } on StorageCloudException catch (e) {
      if (e.unauthorized) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<StorageLotsPayload> loadLots(String token) async {
    final body = await _send('GET', '/api/lots', token: token);
    return StorageLotsPayload.fromJson(body);
  }

  Future<void> saveLots(String token, StorageLotsPayload payload) async {
    await _send('PUT', '/api/lots', data: payload.toJson(), token: token);
  }

  Future<StorageCloudSession> _auth(
    String path,
    Map<String, dynamic> data,
  ) async {
    final body = await _send('POST', path, data: data);
    final token = (body['token'] as String? ?? '').trim();
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    if (token.isEmpty || email.isEmpty) {
      throw const StorageCloudException('unauthorized', status: 401);
    }
    return StorageCloudSession(
      token: token,
      email: email,
      shopName: (body['shopName'] as String? ?? '').trim(),
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final res = await _dio.request<Map<String, dynamic>>(
        '$origin$path',
        data: data,
        options: Options(
          method: method,
          headers: {
            if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
          },
        ),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      final code = e.response?.data;
      final status = e.response?.statusCode ?? 0;
      if (code is Map && code['error'] is String) {
        throw StorageCloudException(code['error'] as String, status: status);
      }
      if (status == 409) throw const StorageCloudException('exists', status: 409);
      if (status == 401) {
        throw const StorageCloudException('unauthorized', status: 401);
      }
      debugPrint('storage cloud $method $path: $e');
      throw StorageCloudException('offline', status: status);
    }
  }
}
