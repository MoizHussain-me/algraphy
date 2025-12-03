import 'package:algraphy/modules/employees/domain/repository/employee_repository.dart';
import 'package:dio/dio.dart';

import '../models/employee.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final Dio _dio;

  EmployeeRepositoryImpl(this._dio);

  @override
  Future<List<Employee>> fetchEmployees() async {
    final response = await _dio.get('/employees');
    return (response.data as List)
        .map((e) => Employee.fromJson(e))
        .toList();
  }
}
