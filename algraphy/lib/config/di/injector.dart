import 'package:algraphy/modules/auth/data/repositories/mock_data_repository.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> setup() async {
  // Register the Mock Repository
  // We use registerSingleton so the state persists in memory during the session
  getIt.registerSingleton<MockAuthRepository>(MockAuthRepository());
}