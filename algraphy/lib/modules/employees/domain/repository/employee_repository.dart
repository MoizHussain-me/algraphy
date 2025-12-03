import 'package:algraphy/modules/employees/data/models/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> fetchEmployees();
}
