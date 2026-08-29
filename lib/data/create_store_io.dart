import 'package:flutter/foundation.dart';

import 'crm_store.dart';
import 'memory_crm_store.dart';
import 'sqlite_crm_store.dart';

Future<CrmStore> createCrmStore({bool inMemory = false}) async {
  if (inMemory) {
    final store = MemoryCrmStore();
    await store.init();
    return store;
  }

  try {
    final store = SqliteCrmStore(memory: false);
    await store.init();
    return store;
  } catch (error, stack) {
    debugPrint('Sqlite init failed, falling back to memory store: $error\n$stack');
    final store = MemoryCrmStore();
    await store.init();
    return store;
  }
}
