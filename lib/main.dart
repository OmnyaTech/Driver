import 'package:flutter/widgets.dart';

import 'app.dart';
import 'config/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const OmnyaDriverApp());
}
