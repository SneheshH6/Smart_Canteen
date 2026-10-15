import 'package:intl/intl.dart';

class CanteenScheduleModel {
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;
  final bool isAutomatic;
  final bool isManualForceClosed;
  final bool isManualForceOpen;
  final DateTime updatedAt;
  final String? updatedBy;

  const CanteenScheduleModel({
    this.openHour = 8,
    this.openMinute = 0,
    this.closeHour = 17,
    this.closeMinute = 30,
    this.isAutomatic = true,
    this.isManualForceClosed = false,
    this.isManualForceOpen = false,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Factory default schedule in IST: 6:00 AM - 11:00 PM IST (Enforced strictly by IST time)
  factory CanteenScheduleModel.defaultSchedule() {
    return CanteenScheduleModel(
      openHour: 6,
      openMinute: 0,
      closeHour: 23,
      closeMinute: 0,
      isAutomatic: true,
      isManualForceClosed: false,
      isManualForceOpen: false,
      updatedAt: DateTime.now(),
      updatedBy: 'System (IST Schedule)',
    );
  }

  /// Get current time in Indian Standard Time (IST: UTC + 5:30)
  static DateTime get nowIst {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Formatted Opening Time, e.g. "6:00 AM"
  String get openTimeFormatted {
    final dt = DateTime(2026, 1, 1, openHour, openMinute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Formatted Closing Time, e.g. "11:00 PM"
  String get closeTimeFormatted {
    final dt = DateTime(2026, 1, 1, closeHour, closeMinute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Check if Canteen is currently open strictly based on IST
  bool get isCanteenOpen {
    if (isManualForceOpen) return true;
    if (isManualForceClosed) return false;

    final ist = nowIst;
    final currentMinutes = ist.hour * 60 + ist.minute;
    final openMinutes = openHour * 60 + openMinute;
    final closeMinutes = closeHour * 60 + closeMinute;

    // Support overnight shifts where close time is on next morning (e.g. 10:00 PM to 6:00 AM)
    if (openMinutes > closeMinutes) {
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    }

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  /// User-friendly message explaining the current canteen ordering status
  String get statusMessage {
    if (isCanteenOpen) {
      return 'Canteen is open for orders until $closeTimeFormatted (IST).';
    }
    return closedNoticeMessage;
  }

  /// Message displayed strictly when the canteen is closed
  String get closedNoticeMessage {
    final ist = nowIst;
    final currentMinutes = ist.hour * 60 + ist.minute;
    final openMinutes = openHour * 60 + openMinute;

    if (currentMinutes < openMinutes) {
      return 'Canteen is currently closed. Ordering will open today at $openTimeFormatted (IST).';
    } else {
      return 'Canteen is currently closed. Ordering will reopen tomorrow at $openTimeFormatted (IST).';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'openHour': openHour,
      'openMinute': openMinute,
      'closeHour': closeHour,
      'closeMinute': closeMinute,
      'isAutomatic': isAutomatic,
      'isManualForceClosed': isManualForceClosed,
      'isManualForceOpen': isManualForceOpen,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory CanteenScheduleModel.fromMap(Map<String, dynamic> map) {
    return CanteenScheduleModel(
      openHour: map['openHour'] as int? ?? 8,
      openMinute: map['openMinute'] as int? ?? 0,
      closeHour: map['closeHour'] as int? ?? 17,
      closeMinute: map['closeMinute'] as int? ?? 30,
      isAutomatic: map['isAutomatic'] as bool? ?? true,
      isManualForceClosed: map['isManualForceClosed'] as bool? ?? false,
      isManualForceOpen: map['isManualForceOpen'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  CanteenScheduleModel copyWith({
    int? openHour,
    int? openMinute,
    int? closeHour,
    int? closeMinute,
    bool? isAutomatic,
    bool? isManualForceClosed,
    bool? isManualForceOpen,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return CanteenScheduleModel(
      openHour: openHour ?? this.openHour,
      openMinute: openMinute ?? this.openMinute,
      closeHour: closeHour ?? this.closeHour,
      closeMinute: closeMinute ?? this.closeMinute,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      isManualForceClosed: isManualForceClosed ?? this.isManualForceClosed,
      isManualForceOpen: isManualForceOpen ?? this.isManualForceOpen,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
