import '../../core/l10n/app_lang.dart';
import 'crm_models.dart';

class ShopMaster {
  const ShopMaster({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
  });

  final String id;
  final L name;
  final MasterSpecialty specialty;
  final L bio;
}

class ShopReview {
  const ShopReview({
    required this.author,
    required this.stars,
    required this.text,
  });

  final String author;
  final int stars;
  final L text;
}

class ShopGalleryItem {
  const ShopGalleryItem({required this.title, required this.icon});

  final L title;
  final IconKey icon;
}

enum IconKey { bay, engine, chips, paint, lift, night }

/// How the shop presents itself: garage bay, full service, or dealer showroom.
enum ShopPositioning {
  garage,
  service,
  dealer;

  /// Settings value, or a stable mix from [seed] when missing / unknown.
  static ShopPositioning resolve(String? raw, {required String seed}) {
    switch (raw) {
      case 'garage':
        return garage;
      case 'dealer':
        return dealer;
      case 'service':
        return service;
    }
    var h = 2166136261;
    for (final u in seed.codeUnits) {
      h ^= u;
      h = (h * 16777619) & 0x7fffffff;
    }
    return values[h.abs() % values.length];
  }
}

const kShopHours = L(
  'Пн–Сб 09:00–18:00 · неділя вихідний',
  'Mon–Sat 09:00–18:00 · closed Sunday',
  'Пн–Сб 09:00–18:00 · воскресенье выходной',
  'Pn–Sb 09:00–18:00 · niedziela wolna',
);

const kTowHours = L(
  'Виїзд 24/7 · бокс Пн–Сб 09:00–18:00',
  'Dispatch 24/7 · bay Mon–Sat 09:00–18:00',
  'Выезд 24/7 · бокс Пн–Сб 09:00–18:00',
);

class ShopProfile {
  const ShopProfile({
    required this.id,
    required this.name,
    required this.cityId,
    required this.city,
    required this.address,
    required this.distanceKm,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.workIds,
    required this.masters,
    required this.reviews,
    required this.gallery,
    required this.liveFromBay,
    required this.phone,
    required this.lead,
    this.hours = kShopHours,
    this.mapaHelp = false,
    this.positioning = '',
  });

  final String id;
  final L name;
  final String cityId;
  final L city;
  final L address;
  final double distanceKm;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final List<L> tags;
  final List<String> workIds;
  final List<ShopMaster> masters;
  final List<ShopReview> reviews;
  final List<ShopGalleryItem> gallery;
  final bool liveFromBay;
  final String phone;
  final L lead;
  final L hours;
  /// Night / roadside help network (MAPA Help).
  final bool mapaHelp;
  /// `garage` | `service` | `dealer`. Empty → hashed from [id].
  final String positioning;

  ShopPositioning get kind =>
      ShopPositioning.resolve(positioning, seed: id);

  String get initials {
    final parts = name.uk.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'СТО';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  ShopProfile copyWith({
    double? distanceKm,
    List<ShopMaster>? masters,
    L? hours,
    bool? mapaHelp,
    String? positioning,
  }) {
    return ShopProfile(
      id: id,
      name: name,
      cityId: cityId,
      city: city,
      address: address,
      distanceKm: distanceKm ?? this.distanceKm,
      lat: lat,
      lng: lng,
      rating: rating,
      reviewCount: reviewCount,
      tags: tags,
      workIds: workIds,
      masters: masters ?? this.masters,
      reviews: reviews,
      gallery: gallery,
      liveFromBay: liveFromBay,
      phone: phone,
      lead: lead,
      hours: hours ?? this.hours,
      mapaHelp: mapaHelp ?? this.mapaHelp,
      positioning: positioning ?? this.positioning,
    );
  }
}

class ShopTimeSlot {
  const ShopTimeSlot({
    required this.start,
    required this.masterId,
    required this.open,
  });

  final DateTime start;
  final String masterId;
  final bool open;
}

class FeedClip {
  const FeedClip({
    required this.id,
    required this.shopId,
    required this.title,
    required this.caption,
    required this.live,
    required this.video,
    this.youtubeId,
    this.streamUrl,
    this.videoAsset,
    this.viewCount = 0,
    this.channel,
    this.cityId,
  });

  final String id;
  final String shopId;
  /// Preferred city for location-ranked feed. Null = show in every city.
  final String? cityId;
  final L title;
  final L caption;
  final bool live;
  final bool video;
  final String? youtubeId;
  /// Remote MP4 (Mixkit etc.) — works without bundling.
  final String? streamUrl;
  /// Bundled mp4 filename under assets/feed/.
  final String? videoAsset;
  final int viewCount;
  final L? channel;

  String get playbackUrl {
    if (streamUrl != null && streamUrl!.isNotEmpty) return streamUrl!;
    final asset = videoAsset;
    if (asset != null && asset.isNotEmpty) {
      return '/assets/assets/feed/$asset';
    }
    return '';
  }

  String get youtubeThumbnail {
    final id = youtubeId;
    if (id == null || id.isEmpty) return '';
    return 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
  }

  String get youtubeThumbFallback {
    final id = youtubeId;
    if (id == null || id.isEmpty) return '';
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}

enum ShopSort { rating, distance, slotsToday }
