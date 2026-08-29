import 'crm_store.dart';
import 'create_store_memory.dart'
    if (dart.library.io) 'create_store_io.dart' as impl;

Future<CrmStore> createCrmStore({bool inMemory = false}) {
  return impl.createCrmStore(inMemory: inMemory);
}
