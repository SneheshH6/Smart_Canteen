import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/canteen_schedule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../widgets/app_button.dart';

class AdminCanteenScheduleScreen extends StatefulWidget {
  const AdminCanteenScheduleScreen({super.key});

  @override
  State<AdminCanteenScheduleScreen> createState() => _AdminCanteenScheduleScreenState();
}

class _AdminCanteenScheduleScreenState extends State<AdminCanteenScheduleScreen> {
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 23, minute: 0);
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final canteen = Provider.of<CanteenProvider>(context);
      final s = canteen.schedule;
      _openTime = TimeOfDay(hour: s.openHour, minute: s.openMinute);
      _closeTime = TimeOfDay(hour: s.closeHour, minute: s.closeMinute);
      _isLoaded = true;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final dt = DateTime(2026, 1, 1, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _selectOpenTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _openTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _openTime = picked;
      });
    }
  }

  Future<void> _selectCloseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _closeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _closeTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canteen = Provider.of<CanteenProvider>(context, listen: false);

    final success = await canteen.updateSchedule(
      openHour: _openTime.hour,
      openMinute: _openTime.minute,
      closeHour: _closeTime.hour,
      closeMinute: _closeTime.minute,
      isAutomatic: true,
      isManualForceClosed: false,
      isManualForceOpen: false,
      adminName: auth.currentUser?.name ?? 'Admin',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      SnackbarUtils.showSuccess(
        context,
        'Canteen IST operating hours saved successfully (${_formatTimeOfDay(_openTime)} - ${_formatTimeOfDay(_closeTime)})',
      );
    } else {
      SnackbarUtils.showError(
        context,
        'Failed to save schedule. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canteen = Provider.of<CanteenProvider>(context);
    final isCurrentlyOpen = canteen.isCanteenOpen;
    final nowIst = CanteenScheduleModel.nowIst;
    final formattedCurrentIst = DateFormat('h:mm:ss a').format(nowIst);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B), // Deep Indigo
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Operating Hours & Schedule',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrentlyOpen
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.red.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCurrentlyOpen ? AppColors.primary : Colors.red)
                        .withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrentlyOpen
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCurrentlyOpen
                                  ? Icons.storefront_rounded
                                  : Icons.lock_clock_rounded,
                              color: isCurrentlyOpen
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCurrentlyOpen ? 'CANTEEN OPEN' : 'CANTEEN CLOSED',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isCurrentlyOpen
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Current IST: $formattedCurrentIst',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCurrentlyOpen
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCurrentlyOpen ? 'Active' : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isCurrentlyOpen
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  const SizedBox(height: 12),
                  Text(
                    canteen.statusMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Time Pickers Section
            const Text(
              'Automatic Daily Timings (IST)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ordering automatically enables at Opening Time and restricts at Closing Time every day.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Opening Time Card
            InkWell(
              onTap: _selectOpenTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Opening Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Students can place new orders from this time',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _formatTimeOfDay(_openTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Closing Time Card
            InkWell(
              onTap: _selectCloseTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Closing Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Checkout closes; menu remains view-only',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        _formatTimeOfDay(_closeTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Important Rules Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Automatic Schedule Rules',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• During closed hours, students can browse food items, photos, and prices, but checkout is disabled.\n'
                    '• Orders placed before closing continue through Kitchen preparation & delivery.\n'
                    '• Timings are synchronized and enforced in real-time across student and kitchen devices.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF14532D),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Schedule Button
            AppButton(
              text: 'Save Canteen Schedule',
              icon: Icons.save_rounded,
              isLoading: _isSaving,
              onPressed: _saveSchedule,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
