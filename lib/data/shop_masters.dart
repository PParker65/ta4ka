import '../domain/models/shop_account.dart';
import '../domain/models/shop_models.dart';

List<ShopMaster> mastersVisible(ShopProfile shop, ShopAccount account) {
  if (shop.id == account.catalogShopId && account.deskMasters.isNotEmpty) {
    return [for (final m in account.deskMasters) m.toShopMaster()];
  }
  return shop.masters;
}
