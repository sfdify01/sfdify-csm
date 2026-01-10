import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/features/home/data/models/home_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<HomeModel>> getHomeData();
}

@Injectable(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl();

  @override
  Future<List<HomeModel>> getHomeData() async {
    // Simulated API response - replace with actual API call
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return const [
      HomeModel(
        title: 'Welcome to SFDIFY SCM',
        description: 'Your supply chain management solution',
      ),
      HomeModel(
        title: 'Dashboard',
        description: 'View your analytics and metrics',
      ),
      HomeModel(
        title: 'Inventory',
        description: 'Manage your inventory efficiently',
      ),
    ];
  }
}
