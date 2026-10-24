import 'model_parsing.dart';

class FarmAccount {
  const FarmAccount({
    required this.accountId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  final String accountId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? role;
  final String? createdAt;
  final String? updatedAt;

  factory FarmAccount.fromJson(JsonRow json) => FarmAccount(
        accountId: stringValue(json, 'account_id') ?? '',
        fullName: stringValue(json, 'full_name') ?? '',
        email: stringValue(json, 'email') ?? '',
        phoneNumber: stringValue(json, 'phone_number'),
        role: stringValue(json, 'role'),
        createdAt: stringValue(json, 'created_at'),
        updatedAt: stringValue(json, 'updated_at'),
      );

  JsonRow toJson() => {
        'account_id': accountId,
        'full_name': fullName,
        'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (role != null) 'role': role,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class EmployeeProfile {
  const EmployeeProfile({
    required this.profileId,
    required this.accountId,
    required this.farmId,
    this.employeeNumber,
    this.isDeleted = false,
  });

  final String profileId;
  final String accountId;
  final String farmId;
  final String? employeeNumber;
  final bool isDeleted;
}
