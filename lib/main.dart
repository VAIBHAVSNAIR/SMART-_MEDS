import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartMedsApp());
}

class AppColors {
  static const primary = Color(0xFF1F6BFF);
  static const primaryDark = Color(0xFF163CBA);
  static const primarySoft = Color(0xFFEAF1FF);
  static const background = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const shadow = Color(0x1A0F172A);
}

class SmartMedsApp extends StatelessWidget {
  const SmartMedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Meds',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          indicatorColor: AppColors.primarySoft,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const SmartMedsHome(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Medicine {
  String id;
  String name;
  String tablets;
  String time;
  String container;
  int stock;
  String status;
  String takenDate;
  String scheduleDate;
  String safetyEventId;

  Medicine({
    String? id,
    required this.name,
    required this.tablets,
    required this.time,
    this.container = 'Container 1',
    this.stock = 10,
    this.status = 'Pending',
    this.takenDate = '',
    this.scheduleDate = '',
    this.safetyEventId = '',
  }) : id = id ?? _newId();

  static String _newId() =>
      'med_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tablets': tablets,
        'time': time,
        'container': container,
        'stock': stock,
        'status': status,
        'takenDate': takenDate,
        'scheduleDate': scheduleDate,
        'safetyEventId': safetyEventId,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        tablets: json['tablets']?.toString() ?? '1',
        time: json['time']?.toString() ?? '',
        container: json['container']?.toString() ?? 'Container 1',
        stock: int.tryParse(json['stock']?.toString() ?? '') ?? 10,
        status: _normaliseStatus(json['status']?.toString() ?? 'Pending'),
        takenDate: json['takenDate']?.toString() ?? '',
        scheduleDate: json['scheduleDate']?.toString() ?? '',
        safetyEventId: json['safetyEventId']?.toString() ?? '',
      );

  static String _normaliseStatus(String value) {
    if (value.contains('Taken')) return 'Taken';
    if (value.contains('Missed')) return 'Missed';
    if (value.contains('Due')) return 'Due';
    if (value.contains('Invalid')) return 'Invalid Time';
    return 'Pending';
  }
}

class DispensingRecord {
  String eventId;
  String medicineId;
  String medicine;
  String container;
  String scheduledDateTime;
  String scheduledTime;
  String dispensedTime;
  int tablets;
  String status;
  int delayMinutes;
  bool alertTriggered;
  String alertSentAt;

  DispensingRecord({
    String? eventId,
    this.medicineId = '',
    required this.medicine,
    required this.container,
    required this.scheduledDateTime,
    required this.scheduledTime,
    required this.dispensedTime,
    required this.tablets,
    this.status = 'Taken',
    this.delayMinutes = 0,
    this.alertTriggered = false,
    this.alertSentAt = '',
  }) : eventId = eventId ?? _newId();

  static String _newId() =>
      'evt_${DateTime.now().microsecondsSinceEpoch}';

  bool get isTaken => status == 'Taken' || status == 'Taken Late';
  bool get isMissed => status == 'Missed';

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'medicineId': medicineId,
        'medicine': medicine,
        'container': container,
        'scheduledDateTime': scheduledDateTime,
        'scheduledTime': scheduledTime,
        'dispensedTime': dispensedTime,
        'tablets': tablets,
        'status': status,
        'delayMinutes': delayMinutes,
        'alertTriggered': alertTriggered,
        'alertSentAt': alertSentAt,
      };

  factory DispensingRecord.fromJson(Map<String, dynamic> json) {
    return DispensingRecord(
      eventId: json['eventId']?.toString(),
      medicineId: json['medicineId']?.toString() ?? '',
      medicine: json['medicine']?.toString() ?? 'Unknown medicine',
      container: json['container']?.toString() ?? 'Container 1',
      scheduledDateTime: json['scheduledDateTime']?.toString() ?? '',
      scheduledTime: json['scheduledTime']?.toString() ?? '',
      dispensedTime: json['dispensedTime']?.toString() ?? '',
      tablets: int.tryParse(json['tablets']?.toString() ?? '') ?? 1,
      status: _normaliseStatus(json['status']?.toString() ?? 'Taken'),
      delayMinutes: int.tryParse(json['delayMinutes']?.toString() ?? '') ?? 0,
      alertTriggered: json['alertTriggered'] == true,
      alertSentAt: json['alertSentAt']?.toString() ?? '',
    );
  }

  static String _normaliseStatus(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('miss')) return 'Missed';
    if (lower.contains('late')) return 'Taken Late';
    return 'Taken';
  }
}

class AppSettings {
  String patientName;
  String emergencyContactName;
  String emergencyPhone;
  String doctorEmail;
  String emailWebhookUrl;
  bool emergencyAlertsEnabled;
  bool smsEnabled;
  bool emailEnabled;
  bool dataConsent;
  bool sharingConsent;
  int alertDelayMinutes;

  AppSettings({
    this.patientName = 'Prototype Patient',
    this.emergencyContactName = 'Emergency Contact',
    this.emergencyPhone = '',
    this.doctorEmail = '',
    this.emailWebhookUrl = '',
    this.emergencyAlertsEnabled = false,
    this.smsEnabled = true,
    this.emailEnabled = false,
    this.dataConsent = false,
    this.sharingConsent = false,
    this.alertDelayMinutes = 45,
  });

  Map<String, dynamic> toJson() => {
        'patientName': patientName,
        'emergencyContactName': emergencyContactName,
        'emergencyPhone': emergencyPhone,
        'doctorEmail': doctorEmail,
        'emailWebhookUrl': emailWebhookUrl,
        'emergencyAlertsEnabled': emergencyAlertsEnabled,
        'smsEnabled': smsEnabled,
        'emailEnabled': emailEnabled,
        'dataConsent': dataConsent,
        'sharingConsent': sharingConsent,
        'alertDelayMinutes': alertDelayMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        patientName: json['patientName']?.toString() ?? 'Prototype Patient',
        emergencyContactName:
            json['emergencyContactName']?.toString() ?? 'Emergency Contact',
        emergencyPhone: json['emergencyPhone']?.toString() ?? '',
        doctorEmail: json['doctorEmail']?.toString() ?? '',
        emailWebhookUrl: json['emailWebhookUrl']?.toString() ?? '',
        emergencyAlertsEnabled: json['emergencyAlertsEnabled'] == true,
        smsEnabled: json['smsEnabled'] != false,
        emailEnabled: json['emailEnabled'] == true,
        dataConsent: json['dataConsent'] == true,
        sharingConsent: json['sharingConsent'] == true,
        alertDelayMinutes:
            int.tryParse(json['alertDelayMinutes']?.toString() ?? '') ?? 45,
      );
}

// ============================================================
// NATIVE ANDROID BRIDGE
// ============================================================

class NativeSafetyBridge {
  static const _channel = MethodChannel('smart_meds/safety');

  static Future<bool> smsPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isSmsPermissionGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestSmsPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestSmsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSms(String phone, String message) async {
    try {
      return await _channel.invokeMethod<bool>('sendSms', {
            'phone': phone,
            'message': message,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> scheduleEmergencyAlarm({
    required String eventId,
    required int triggerAtMillis,
    required String phone,
    required String message,
    required String emailWebhookUrl,
    required String doctorEmail,
    required bool emailEnabled,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('scheduleEmergencyAlarm', {
            'eventId': eventId,
            'triggerAtMillis': triggerAtMillis,
            'phone': phone,
            'message': message,
            'emailWebhookUrl': emailWebhookUrl,
            'doctorEmail': doctorEmail,
            'emailEnabled': emailEnabled,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelEmergencyAlarm(String eventId) async {
    try {
      return await _channel.invokeMethod<bool>('cancelEmergencyAlarm', {
        'eventId': eventId,
      }) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> safetyAlertAlreadyFired(String eventId) async {
    try {
      return await _channel.invokeMethod<bool>('isSafetyFired', {
        'eventId': eventId,
      }) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canScheduleExactAlarm() async {
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarm') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {}
  }
}

// ============================================================
// ANALYTICS ENGINE
// ============================================================

class SmartMedsAnalytics {
  final List<DispensingRecord> records;
  SmartMedsAnalytics(this.records);

  List<DispensingRecord> inRange(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records.where((record) {
      final date = DateTime.tryParse(record.scheduledDateTime);
      return date != null && !date.isBefore(cutoff);
    }).toList();
  }

  int takenCount(int days) => inRange(days).where((r) => r.isTaken).length;
  int missedCount(int days) => inRange(days).where((r) => r.isMissed).length;

  double adherencePercent(int days) {
    final total = takenCount(days) + missedCount(days);
    if (total == 0) return 0;
    return takenCount(days) * 100 / total;
  }

  double averageLateMinutes(int days) {
    final late = inRange(days)
        .where((r) => r.isTaken && r.delayMinutes > 0)
        .toList();
    if (late.isEmpty) return 0;
    final total = late.fold<int>(0, (sum, r) => sum + r.delayMinutes);
    return total / late.length;
  }

  double morningAverageDelay(int days) {
    final morning = inRange(days).where((r) {
      final dt = parseScheduled(r);
      return dt != null && dt.hour < 12 && r.isTaken;
    }).toList();
    if (morning.isEmpty) return 0;
    final total = morning.fold<int>(0, (sum, r) => sum + r.delayMinutes);
    return total / morning.length;
  }

  double missRateForWeekday(int weekday, int days) {
    final list = inRange(days).where((r) {
      final dt = DateTime.tryParse(r.scheduledDateTime);
      return dt?.weekday == weekday;
    }).toList();
    if (list.isEmpty) return 0;
    return list.where((r) => r.isMissed).length * 100 / list.length;
  }

  String mostMissedDay(int days) {
    var bestDay = '';
    var bestRate = -1.0;
    for (var day = 1; day <= 7; day++) {
      final list = inRange(days).where((r) {
        final dt = DateTime.tryParse(r.scheduledDateTime);
        return dt?.weekday == day;
      }).toList();
      if (list.isEmpty) continue;
      final rate = list.where((r) => r.isMissed).length * 100 / list.length;
      if (rate > bestRate) {
        bestRate = rate;
        bestDay = dayName(day);
      }
    }
    return bestDay.isEmpty ? 'None' : bestDay;
  }

  String mostMissedMedicine(int days) {
    final counts = <String, int>{};
    for (final r in inRange(days)) {
      if (r.isMissed) counts[r.medicine] = (counts[r.medicine] ?? 0) + 1;
    }
    if (counts.isEmpty) return 'None';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String bestMedicine(int days) {
    final grouped = <String, List<DispensingRecord>>{};
    for (final r in inRange(days)) {
      grouped.putIfAbsent(r.medicine, () => []).add(r);
    }
    String best = 'None';
    var bestRate = -1.0;
    for (final entry in grouped.entries) {
      final total = entry.value.where((r) => r.isTaken || r.isMissed).length;
      if (total == 0) continue;
      final rate = entry.value.where((r) => r.isTaken).length * 100 / total;
      if (rate > bestRate) {
        bestRate = rate;
        best = entry.key;
      }
    }
    return best;
  }

  String adherenceLabel(int days) {
    final p = adherencePercent(days);
    if (p >= 90) return 'Excellent adherence';
    if (p >= 75) return 'Good adherence';
    if (p >= 50) return 'Needs attention';
    return 'High risk of missed doses';
  }

  static DateTime? parseScheduled(DispensingRecord record) {
    final date = DateTime.tryParse(record.scheduledDateTime);
    if (date == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$')
        .firstMatch(record.scheduledTime.trim().toUpperCase());
    if (match == null) return date;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final period = match.group(3)!;
    if (period == 'AM' && hour == 12) hour = 0;
    if (period == 'PM' && hour != 12) hour += 12;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String dayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}

// ============================================================
// STORE / ALL APP LOGIC
// ============================================================

class SmartMedsStore extends ChangeNotifier {
  static const medicinesKey = 'medicines';
  static const historyKey = 'dispensingHistory';
  static const settingsKey = 'smartMedsSettings';
  static const safetySchedulesKey = 'safetySchedules';

  List<Medicine> medicines = [];
  List<DispensingRecord> history = [];
  AppSettings settings = AppSettings();
  Timer? timer;
  bool loading = true;

  SmartMedsAnalytics get analytics => SmartMedsAnalytics(history);

  Future<void> initialize() async {
    await loadAll();
    await updateStatuses(save: false);
    await syncSafetyAlarms();
    loading = false;
    notifyListeners();
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await updateStatuses();
      await autoDispenseDueMedicines();
    });
    // Catch a dose that becomes due just after the app opens.
    await autoDispenseDueMedicines();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(medicinesKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          medicines = data
              .map((e) => Medicine.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final raw = prefs.getString(historyKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          history = data
              .map((e) => DispensingRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final raw = prefs.getString(settingsKey);
      if (raw != null && raw.isNotEmpty) {
        settings = AppSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw)),
        );
      }
    } catch (_) {}

    if (medicines.isEmpty) {
      final today = dateOnly(DateTime.now());
      medicines = [
        Medicine(
          name: 'Paracetamol',
          tablets: '1',
          time: '8:00 AM',
          container: 'Container 1',
          scheduleDate: today,
        ),
        Medicine(
          name: 'Vitamin D',
          tablets: '1',
          time: '1:00 PM',
          container: 'Container 2',
          scheduleDate: today,
        ),
        Medicine(
          name: 'BP Tablet',
          tablets: '1',
          time: '8:00 PM',
          container: 'Container 3',
          scheduleDate: today,
        ),
      ];
      await saveMedicines();
    }
  }

  Future<void> saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      medicinesKey,
      jsonEncode(medicines.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  static String dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String today() => dateOnly(DateTime.now());

  DateTime? parseSchedule(String time, String date) {
    final base = DateTime.tryParse(date);
    if (base == null) return null;
    final value = time.trim().toUpperCase();
    final twelve = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$')
        .firstMatch(value);
    if (twelve != null) {
      var hour = int.parse(twelve.group(1)!);
      final minute = int.parse(twelve.group(2)!);
      if (hour < 1 || hour > 12 || minute > 59) return null;
      if (twelve.group(3) == 'AM' && hour == 12) hour = 0;
      if (twelve.group(3) == 'PM' && hour != 12) hour += 12;
      return DateTime(base.year, base.month, base.day, hour, minute);
    }
    final twentyFour = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (twentyFour != null) {
      final hour = int.parse(twentyFour.group(1)!);
      final minute = int.parse(twentyFour.group(2)!);
      if (hour > 23 || minute > 59) return null;
      return DateTime(base.year, base.month, base.day, hour, minute);
    }
    return null;
  }

  String buildEventId(Medicine medicine, String scheduleDate) {
    final compactTime = medicine.time.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return '${medicine.id}_${scheduleDate}_$compactTime';
  }

  Future<void> updateStatuses({bool save = true}) async {
    if (medicines.isEmpty) return;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    var changed = false;

    for (final medicine in medicines) {
      if (medicine.scheduleDate.isEmpty) {
        medicine.scheduleDate = today();
        changed = true;
      }

      var scheduled = parseSchedule(medicine.time, medicine.scheduleDate);
      if (scheduled == null) {
        medicine.status = 'Invalid Time';
        changed = true;
        continue;
      }

      final scheduleDay = DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day,
      );

      if (scheduleDay.isBefore(todayDate)) {
        var cursor = scheduleDay;
        while (cursor.isBefore(todayDate)) {
          final oldDate = dateOnly(cursor);
          final oldSchedule = parseSchedule(medicine.time, oldDate);
          if (oldSchedule != null) {
            final oldEventId = buildEventId(medicine, oldDate);
            final exists = history.any((r) => r.eventId == oldEventId);
            if (!exists) {
              addMissedRecord(medicine, oldSchedule, oldEventId);
              changed = true;
            }
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        medicine.scheduleDate = today();
        medicine.takenDate = '';
        medicine.safetyEventId = '';
        scheduled = parseSchedule(medicine.time, medicine.scheduleDate);
        changed = true;
      }

      if (medicine.takenDate == today()) {
        medicine.status = 'Taken';
        continue;
      }

      if (scheduled == null) continue;
      if (now.isBefore(scheduled)) {
        if (medicine.status != 'Pending') {
          medicine.status = 'Pending';
          changed = true;
        }
      } else {
        final elapsed = now.difference(scheduled);
        if (elapsed.inMinutes < 30) {
          if (medicine.status != 'Due') {
            medicine.status = 'Due';
            changed = true;
          }
        } else if (medicine.status != 'Missed') {
          medicine.status = 'Missed';
          final eventId = buildEventId(medicine, medicine.scheduleDate);
          if (!history.any((r) => r.eventId == eventId)) {
            addMissedRecord(medicine, scheduled, eventId);
          }
          changed = true;
        }
      }

      if (medicine.status == 'Missed') {
        final eventId = buildEventId(medicine, medicine.scheduleDate);
        if (await NativeSafetyBridge.safetyAlertAlreadyFired(eventId)) {
          final index = history.indexWhere((r) => r.eventId == eventId);
          if (index >= 0 && !history[index].alertTriggered) {
            history[index].alertTriggered = true;
            history[index].alertSentAt = DateTime.now().toIso8601String();
            changed = true;
          }
        }
      }
    }

    if (changed) {
      if (save) {
        await saveMedicines();
        await saveHistory();
      }
      notifyListeners();
    }
    await syncSafetyAlarms();
  }

  // DEMO MODE: automatically records a simulated dispense while this app is open.
  // This does not move a physical servo or confirm a real tablet was released.
  Future<void> autoDispenseDueMedicines() async {
    final now = DateTime.now();
    for (var i = 0; i < medicines.length; i++) {
      final medicine = medicines[i];
      if (medicine.status == 'Taken' || medicine.status == 'Missed') continue;
      if (medicine.stock <= 0) continue;

      final schedule = parseSchedule(
        medicine.time,
        medicine.scheduleDate.isEmpty ? today() : medicine.scheduleDate,
      );
      if (schedule == null || now.isBefore(schedule)) continue;

      // Only auto-process within the existing 30-minute due window.
      if (now.difference(schedule).inMinutes >= 30) continue;

      try {
        await markTaken(i, dispense: true);
      } catch (_) {
        // Leave the dose due if the stock or schedule is invalid.
      }
    }
  }

  void addMissedRecord(Medicine medicine, DateTime schedule, String eventId) {
    history.insert(
      0,
      DispensingRecord(
        eventId: eventId,
        medicineId: medicine.id,
        medicine: medicine.name,
        container: medicine.container,
        scheduledDateTime: schedule.toIso8601String(),
        scheduledTime: medicine.time,
        dispensedTime: '',
        tablets: int.tryParse(medicine.tablets) ?? 1,
        status: 'Missed',
      ),
    );
    if (history.length > 1000) history = history.take(1000).toList();
  }

  Future<void> addMedicine(Medicine medicine) async {
    final now = DateTime.now();
    final todaySchedule = parseSchedule(medicine.time, today());
    final tomorrow = dateOnly(now.add(const Duration(days: 1)));
    medicine.scheduleDate =
        todaySchedule != null && todaySchedule.isAfter(now)
            ? today()
            : tomorrow;
    medicine.status = 'Pending';
    medicine.takenDate = '';
    medicine.safetyEventId = '';
    medicines.add(medicine);
    await saveMedicines();
    await updateStatuses();
  }

  Future<void> _cancelSafetySchedulesForMedicine(Medicine medicine) async {
    final previous = await _readSafetySchedules();
    for (final item in previous) {
      final medicineId = item['medicineId']?.toString() ?? '';
      final eventId = item['eventId']?.toString() ?? '';
      if (eventId.isNotEmpty && medicineId == medicine.id) {
        await NativeSafetyBridge.cancelEmergencyAlarm(eventId);
      }
    }
    if (medicine.safetyEventId.isNotEmpty) {
      await NativeSafetyBridge.cancelEmergencyAlarm(medicine.safetyEventId);
    }
  }

  Future<void> editMedicine(int index, Medicine medicine) async {
    if (index < 0 || index >= medicines.length) return;
    final old = medicines[index];
    await _cancelSafetySchedulesForMedicine(old);

    final now = DateTime.now();
    final todaySchedule = parseSchedule(medicine.time, today());
    medicine.scheduleDate =
        todaySchedule != null && todaySchedule.isAfter(now)
            ? today()
            : dateOnly(now.add(const Duration(days: 1)));
    medicine.status = 'Pending';
    medicine.takenDate = '';
    medicine.safetyEventId = '';
    medicines[index] = medicine;
    await saveMedicines();
    await updateStatuses();
  }

  Future<void> removeMedicine(int index) async {
    if (index < 0 || index >= medicines.length) return;
    final old = medicines[index];
    await _cancelSafetySchedulesForMedicine(old);
    medicines.removeAt(index);
    await saveMedicines();
    await syncSafetyAlarms();
    notifyListeners();
  }

  Future<void> markTaken(int index, {required bool dispense}) async {
    if (index < 0 || index >= medicines.length) return;
    final medicine = medicines[index];
    final schedule = parseSchedule(
      medicine.time,
      medicine.scheduleDate.isEmpty ? today() : medicine.scheduleDate,
    );
    if (schedule == null) throw StateError('This medicine has an invalid time.');

    final dose = int.tryParse(medicine.tablets) ?? 1;
    if (dose <= 0) throw StateError('Dose quantity is invalid.');
    if (dispense && medicine.stock < dose) {
      throw StateError(
        'Not enough ${medicine.name} in ${medicine.container}. Only ${medicine.stock} tablet(s) remain.',
      );
    }

    await _cancelSafetySchedulesForMedicine(medicine);
    if (dispense) medicine.stock -= dose;
    final now = DateTime.now();
    final delay = now.isAfter(schedule) ? now.difference(schedule).inMinutes : 0;
    final eventId = buildEventId(medicine, medicine.scheduleDate);
    final existing = history.indexWhere((r) => r.eventId == eventId);

    if (existing >= 0) {
      final record = history[existing];
      record.dispensedTime = timeNowText();
      record.delayMinutes = delay;
      record.status = delay > 5 ? 'Taken Late' : 'Taken';
      record.alertTriggered = false;
      record.alertSentAt = '';
      record.tablets = dose;
    } else {
      history.insert(
        0,
        DispensingRecord(
          eventId: eventId,
          medicineId: medicine.id,
          medicine: medicine.name,
          container: medicine.container,
          scheduledDateTime: schedule.toIso8601String(),
          scheduledTime: medicine.time,
          dispensedTime: timeNowText(),
          tablets: dose,
          status: delay > 5 ? 'Taken Late' : 'Taken',
          delayMinutes: delay,
        ),
      );
    }

    medicine.status = 'Taken';
    medicine.takenDate = today();
    medicine.scheduleDate = dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    medicine.safetyEventId = '';

    await saveMedicines();
    await saveHistory();
    await syncSafetyAlarms();
    notifyListeners();
  }

  Future<void> registerPickup(int index) => markTaken(index, dispense: false);

  String timeNowText() {
    var hour = DateTime.now().hour;
    final minute = DateTime.now().minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour %= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  String emergencyMessage(Medicine medicine, DateTime scheduled) {
    return 'SMART MEDS SAFETY ALERT\n'
        'Patient: ${settings.patientName}\n'
        'Medicine: ${medicine.name}\n'
        'Container: ${medicine.container}\n'
        'Scheduled: ${formatDateTime(scheduled)}\n'
        'Pickup not detected within ${settings.alertDelayMinutes} minutes.\n'
        'Please check on the patient.';
  }

  Future<void> syncSafetyAlarms() async {
    final schedules = <Map<String, dynamic>>[];
    final previous = await _readSafetySchedules();
    final previousById = <String, Map<String, dynamic>>{
      for (final item in previous)
        if (item['eventId'] != null) item['eventId'].toString(): item,
    };

    if (!settings.emergencyAlertsEnabled) {
      for (final item in previous) {
        final id = item['eventId']?.toString() ?? '';
        if (id.isNotEmpty) {
          await NativeSafetyBridge.cancelEmergencyAlarm(id);
        }
      }
      for (final medicine in medicines) {
        medicine.safetyEventId = '';
      }
      await _saveSafetySchedules(const []);
      await saveMedicines();
      return;
    }

    final now = DateTime.now();

    for (final medicine in medicines) {
      final baseDate = DateTime.tryParse(
        medicine.scheduleDate.isEmpty ? today() : medicine.scheduleDate,
      );
      if (baseDate == null) continue;

      medicine.safetyEventId = '';
      final candidateDates = <DateTime>[
        DateTime(baseDate.year, baseDate.month, baseDate.day),
        DateTime(baseDate.year, baseDate.month, baseDate.day + 1),
      ];

      for (final scheduledDate in candidateDates) {
        final dateString = dateOnly(scheduledDate);
        final schedule = parseSchedule(medicine.time, dateString);
        if (schedule == null) continue;

        if (schedule.isBefore(now.subtract(const Duration(minutes: 1))) &&
            dateString != today()) {
          continue;
        }

        if (medicine.takenDate == dateString) {
          continue;
        }

        final eventId = buildEventId(medicine, dateString);
        final fired = await NativeSafetyBridge.safetyAlertAlreadyFired(eventId);
        if (fired) continue;

        final target = schedule.add(
          Duration(minutes: settings.alertDelayMinutes),
        );
        final trigger = target.isAfter(now)
            ? target
            : now.add(const Duration(seconds: 2));
        final phone = settings.smsEnabled
            ? settings.emergencyPhone.trim()
            : '';
        final webhook = settings.emailEnabled
            ? settings.emailWebhookUrl.trim()
            : '';
        final emailEnabled = settings.emailEnabled && webhook.isNotEmpty;
        final message = emergencyMessage(medicine, schedule);

        final payload = <String, dynamic>{
          'eventId': eventId,
          'medicineId': medicine.id,
          'triggerAtMillis': trigger.millisecondsSinceEpoch,
          'phone': phone,
          'message': message,
          'emailWebhookUrl': webhook,
          'doctorEmail': settings.doctorEmail.trim(),
          'emailEnabled': emailEnabled,
        };

        final previousItem = previousById[eventId];
        final unchanged = previousItem != null &&
            previousItem['triggerAtMillis']?.toString() ==
                trigger.millisecondsSinceEpoch.toString() &&
            previousItem['phone']?.toString() == phone &&
            previousItem['message']?.toString() == message &&
            previousItem['emailWebhookUrl']?.toString() == webhook &&
            previousItem['doctorEmail']?.toString() ==
                settings.doctorEmail.trim() &&
            previousItem['emailEnabled'] == emailEnabled;

        if (!unchanged) {
          await NativeSafetyBridge.scheduleEmergencyAlarm(
            eventId: eventId,
            triggerAtMillis: trigger.millisecondsSinceEpoch,
            phone: phone,
            message: message,
            emailWebhookUrl: webhook,
            doctorEmail: settings.doctorEmail.trim(),
            emailEnabled: emailEnabled,
          );
        }

        schedules.add(payload);
        if (medicine.safetyEventId.isEmpty) {
          medicine.safetyEventId = eventId;
        }
      }
    }

    final newIds = schedules.map((e) => e['eventId'].toString()).toSet();
    for (final item in previous) {
      final oldId = item['eventId']?.toString() ?? '';
      if (oldId.isNotEmpty && !newIds.contains(oldId)) {
        await NativeSafetyBridge.cancelEmergencyAlarm(oldId);
      }
    }

    await saveMedicines();
    await _saveSafetySchedules(schedules);
  }

  Future<List<Map<String, dynamic>>> _readSafetySchedules() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(safetySchedulesKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSafetySchedules(List<Map<String, dynamic>> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(safetySchedulesKey, jsonEncode(schedules));
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await saveSettings();
    await syncSafetyAlarms();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    await saveHistory();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final previous = await _readSafetySchedules();
    for (final item in previous) {
      final id = item['eventId']?.toString() ?? '';
      if (id.isNotEmpty) {
        await NativeSafetyBridge.cancelEmergencyAlarm(id);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(medicinesKey);
    await prefs.remove(historyKey);
    await prefs.remove(settingsKey);
    await prefs.remove(safetySchedulesKey);
    medicines = [];
    history = [];
    settings = AppSettings();
    notifyListeners();
  }

  Future<void> testSms() async {
    if (settings.emergencyPhone.trim().isEmpty) {
      throw StateError('Enter the prototype phone number first.');
    }
    var permission = await NativeSafetyBridge.smsPermissionGranted();
    if (!permission) {
      await NativeSafetyBridge.requestSmsPermission();
      permission = await NativeSafetyBridge.smsPermissionGranted();
    }
    if (!permission) throw StateError('SMS permission was not granted.');
    final sent = await NativeSafetyBridge.sendSms(
      settings.emergencyPhone.trim(),
      'SMART MEDS TEST ALERT\nAutomatic SMS channel is working.',
    );
    if (!sent) throw StateError('The phone could not send the test SMS.');
  }

  Future<void> testEmergencyProtocol() async {
    if (settings.emergencyPhone.trim().isEmpty) {
      throw StateError('Enter the prototype phone number first.');
    }
    var permission = await NativeSafetyBridge.smsPermissionGranted();
    if (!permission) {
      await NativeSafetyBridge.requestSmsPermission();
      permission = await NativeSafetyBridge.smsPermissionGranted();
    }
    if (!permission) throw StateError('SMS permission was not granted.');

    final id = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final ok = await NativeSafetyBridge.scheduleEmergencyAlarm(
      eventId: id,
      triggerAtMillis:
          DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      phone: settings.emergencyPhone.trim(),
      message: 'SMART MEDS EMERGENCY TEST\n'
          'This is an automatic 45-minute no-pickup safety-alert simulation.',
      emailWebhookUrl: '',
      doctorEmail: '',
      emailEnabled: false,
    );
    if (!ok) throw StateError('Could not schedule the emergency test alarm.');
  }

  Future<void> loadDefaultIfNeeded() async {
    if (medicines.isNotEmpty) return;
    final today = this.today();
    medicines = [
      Medicine(
        name: 'Paracetamol',
        tablets: '1',
        time: '8:00 AM',
        container: 'Container 1',
        scheduleDate: today,
      ),
      Medicine(
        name: 'Vitamin D',
        tablets: '1',
        time: '1:00 PM',
        container: 'Container 2',
        scheduleDate: today,
      ),
      Medicine(
        name: 'BP Tablet',
        tablets: '1',
        time: '8:00 PM',
        container: 'Container 3',
        scheduleDate: today,
      ),
    ];
    await saveMedicines();
  }

  static String formatDateTime(DateTime d) {
    var hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour %= 12;
    if (hour == 0) hour = 12;
    return '${d.day}/${d.month}/${d.year} $hour:$minute $period';
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Taken':
        return AppColors.success;
      case 'Taken Late':
        return AppColors.warning;
      case 'Due':
        return AppColors.info;
      case 'Missed':
      case 'Invalid Time':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  String displayStatus(String status) {
    switch (status) {
      case 'Due':
        return 'Due now';
      case 'Pending':
        return 'Upcoming';
      default:
        return status;
    }
  }
}

// ============================================================
// ROOT NAVIGATION
// ============================================================

class SmartMedsHome extends StatefulWidget {
  const SmartMedsHome({super.key});

  @override
  State<SmartMedsHome> createState() => _SmartMedsHomeState();
}

class _SmartMedsHomeState extends State<SmartMedsHome> {
  final SmartMedsStore store = SmartMedsStore();
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    store.initialize();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  String get title {
    switch (selectedIndex) {
      case 1:
        return 'Adherence';
      case 2:
        return 'Reports';
      case 3:
        return 'Settings';
      default:
        return 'Smart Meds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (store.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            actions: [
              if (selectedIndex == 0)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: store.updateStatuses,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: [
              TodayScreen(store: store),
              AdherenceScreen(store: store),
              ReportsScreen(store: store),
              SettingsScreen(store: store),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (value) =>
                setState(() => selectedIndex = value),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today_rounded),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Adherence',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// TODAY SCREEN
// ============================================================

class TodayScreen extends StatelessWidget {
  final SmartMedsStore store;

  const TodayScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final taken = store.medicines.where((m) => m.status == 'Taken').length;
    final due = store.medicines.where((m) => m.status == 'Due').length;
    final missed = store.medicines.where((m) => m.status == 'Missed').length;

    return RefreshIndicator(
      onRefresh: store.updateStatuses,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          _DashboardHeader(
            patient: store.settings.patientName,
            attention: due + missed,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Automatic demo mode: when a dose becomes due, the app records a simulated dispense and updates stock while this screen is running. No physical dispenser is activated.',
                    style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.medication_rounded,
                  label: 'Medicines',
                  value: '${store.medicines.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Taken today',
                  value: '$taken',
                  accent: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  icon: Icons.warning_rounded,
                  label: 'Attention',
                  value: '${due + missed}',
                  accent: due + missed == 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: "Today's medicines",
            subtitle: '$taken taken Â· $due due Â· $missed missed',
            trailing: FilledButton.icon(
              onPressed: () => _addMedicine(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
          const SizedBox(height: 12),
          if (store.medicines.isEmpty)
            EmptyStateCard(
              icon: Icons.medication_outlined,
              title: 'No medicines scheduled',
              message: 'Add a medicine to begin your care schedule.',
              actionLabel: 'Add medicine',
              onPressed: () => _addMedicine(context),
            ),
          ...store.medicines.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MedicineCard(
                    store: store,
                    medicine: entry.value,
                    index: entry.key,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addMedicine(BuildContext context) async {
    final medicine = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(builder: (_) => const MedicineEditorScreen()),
    );
    if (medicine != null) await store.addMedicine(medicine);
  }
}

class _DashboardHeader extends StatelessWidget {
  final String patient;
  final int attention;

  const _DashboardHeader({required this.patient, required this.attention});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${_month(now.month)} ${now.day}, ${now.year}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163CBA), Color(0xFF1F6BFF), Color(0xFF5AA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1F6BFF),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Meds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Good care starts with every dose, $patient.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  attention == 0
                      ? 'All scheduled doses are under control.'
                      : '$attention dose${attention == 1 ? '' : 's'} need attention.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  static String _month(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    children.add(
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (trailing != null) {
      children.add(trailing!);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }
}

// ============================================================
// MEDICINE CARD
// ============================================================

class MedicineCard extends StatelessWidget {
  final SmartMedsStore store;
  final Medicine medicine;
  final int index;

  const MedicineCard({
    super.key,
    required this.store,
    required this.medicine,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = store.statusColor(medicine.status);
    final dose = int.tryParse(medicine.tablets) ?? 1;
    final empty = medicine.stock <= 0;
    final low = medicine.stock > 0 && medicine.stock <= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 11,
                      runSpacing: 5,
                      children: [
                        _MetaItem(
                          icon: Icons.schedule_rounded,
                          text: medicine.time,
                        ),
                        _MetaItem(
                          icon: Icons.numbers_rounded,
                          text: '$dose tablet${dose == 1 ? '' : 's'}',
                        ),
                        _MetaItem(
                          icon: Icons.inventory_2_rounded,
                          text: medicine.container,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(text: store.displayStatus(medicine.status), color: color),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    empty
                        ? 'Container empty'
                        : '${medicine.stock} tablet${medicine.stock == 1 ? '' : 's'} remaining',
                    style: TextStyle(
                      color: empty
                          ? AppColors.danger
                          : low
                              ? AppColors.warning
                              : AppColors.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (low)
                  const _StatusChip(text: 'Low stock', color: AppColors.warning),
              ],
            ),
          ),
          if (empty && medicine.status != 'Taken') ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Container empty — automatic dispensing is paused.',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _dispense(BuildContext context) async {
    try {
      await store.markTaken(index, dispense: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medicine.name} dispensed and logged.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineEditorScreen(
          medicine: medicine,
          editing: true,
        ),
      ),
    );
    if (result != null) await store.editMedicine(index, result);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove ${medicine.name} and its safety schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.removeMedicine(index);
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

// ============================================================
// ADHERENCE SCREEN
// ============================================================

class AdherenceScreen extends StatefulWidget {
  final SmartMedsStore store;
  const AdherenceScreen({super.key, required this.store});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    final a = widget.store.analytics;
    final adherence = a.adherencePercent(days);
    final taken = a.takenCount(days);
    final missed = a.missedCount(days);
    final late = a.inRange(days)
        .where((r) => r.isTaken && r.delayMinutes > 0)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        _AdherenceHero(
          percent: adherence,
          label: a.adherenceLabel(days),
        ),
        const SizedBox(height: 14),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: {days},
          onSelectionChanged: (selection) =>
              setState(() => days = selection.first),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Performance snapshot',
          subtitle: 'Calculated from recorded dose events',
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.check_circle_rounded,
                label: 'Taken',
                value: '$taken',
                accent: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.event_busy_rounded,
                label: 'Missed',
                value: '$missed',
                accent: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.schedule_rounded,
                label: 'Late doses',
                value: '$late',
                accent: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Analytics',
          subtitle: 'Patterns Smart Meds can calculate from the history',
        ),
        const SizedBox(height: 11),
        _AnalyticsRow(
          icon: Icons.timelapse_rounded,
          title: 'Average delay when late',
          value: '${a.averageLateMinutes(days).toStringAsFixed(1)} min',
          color: AppColors.warning,
        ),
        _AnalyticsRow(
          icon: Icons.wb_sunny_outlined,
          title: 'Average morning delay',
          value: '${a.morningAverageDelay(days).toStringAsFixed(1)} min',
          color: AppColors.info,
        ),
        _AnalyticsRow(
          icon: Icons.calendar_month_rounded,
          title: 'Most missed day',
          value: a.mostMissedDay(days),
          color: AppColors.danger,
        ),
        _AnalyticsRow(
          icon: Icons.medication_rounded,
          title: 'Most missed medicine',
          value: a.mostMissedMedicine(days),
          color: AppColors.danger,
        ),
        _AnalyticsRow(
          icon: Icons.verified_rounded,
          title: 'Best adherence medicine',
          value: a.bestMedicine(days),
          color: AppColors.success,
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Daily missed-dose rates',
          subtitle: 'Useful for finding recurring weekly patterns',
        ),
        const SizedBox(height: 10),
        ...List.generate(7, (index) {
          final weekday = index + 1;
          final rate = a.missRateForWeekday(weekday, days);
          return _DayRateRow(
            day: SmartMedsAnalytics.dayName(weekday),
            rate: rate,
          );
        }),
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Recent events',
          subtitle: 'Taken, late and missed doses',
        ),
        const SizedBox(height: 10),
        if (a.inRange(days).isEmpty)
          const EmptyHistoryCard()
        else
          ...a.inRange(days).take(15).map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DoseHistoryRow(record: record),
                ),
              ),
      ],
    );
  }
}

class _AdherenceHero extends StatelessWidget {
  final double percent;
  final String label;

  const _AdherenceHero({required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 90
        ? AppColors.success
        : percent >= 75
            ? AppColors.primary
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 94,
            height: 94,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (percent / 100).clamp(0, 1),
                  strokeWidth: 10,
                  color: color,
                  backgroundColor: AppColors.border,
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication adherence',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'A dose is considered on time when pickup is within 5 minutes of the scheduled time.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _AnalyticsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRateRow extends StatelessWidget {
  final String day;
  final double rate;

  const _DayRateRow({required this.day, required this.rate});

  @override
  Widget build(BuildContext context) {
    final value = (rate / 100).clamp(0.0, 1.0);
    final color = rate == 0 ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${rate.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoseHistoryRow extends StatelessWidget {
  final DispensingRecord record;
  const DoseHistoryRow({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.status == 'Missed'
        ? AppColors.danger
        : record.status == 'Taken Late'
            ? AppColors.warning
            : AppColors.success;
    final dt = DateTime.tryParse(record.scheduledDateTime);
    final date = dt == null
        ? 'Unknown date'
        : '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              record.isMissed
                  ? Icons.event_busy_rounded
                  : Icons.medication_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.medicine,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$date Â· ${record.scheduledTime}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(text: record.status, color: color),
              if (record.isTaken && record.delayMinutes > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+${record.delayMinutes} min',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyHistoryCard extends StatelessWidget {
  const EmptyHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, size: 46, color: AppColors.primary),
          SizedBox(height: 11),
          Text(
            'No adherence data yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Record a few doses and Smart Meds will start calculating trends.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORTS SCREEN
// ============================================================

class ReportsScreen extends StatefulWidget {
  final SmartMedsStore store;
  const ReportsScreen({super.key, required this.store});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int days = 30;
  bool busy = false;

  Future<void> exportCsv() async {
    if (!widget.store.settings.sharingConsent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable report-sharing consent in Settings before exporting.'),
        ),
      );
      return;
    }
    final records = widget.store.analytics.inRange(days);
    final out = StringBuffer();
    out.writeln(
      'Date,Medicine,Container,Scheduled time,Pickup time,Delay minutes,Status,Alert triggered',
    );
    for (final record in records) {
      final dt = DateTime.tryParse(record.scheduledDateTime);
      final date = dt == null
          ? ''
          : '${dt.year.toString().padLeft(4, '0')}-'
              '${dt.month.toString().padLeft(2, '0')}-'
              '${dt.day.toString().padLeft(2, '0')}';
      out.writeln([
        csv(date),
        csv(record.medicine),
        csv(record.container),
        csv(record.scheduledTime),
        csv(record.dispensedTime),
        record.delayMinutes,
        csv(record.status),
        record.alertTriggered ? 'Yes' : 'No',
      ].join(','));
    }

    final bytes = Uint8List.fromList(utf8.encode(out.toString()));
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Smart Meds CSV report',
          subject: 'Smart Meds Patient Adherence Report',
          files: [
            XFile.fromData(
              bytes,
              name: 'smart_meds_adherence.csv',
              mimeType: 'text/csv',
            ),
          ],
          fileNameOverrides: ['smart_meds_adherence_${days}days.csv'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> exportPdf() async {
    if (!widget.store.settings.sharingConsent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable report-sharing consent in Settings before exporting.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final bytes = await SmartMedsReportPdf(widget.store).build(days);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'smart_meds_adherence_${days}days.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF export failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String csv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.store.analytics;
    final adherence = a.adherencePercent(days);
    final taken = a.takenCount(days);
    final missed = a.missedCount(days);
    final late = a.inRange(days)
        .where((r) => r.isTaken && r.delayMinutes > 0)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF163CBA), Color(0xFF1F6BFF), Color(0xFF5AA8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F1F6BFF),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Adherence Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'A structured record of adherence, delays, missed doses and safety events.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7d')),
                  ButtonSegment(value: 30, label: Text('30d')),
                  ButtonSegment(value: 90, label: Text('90d')),
                ],
                selected: {days},
                onSelectionChanged: (s) => setState(() => days = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.percent_rounded,
                label: 'Adherence',
                value: '${adherence.toStringAsFixed(0)}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.check_circle_rounded,
                label: 'Taken',
                value: '$taken',
                accent: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.event_busy_rounded,
                label: 'Missed',
                value: '$missed',
                accent: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Generate report',
          subtitle: 'Export exactly what the Data Hub calculates',
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _ReportAction(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Patient Adherence Report PDF',
                subtitle: 'Presentation-ready summary and dose history',
                onPressed: busy ? null : exportPdf,
              ),
              const Divider(height: 14),
              _ReportAction(
                icon: Icons.table_chart_rounded,
                title: 'Adherence CSV dataset',
                subtitle: 'Machine-readable event history for analysis',
                onPressed: busy ? null : exportCsv,
              ),
              if (busy) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Data Hub insights',
          subtitle: 'Automatically calculated from recorded events',
        ),
        const SizedBox(height: 10),
        _AnalyticsRow(
          icon: Icons.schedule_rounded,
          title: 'Average delay when late',
          value: '${a.averageLateMinutes(days).toStringAsFixed(1)} min',
          color: AppColors.warning,
        ),
        _AnalyticsRow(
          icon: Icons.wb_sunny_outlined,
          title: 'Morning average delay',
          value: '${a.morningAverageDelay(days).toStringAsFixed(1)} min',
          color: AppColors.info,
        ),
        _AnalyticsRow(
          icon: Icons.calendar_month_rounded,
          title: 'Most missed day',
          value: a.mostMissedDay(days),
          color: AppColors.danger,
        ),
        _AnalyticsRow(
          icon: Icons.medication_rounded,
          title: 'Most missed medicine',
          value: a.mostMissedMedicine(days),
          color: AppColors.danger,
        ),
        _AnalyticsRow(
          icon: Icons.timer_outlined,
          title: 'Late doses',
          value: '$late',
          color: AppColors.warning,
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Included data',
          subtitle: 'The CSV and PDF are based on these fields',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _DataPill('Date'),
            _DataPill('Medicine'),
            _DataPill('Container'),
            _DataPill('Scheduled time'),
            _DataPill('Pickup time'),
            _DataPill('Delay'),
            _DataPill('Status'),
            _DataPill('Safety alert'),
          ],
        ),
      ],
    );
  }
}

class _ReportAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  const _ReportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
      ),
      trailing: FilledButton(
        onPressed: onPressed,
        child: const Text('Export'),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  final String text;
  const _DataPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// PDF GENERATOR
// ============================================================

class SmartMedsReportPdf {
  final SmartMedsStore store;
  SmartMedsReportPdf(this.store);

  Future<Uint8List> build(int days) async {
    final a = store.analytics;
    final data = a.inRange(days);
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SMART MEDS',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'PATIENT ADHERENCE REPORT',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Text(
            'Patient Adherence Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Patient: ${store.settings.patientName}'),
          pw.Text('Emergency contact: ${store.settings.emergencyContactName}'),
          pw.Text('Reporting period: last $days days'),
          pw.Text('Generated: ${SmartMedsStore.formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _metricRow('Adherence', '${a.adherencePercent(days).toStringAsFixed(0)}%'),
              _metricRow('Taken doses', '${a.takenCount(days)}'),
              _metricRow('Missed doses', '${a.missedCount(days)}'),
              _metricRow('Average late delay', '${a.averageLateMinutes(days).toStringAsFixed(1)} min'),
              _metricRow('Morning average delay', '${a.morningAverageDelay(days).toStringAsFixed(1)} min'),
              _metricRow('Most missed day', a.mostMissedDay(days)),
              _metricRow('Most missed medicine', a.mostMissedMedicine(days)),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Dose history',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 7),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Medicine',
              'Time',
              'Pickup',
              'Delay',
              'Status',
            ],
            data: data.map((r) {
              final dt = DateTime.tryParse(r.scheduledDateTime);
              final date = dt == null ? '' : '${dt.day}/${dt.month}/${dt.year}';
              return [
                date,
                r.medicine,
                r.scheduledTime,
                r.dispensedTime.isEmpty ? '-' : r.dispensedTime,
                '${r.delayMinutes} min',
                r.status,
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.4),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Safety protocol',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Configured escalation window: ${store.settings.alertDelayMinutes} minutes. '
            'The Android safety engine schedules an alarm for a dose when pickup has not been recorded. '
            'For this prototype, the registered emergency phone can be the developer/tester phone.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report is a prototype operational record and is not a diagnosis or a substitute for professional medical advice.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.TableRow _metricRow(String label, String value) => pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(7),
            child: pw.Text(label),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(7),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      );
}

// ============================================================
// SETTINGS SCREEN
// ============================================================

class SettingsScreen extends StatefulWidget {
  final SmartMedsStore store;
  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final TextEditingController patient;
  late final TextEditingController contact;
  late final TextEditingController phone;
  late final TextEditingController doctorEmail;
  late final TextEditingController webhook;

  bool emergency = false;
  bool sms = true;
  bool email = false;
  bool dataConsent = false;
  bool sharingConsent = false;
  bool smsPermission = false;
  bool exactAlarm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = widget.store.settings;
    patient = TextEditingController(text: s.patientName);
    contact = TextEditingController(text: s.emergencyContactName);
    phone = TextEditingController(text: s.emergencyPhone);
    doctorEmail = TextEditingController(text: s.doctorEmail);
    webhook = TextEditingController(text: s.emailWebhookUrl);
    emergency = s.emergencyAlertsEnabled;
    sms = s.smsEnabled;
    email = s.emailEnabled;
    dataConsent = s.dataConsent;
    sharingConsent = s.sharingConsent;
    refreshPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    patient.dispose();
    contact.dispose();
    phone.dispose();
    doctorEmail.dispose();
    webhook.dispose();
    super.dispose();
  }

  Future<void> refreshPermissions() async {
    final smsValue = await NativeSafetyBridge.smsPermissionGranted();
    final exactValue = await NativeSafetyBridge.canScheduleExactAlarm();
    if (!mounted) return;
    setState(() {
      smsPermission = smsValue;
      exactAlarm = exactValue;
    });
  }

  AppSettings collectSettings() => AppSettings(
        patientName: patient.text.trim().isEmpty
            ? 'Prototype Patient'
            : patient.text.trim(),
        emergencyContactName: contact.text.trim().isEmpty
            ? 'Emergency Contact'
            : contact.text.trim(),
        emergencyPhone: phone.text.trim(),
        doctorEmail: doctorEmail.text.trim(),
        emailWebhookUrl: webhook.text.trim(),
        emergencyAlertsEnabled: emergency,
        smsEnabled: sms,
        emailEnabled: email,
        dataConsent: dataConsent,
        sharingConsent: sharingConsent,
        alertDelayMinutes: 45,
      );

  Future<void> save() async {
    final value = collectSettings();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (value.emergencyAlertsEnabled) {
      if (value.smsEnabled && value.emergencyPhone.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Enter an emergency phone number for automatic SMS.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (value.smsEnabled) {
        final granted = await NativeSafetyBridge.smsPermissionGranted();
        if (!granted) {
          await NativeSafetyBridge.requestSmsPermission();
          final grantedAfterRequest = await NativeSafetyBridge.smsPermissionGranted();
          if (!grantedAfterRequest) {
            messenger?.showSnackBar(
              const SnackBar(
                content: Text('Grant SMS permission before enabling automatic SMS alerts.'),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }
        }
      }
      if (value.emailEnabled && value.doctorEmail.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Enter the doctor or healthcare email for email alerts.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (value.emailEnabled && value.emailWebhookUrl.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Enter the HTTPS email webhook URL for email alerts.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (value.emailEnabled &&
          !value.emailWebhookUrl.toLowerCase().startsWith('https://')) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Email webhook must use HTTPS.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }
    await widget.store.updateSettings(value);
    if (!mounted) return;
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> grantSms() async {
    final before = await NativeSafetyBridge.smsPermissionGranted();
    if (!before) await NativeSafetyBridge.requestSmsPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    await refreshPermissions();
  }

  Future<void> testSms() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await save();
    try {
      await widget.store.testSms();
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Test SMS sent.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> testAutomaticAlert() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await save();
    try {
      await widget.store.testEmergencyProtocol();
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Automatic safety test scheduled for 1 minute from now.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> clearHistory() async {
    final yes = await confirmAction(
      context,
      title: 'Clear adherence history?',
      message: 'This removes all recorded dose events from this device.',
      confirmLabel: 'Clear history',
    );
    if (yes) await widget.store.clearHistory();
  }

  Future<void> deleteAll() async {
    final yes = await confirmAction(
      context,
      title: 'Delete all local data?',
      message:
          'Medicines, reports, history, settings and safety schedules will be removed from this device.',
      confirmLabel: 'Delete everything',
      danger: true,
    );
    if (yes) await widget.store.clearAllData();
  }

  Future<bool> confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: danger
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      )
                    : null,
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        const SectionHeader(
          title: 'Patient profile',
          subtitle: 'Used in reports and safety messages',
        ),
        const SizedBox(height: 10),
        SettingsPanel(
          children: [
            TextField(
              controller: patient,
              decoration: const InputDecoration(
                labelText: 'Patient name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: contact,
              decoration: const InputDecoration(
                labelText: 'Emergency contact name',
                prefixIcon: Icon(Icons.contact_phone_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Emergency safety protocol',
          subtitle: '45-minute no-pickup escalation',
        ),
        const SizedBox(height: 10),
        SettingsPanel(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: emergency,
              onChanged: (v) => setState(() => emergency = v),
              title: const Text(
                'Enable emergency alerts',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Schedule an automatic safety alarm 45 minutes after each dose.',
              ),
            ),
            const Divider(height: 22),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency contact phone',
                hintText: '+91XXXXXXXXXX',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 10),
            _PermissionRow(
              icon: smsPermission
                  ? Icons.check_circle_rounded
                  : Icons.sms_failed_outlined,
              color: smsPermission
                  ? AppColors.success
                  : AppColors.warning,
              text: smsPermission
                  ? 'SMS permission granted'
                  : 'SMS permission required for automatic SMS',
              actionLabel: 'Grant',
              onPressed: grantSms,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: sms,
              onChanged: (v) => setState(() => sms = v),
              title: const Text(
                'Automatic SMS',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Send the safety alert to the registered number.'),
            ),
            const Divider(height: 22),
            TextField(
              controller: doctorEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Doctor / healthcare email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: webhook,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Secure email webhook URL',
                hintText: 'https://example.com/webhook',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Email automation is routed through your HTTPS webhook. Keep provider passwords and secret API keys outside the mobile app.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: email,
              onChanged: (v) => setState(() => email = v),
              title: const Text(
                'Automatic email webhook',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: testSms,
                icon: const Icon(Icons.sms_rounded),
                label: const Text('Send test SMS now'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: testAutomaticAlert,
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text('Test automatic alert in 1 minute'),
              ),
            ),
            const SizedBox(height: 10),
            _PermissionRow(
              icon: exactAlarm
                  ? Icons.alarm_on_rounded
                  : Icons.alarm_off_rounded,
              color: exactAlarm ? AppColors.success : AppColors.warning,
              text: exactAlarm
                  ? 'Exact alarm access enabled'
                  : 'Exact alarm access not enabled; Android may delay alarms',
              actionLabel: 'Open',
              onPressed: () async {
                await NativeSafetyBridge.openExactAlarmSettings();
                await Future.delayed(const Duration(milliseconds: 500));
                await refreshPermissions();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Data & privacy',
          subtitle: 'Patient-controlled local data management',
        ),
        const SizedBox(height: 10),
        SettingsPanel(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: dataConsent,
              onChanged: (v) => setState(() => dataConsent = v ?? false),
              title: const Text(
                'I consent to local storage of medication and adherence data.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: sharingConsent,
              onChanged: (v) =>
                  setState(() => sharingConsent = v ?? false),
              title: const Text(
                'I consent to sharing generated reports with registered recipients.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: clearHistory,
                icon: const Icon(Icons.history_rounded),
                label: const Text('Clear adherence history'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: deleteAll,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Delete all local data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save_rounded),
          label: const Text(
            'Save settings',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(53),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Smart Meds prototype. Medication records remain local unless exported or explicitly sent through a configured alert route.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 10.5),
        ),
      ],
    );
  }
}

class SettingsPanel extends StatelessWidget {
  final List<Widget> children;
  const SettingsPanel({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String actionLabel;
  final VoidCallback onPressed;

  const _PermissionRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ],
      );
}

// ============================================================
// MEDICINE EDITOR
// ============================================================

class MedicineEditorScreen extends StatefulWidget {
  final Medicine? medicine;
  final bool editing;

  const MedicineEditorScreen({
    super.key,
    this.medicine,
    this.editing = false,
  });

  @override
  State<MedicineEditorScreen> createState() => _MedicineEditorScreenState();
}

class _MedicineEditorScreenState extends State<MedicineEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController dose;
  late final TextEditingController stock;
  String hour = '8';
  String minute = '00';
  String period = 'AM';
  String container = 'Container 1';

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    name = TextEditingController(text: m?.name ?? '');
    dose = TextEditingController(text: m?.tablets ?? '1');
    stock = TextEditingController(text: m?.stock.toString() ?? '10');
    if (m != null) {
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$')
          .firstMatch(m.time.trim().toUpperCase());
      if (match != null) {
        hour = match.group(1)!;
        minute = match.group(2)!;
        period = match.group(3)!;
      }
      container = m.container;
    }
  }

  @override
  void dispose() {
    name.dispose();
    dose.dispose();
    stock.dispose();
    super.dispose();
  }

  void save() {
    final medicineName = name.text.trim();
    final doseNumber = int.tryParse(dose.text.trim());
    final stockNumber = int.tryParse(stock.text.trim());
    if (medicineName.isEmpty) {
      showError('Enter the medicine name.');
      return;
    }
    if (doseNumber == null || doseNumber <= 0) {
      showError('Enter a valid dose quantity.');
      return;
    }
    if (stockNumber == null || stockNumber < doseNumber) {
      showError('Current stock must be at least the dose quantity.');
      return;
    }

    Navigator.pop(
      context,
      Medicine(
        id: widget.medicine?.id,
        name: medicineName,
        tablets: doseNumber.toString(),
        time: '$hour:$minute $period',
        container: container,
        stock: stockNumber,
        status: widget.medicine?.status ?? 'Pending',
        takenDate: widget.medicine?.takenDate ?? '',
        scheduleDate: widget.medicine?.scheduleDate ?? '',
        safetyEventId: widget.medicine?.safetyEventId ?? '',
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing ? 'Edit medicine' : 'Add medicine',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          const SectionHeader(
            title: 'Medicine details',
            subtitle: 'Dose, stock and dispenser assignment',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  hintText: 'e.g. Paracetamol',
                  prefixIcon: Icon(Icons.medication_rounded),
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dose,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dose quantity',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current stock',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SectionHeader(
            title: 'Schedule',
            subtitle: 'One daily dose time',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: hour,
                      decoration: const InputDecoration(labelText: 'Hour'),
                      items: List.generate(12, (i) {
                        final value = '${i + 1}';
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setState(() => hour = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: minute,
                      decoration: const InputDecoration(labelText: 'Minute'),
                      items: const [
                        '00',
                        '05',
                        '10',
                        '15',
                        '20',
                        '25',
                        '30',
                        '35',
                        '40',
                        '45',
                        '50',
                        '55',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => minute = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: period,
                      decoration: const InputDecoration(labelText: 'AM / PM'),
                      items: const [
                        DropdownMenuItem(value: 'AM', child: Text('AM')),
                        DropdownMenuItem(value: 'PM', child: Text('PM')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => period = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Daily dose: $hour:$minute $period',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SectionHeader(
            title: 'Dispenser mapping',
            subtitle: 'Match the physical container and servo',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            children: [
              DropdownButtonFormField<String>(
                initialValue: container,
                decoration: const InputDecoration(
                  labelText: 'Container',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Container 1',
                    child: Text('Container 1 Â· Servo 1'),
                  ),
                  DropdownMenuItem(
                    value: 'Container 2',
                    child: Text('Container 2 Â· Servo 2'),
                  ),
                  DropdownMenuItem(
                    value: 'Container 3',
                    child: Text('Container 3 Â· Servo 3'),
                  ),
                  DropdownMenuItem(
                    value: 'Container 4',
                    child: Text('Container 4 Â· Servo 4'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => container = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.12)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Pickup events can come from the physical hand sensor later. For the prototype, the Dispense action records the pickup and feeds the same adherence engine.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              widget.editing ? 'Save changes' : 'Save medicine',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GENERIC EMPTY CARD
// ============================================================

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      );

}