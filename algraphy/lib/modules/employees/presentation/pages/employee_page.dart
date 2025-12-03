import 'package:algraphy/config/di/injector.dart';
import 'package:algraphy/modules/employees/domain/repository/employee_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/employee_bloc.dart';
import '../bloc/employee_event.dart';
import '../bloc/employee_state.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmployeeBloc(
        getIt<EmployeeRepository>()
      )..add(LoadEmployees()),
      child: Scaffold(
        appBar: AppBar(title: const Text("Employees")),
        body: BlocBuilder<EmployeeBloc, EmployeeState>(
          builder: (context, state) {
            if (state is EmployeeLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is EmployeeLoaded) {
              return ListView.builder(
                itemCount: state.employees.length,
                itemBuilder: (context, index) {
                  final emp = state.employees[index];
                  return ListTile(
                    title: Text(emp.name),
                    subtitle: Text(emp.role),
                  );
                },
              );
            } else if (state is EmployeeError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
