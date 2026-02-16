import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/auth_repository.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> setup() async {
  // We use registerSingleton so the state persists in memory during the session
  getIt.registerSingleton<AuthRepository>(AuthRepository());
  getIt.registerLazySingleton(() => AdminRepository());
  getIt.registerLazySingleton<EmployeeRepository>(() => EmployeeRepository());
  getIt.registerLazySingleton<TasksRepository>(() => TasksRepository());
}