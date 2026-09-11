import 'package:flutter/material.dart';

import 'core/di/injector.dart';
import 'features/app/presentation/pages/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppRoot(injector: await Injector.create()));
}
