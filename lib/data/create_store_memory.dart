import 'crm_store.dart';
import 'memory_crm_store.dart';

Future<CrmStore> createCrmStore({bool inMemory = false}) async {
  final store = MemoryCrmStore();
  await store.init();
  return store;
}
