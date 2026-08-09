enum StreakPlatform {
  mobile('MOBILE'),
  web('WEB');

  const StreakPlatform(this.apiValue);

  final String apiValue;
}

class StreakActivityRequest {
  const StreakActivityRequest({required this.platform, this.timezone});

  final StreakPlatform platform;
  final String? timezone;

  Map<String, dynamic> toJson() {
    final String? normalizedTimezone = _blankAsNull(timezone);
    return <String, dynamic>{
      'platform': platform.apiValue,
      if (normalizedTimezone != null) 'timezone': normalizedTimezone,
    };
  }
}

class UserStreaksModel {
  const UserStreaksModel({
    required this.mobile,
    required this.web,
    required this.shared,
  });

  final UserStreakScopeModel mobile;
  final UserStreakScopeModel web;
  final UserStreakScopeModel shared;

  factory UserStreaksModel.empty() {
    return UserStreaksModel(
      mobile: UserStreakScopeModel.empty(),
      web: UserStreakScopeModel.empty(),
      shared: UserStreakScopeModel.empty(),
    );
  }

  factory UserStreaksModel.fromJson(Map<String, dynamic> json) {
    return UserStreaksModel(
      mobile: UserStreakScopeModel.fromJson(_mapOrEmpty(json['mobile'])),
      web: UserStreakScopeModel.fromJson(_mapOrEmpty(json['web'])),
      shared: UserStreakScopeModel.fromJson(_mapOrEmpty(json['shared'])),
    );
  }
}

class UserStreakScopeModel {
  const UserStreakScopeModel({
    required this.currentDays,
    required this.longestDays,
    required this.activeToday,
    this.lastActivityDay,
  });

  final int currentDays;
  final int longestDays;
  final bool activeToday;
  final DateTime? lastActivityDay;

  factory UserStreakScopeModel.empty() {
    return const UserStreakScopeModel(
      currentDays: 0,
      longestDays: 0,
      activeToday: false,
    );
  }

  factory UserStreakScopeModel.fromJson(Map<String, dynamic> json) {
    return UserStreakScopeModel(
      currentDays: _intValue(json['currentDays']),
      longestDays: _intValue(json['longestDays']),
      activeToday: json['activeToday'] == true,
      lastActivityDay: _dateValue(json['lastActivityDay']),
    );
  }
}

Map<String, dynamic> _mapOrEmpty(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }
  return const <String, dynamic>{};
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(Object? value) {
  final String? normalized = _blankAsNull(value?.toString());
  if (normalized == null) {
    return null;
  }
  return DateTime.tryParse(normalized);
}

String? _blankAsNull(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}
