import 'package:flutter/material.dart';

import 'app.dart';
import 'data/flow_store.dart';

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
  runApp(FlowApp(store: store ?? MemoryFlowStore()));
}
