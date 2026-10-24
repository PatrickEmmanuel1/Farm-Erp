class FarmUser {
  const FarmUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.profileId,
    this.farmId,
    this.phoneNumber,
    this.farm,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? profileId;
  final String? farmId;
  final String? phoneNumber;
  final FarmSummary? farm;

  bool get needsFarmSetup => role.toLowerCase() == 'manager' && farm == null;

  FarmUser withFarm(FarmSummary farm) {
    return copyWith(farm: farm, farmId: farm.id);
  }

  FarmUser copyWith({
    String? fullName,
    String? phoneNumber,
    bool clearPhoneNumber = false,
    FarmSummary? farm,
    String? farmId,
  }) {
    return FarmUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      profileId: profileId,
      farmId: farmId ?? this.farmId,
      phoneNumber: clearPhoneNumber ? null : phoneNumber ?? this.phoneNumber,
      farm: farm ?? this.farm,
    );
  }
}

class FarmSummary {
  const FarmSummary({
    required this.id,
    required this.name,
    required this.county,
    required this.size,
    required this.unit,
  });

  final String id;
  final String name;
  final String county;
  final double size;
  final String unit;
}
