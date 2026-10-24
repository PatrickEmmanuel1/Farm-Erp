import 'model_parsing.dart';

class CreateEmployeeRequest {
  const CreateEmployeeRequest({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.employeeNumber,
    required this.farmId,
    this.password,
  });

  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? employeeNumber;
  final String farmId;
  final String? password;

  JsonRow toJson() => {
        'full_name': fullName,
        'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (employeeNumber != null) 'employee_number': employeeNumber,
        'farm_id': farmId,
        if (password != null) 'password': password,
      };
}

class EmployeeDisplay {
  const EmployeeDisplay({
    required this.profileId,
    this.accountId,
    this.farmId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.employeeNumber,
  });

  final String profileId;
  final String? accountId;
  final String? farmId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? employeeNumber;
}

class SupervisorDetails {
  const SupervisorDetails({
    required this.supervisorProfileId,
    required this.salary,
    required this.age,
    required this.residence,
    required this.dateEmployed,
    required this.gender,
  });

  final String supervisorProfileId;
  final double salary;
  final int age;
  final String residence;
  final String dateEmployed;
  final String gender;

  factory SupervisorDetails.fromJson(JsonRow json) => SupervisorDetails(
        supervisorProfileId: stringValue(json, 'supervisor_profile_id') ?? '',
        salary: doubleValue(json, 'salary') ?? 0,
        age: intValue(json, 'age') ?? 0,
        residence: stringValue(json, 'residence') ?? '',
        dateEmployed: stringValue(json, 'date_employed') ?? '',
        gender: stringValue(json, 'gender') ?? '',
      );

  JsonRow toJson() => {
        'supervisor_profile_id': supervisorProfileId,
        'salary': salary,
        'age': age,
        'residence': residence,
        'date_employed': dateEmployed,
        'gender': gender,
      };
}

class SupervisorDetailsInput {
  const SupervisorDetailsInput({
    required this.salary,
    required this.age,
    required this.residence,
    required this.dateEmployed,
    required this.gender,
  });

  final double salary;
  final int age;
  final String residence;
  final String dateEmployed;
  final String gender;

  JsonRow toJson(String supervisorProfileId) => {
        'supervisor_profile_id': supervisorProfileId,
        'salary': salary,
        'age': age,
        'residence': residence,
        'date_employed': dateEmployed,
        'gender': gender,
      };
}
