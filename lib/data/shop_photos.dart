/// Workshop photos a real shop would upload (bay, yard, tools, exterior).
/// Each shop gets a stable set keyed by `shop.id`.
const kShopPhotoPool = <String>[
  'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1723099971299-3789db53604c?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1698796783361-c92fe82d9b79?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1635108198395-82a67cd5eaec?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1657490017761-381bdf660ff4?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1676018366904-c083ed678e60?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1702146713858-8e7d1cc29fe8?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1702146713882-2579afb0bfba?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1702146715471-ae6b10689969?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1599256630445-67b5772b1204?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1599256871787-737fd3315df2?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1601924925166-22a19c485db7?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1599256872237-5dcc0fbe9668?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1509440040931-1505a7cb590e?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1583870908969-89c2ea77dc34?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1702146715274-d466e629ecc2?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1702146713870-8cdd7ab983fb?auto=format&fit=crop&w=900&q=75',
  'https://images.unsplash.com/photo-1530046339160-ce3e530c7d2f?auto=format&fit=crop&w=900&q=75',
];

int shopPhotoHash(String seed) {
  var h = 2166136261;
  for (final u in seed.codeUnits) {
    h ^= u;
    h = (h * 16777619) & 0x7fffffff;
  }
  return h;
}

String shopPhotoAt(String shopId, int slot) {
  final n = kShopPhotoPool.length;
  return kShopPhotoPool[(shopPhotoHash(shopId).abs() + slot * 7) % n];
}

String shopCoverPhoto(String shopId) {
  if (shopId == 'pitlane') {
    return kShopPhotoPool[2];
  }
  return shopPhotoAt(shopId, 0);
}

List<String> shopGalleryPhotos(String shopId, {int count = 4}) {
  return [for (var i = 1; i <= count; i++) shopPhotoAt(shopId, i)];
}
