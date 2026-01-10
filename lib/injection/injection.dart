import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/injection/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();
