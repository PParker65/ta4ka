import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/l10n/app_lang.dart';
import '../core/network/api_client.dart';
import 'auto_spheres.dart';
import 'catalog_seed.dart';
import 'photo_sphere_guess.dart';

class AiTriageResult {
  const AiTriageResult({
    required this.summary,
    required this.workIds,
    this.sphereIds = const [],
  });

  final L summary;
  final List<String> workIds;
  final List<String> sphereIds;
}

abstract class AiTriageApi {
  Future<AiTriageResult> analyze({
    required String query,
    required AppLang lang,
    String? photoBase64,
    String? photoMime,
  });
}

class RemoteAiTriageApi implements AiTriageApi {
  RemoteAiTriageApi(this._client);

  final ApiClient _client;

  @override
  Future<AiTriageResult> analyze({
    required String query,
    required AppLang lang,
    String? photoBase64,
    String? photoMime,
  }) async {
    final response = await _client.raw.post<Map<String, dynamic>>(
      '/v1/ai/triage',
      data: {
        'query': query,
        'lang': lang.code,
        if (photoBase64 != null) 'photoBase64': photoBase64,
        if (photoMime != null) 'photoMime': photoMime,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return _decode(data, lang);
  }
}

class OpenAiTriageApi implements AiTriageApi {
  OpenAiTriageApi({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  @override
  Future<AiTriageResult> analyze({
    required String query,
    required AppLang lang,
    String? photoBase64,
    String? photoMime,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com',
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final langName = switch (lang) {
      AppLang.uk => 'Ukrainian',
      AppLang.en => 'English',
      AppLang.ru => 'Russian',
      AppLang.pl => 'Polish',
    };

    final workCsv = [for (final work in catalogWorks) '"${work.id}"'].join(',');
    final sphereCsv = [for (final sphere in autoSpheres) '"${sphere.id}"'].join(',');
    final textPart = {
      'type': 'text',
      'text': '''
You are an auto repair triage assistant.
Return STRICT JSON with keys:
- summary: short sentence in $langName
- workIds: array of 1-3 values from this whitelist only:
[$workCsv].
- sphereIds: array of 1-4 values from this whitelist only:
[$sphereCsv].
If uncertain include "diag" and "diag-comp".
User issue: $query
''',
    };

    final content = <Map<String, dynamic>>[textPart];
    if (photoBase64 != null && photoMime != null) {
      content.add(
        {
          'type': 'image_url',
          'image_url': {'url': 'data:$photoMime;base64,$photoBase64'},
        },
      );
    }

    final response = await dio.post<Map<String, dynamic>>(
      '/v1/chat/completions',
      data: {
        'model': model,
        'temperature': 0.1,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      },
    );

    final root = response.data ?? const <String, dynamic>{};
    final choices = root['choices'] as List<dynamic>? ?? const [];
    final first = choices.isNotEmpty ? choices.first as Map<String, dynamic> : const <String, dynamic>{};
    final message = first['message'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final contentText = message['content']?.toString() ?? '{}';

    final jsonStart = contentText.indexOf('{');
    final jsonEnd = contentText.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw const FormatException('AI response is not JSON');
    }
    final jsonRaw = contentText.substring(jsonStart, jsonEnd + 1);
    final decoded = jsonDecode(jsonRaw) as Map<String, dynamic>;
    return _decode(decoded, lang);
  }
}

class MockAiTriageApi implements AiTriageApi {
  @override
  Future<AiTriageResult> analyze({
    required String query,
    required AppLang lang,
    String? photoBase64,
    String? photoMime,
  }) async {
    if ((query.trim().isEmpty) && photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final guess = await guessSpheresFromPhoto(base64Decode(photoBase64));
        return _fromSpheres(
          spheresFromIds(guess.sphereIds),
          guess.summary,
        );
      } catch (_) {
        return _fromSpheres(
          spheresFromIds(const ['body', 'paint', 'pdr', 'bumper']),
          const L(
            'По фото схоже на кузов — рихтовка, фарба або вмʼятина.',
            'The photo looks like bodywork — dent, paint or bumper.',
            'По фото похоже на кузов — рихтовка, краска или бампер.',
          ),
        );
      }
    }

    final matches = searchSpheres(query, lang: lang);
    final summary = matches.isNotEmpty
        ? L(
            'Знайшли ${matches.length} категорій — оберіть найближчу.',
            'Found ${matches.length} categories — pick the closest one.',
            'Нашли ${matches.length} категорий — выберите ближайшую.',
          )
        : const L(
            'Для точності почнімо з компʼютерної діагностики.',
            'For accuracy, start with computer diagnostics.',
            'Для точности начнем с компьютерной диагностики.',
          );
    return _fromSpheres(
      matches.take(4).toList(),
      summary,
      fallbackIds: const ['diag'],
    );
  }

  AiTriageResult _fromSpheres(
    List<AutoSphere> spheres,
    L summary, {
    List<String> fallbackIds = const [],
  }) {
    final workIds = <String>{};
    for (final sphere in spheres.take(3)) {
      workIds.addAll(sphere.workIds);
    }
    if (workIds.isEmpty) {
      workIds.add('diag-comp');
    }
    final sphereIds = [for (final sphere in spheres) sphere.id];
    return AiTriageResult(
      summary: summary,
      workIds: workIds.take(3).toList(),
      sphereIds: sphereIds.isEmpty ? fallbackIds : sphereIds,
    );
  }
}

class ResilientAiTriageApi implements AiTriageApi {
  ResilientAiTriageApi(this.primary, this.fallback);

  final AiTriageApi primary;
  final AiTriageApi fallback;

  @override
  Future<AiTriageResult> analyze({
    required String query,
    required AppLang lang,
    String? photoBase64,
    String? photoMime,
  }) async {
    try {
      return await primary.analyze(
        query: query,
        lang: lang,
        photoBase64: photoBase64,
        photoMime: photoMime,
      );
    } catch (_) {
      return fallback.analyze(
        query: query,
        lang: lang,
        photoBase64: photoBase64,
        photoMime: photoMime,
      );
    }
  }
}

AiTriageApi createAiTriageApi(ApiClient client) {
  final fallback = MockAiTriageApi();
  if (client.isConfigured) {
    return ResilientAiTriageApi(RemoteAiTriageApi(client), fallback);
  }
  const key = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  const model = String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');
  if (key.isNotEmpty) {
    return ResilientAiTriageApi(
      OpenAiTriageApi(apiKey: key, model: model),
      fallback,
    );
  }
  return fallback;
}

AiTriageResult _decode(Map<String, dynamic> json, AppLang lang) {
  final summaryRaw = json['summary']?.toString().trim();
  final summary = summaryRaw == null || summaryRaw.isEmpty
      ? const L(
          'Почнемо з діагностики.',
          'Let us start with diagnostics.',
          'Начнем с диагностики.',
        )
      : L(summaryRaw, summaryRaw, summaryRaw);

  final allowed = {for (final work in catalogWorks) work.id};
  final items = json['workIds'] as List<dynamic>? ?? const [];
  final workIds = [
    for (final item in items)
      if (allowed.contains(item.toString())) item.toString(),
  ];

  final sphereAllowed = {for (final sphere in autoSpheres) sphere.id};
  final sphereItems = json['sphereIds'] as List<dynamic>? ?? const [];
  final sphereIds = [
    for (final item in sphereItems)
      if (sphereAllowed.contains(item.toString())) item.toString(),
  ];

  return AiTriageResult(
    summary: summary,
    workIds: workIds.isEmpty ? const ['diag-comp'] : workIds.take(3).toList(),
    sphereIds: sphereIds.take(4).toList(),
  );
}

