import 'package:algraphy/core/local/local_db_service.dart';
import 'package:algraphy/modules/auth/data/local_user_repository.dart';
import 'package:algraphy/modules/employees/data/repository/employee_repository_imp.dart';
import 'package:algraphy/modules/employees/domain/repository/employee_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  // Networking

   // Register LocalDbService
  getIt.registerLazySingleton<LocalDbService>(() => LocalDbService());

  // Now register LocalUserRepository with injected db
  getIt.registerLazySingleton<LocalUserRepository>(
      () => LocalUserRepository(getIt<LocalDbService>()));
//getIt.registerLazySingleton<LocalUserRepository>(()=> LocalUserRepository());
  getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(
        baseUrl: "https://api.yourcompany.com",
      )));

  getIt.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepositoryImpl(getIt<Dio>()),
  );
}