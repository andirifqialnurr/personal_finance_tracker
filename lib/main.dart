import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/flow_store.dart';
import 'state/state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlowStore? store;
  try {
    store = await SqliteFlowStore.open();
  } catch (error, stackTrace) {
    debugPrint(
      'SQLite is unavailable; using in-memory Flow data: $error\n$stackTrace',
    );
  }
  runApp(
    ProviderScope(
      overrides: [
        flowStoreProvider.overrideWithValue(store ?? MemoryFlowStore()),
      ],
      child: const FlowApp(),
    ),
  );
}
