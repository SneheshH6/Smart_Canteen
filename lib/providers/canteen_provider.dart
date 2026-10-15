import 'dart:async';
import 'package:flutter/material.dart';
import '../models/canteen_schedule_model.dart';
import '../services/firestore_service.dart';

class CanteenProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  CanteenScheduleModel _schedule = CanteenScheduleModel.defaultSchedule();
  StreamSubscription<CanteenScheduleModel>? _scheduleSubscription;
  Timer? _periodicTimer;
  bool _isInitialized = false;

  CanteenScheduleModel get schedule => _schedule;
  bool get isInitialized => _isInitialized;

  /// Live boolean indicating whether canteen is open right now in IST
  bool get isCanteenOpen => _schedule.isCanteenOpen;

  /// Live user-facing message, e.g.
  /// "Canteen is currently closed. Ordering will reopen tomorrow at 8:00 AM."
  String get statusMessage => _schedule.statusMessage;

  /// Notice message shown ONLY when the canteen is closed
  String get closedNoticeMessage => _schedule.closedNoticeMessage;

  String get openTimeFormatted => _schedule.openTimeFormatted;
  String get closeTimeFormatted => _schedule.closeTimeFormatted;
  DateTime get currentIst => CanteenScheduleModel.nowIst;

  CanteenProvider() {
    _init();
  }

  void _init() {
    // 1. Listen to live schedule updates from Firestore
    _scheduleSubscription = _firestoreService.getCanteenScheduleStream().listen(
      (updatedSchedule) {
        _schedule = updatedSchedule;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('CanteenProvider schedule stream error: $err');
      },
    );

    // 2. Periodic timer checking every 15 seconds to trigger automatic
    // opening at 8:00 AM and closing at 5:30 PM in IST automatically
    _periodicTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // Re-evaluate current open/closed status
      notifyListeners();
    });
  }

  Future<bool> updateSchedule({
    required int openHour,
    required int openMinute,
    required int closeHour,
    required int closeMinute,
    bool isAutomatic = true,
    bool isManualForceClosed = false,
    bool isManualForceOpen = false,
    String? adminName,
  }) async {
    final newSchedule = _schedule.copyWith(
      openHour: openHour,
      openMinute: openMinute,
      closeHour: closeHour,
      closeMinute: closeMinute,
      isAutomatic: isAutomatic,
      isManualForceClosed: isManualForceClosed,
      isManualForceOpen: isManualForceOpen,
      updatedAt: DateTime.now(),
      updatedBy: adminName ?? 'Admin',
    );

    final success = await _firestoreService.updateCanteenSchedule(newSchedule);
    if (success) {
      _schedule = newSchedule;
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
