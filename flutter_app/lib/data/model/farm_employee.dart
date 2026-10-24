class FarmEmployee {
  const FarmEmployee({
    required this.profileId,
    required this.accountId,
    required this.fullName,
    required this.role,
    this.employeeNumber,
    this.email,
    this.phoneNumber,
  });

  final String profileId;
  final String accountId;
  final String fullName;
  final String role;
  final String? employeeNumber;
  final String? email;
  final String? phoneNumber;
}
