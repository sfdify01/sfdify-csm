import 'package:sfdify_scm/app.dart';
import 'package:sfdify_scm/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
