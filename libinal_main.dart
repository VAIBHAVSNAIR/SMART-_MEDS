import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SmartMedsApp());
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6BFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Medicine {
  final String name;
  final String tablets;
  final String time;
  final String container;
  final int stock;
  final String status;
  final String takenDate;

  const Medicine({
    required this.name,
    required this.tablets,
    required this.time,
    this.container = 'Container 1',
    this.stock = 1,
    this.status = '⏳ Pending',
    this.takenDate = '',
  });

  Medicine copyWith({
    String? name,
    String? tablets,
    String? time,
    String? container,
    int? stock,
    String? status,
    String? takenDate,
  }) {
    return Medicine(
      name: name ?? this.name,
      tablets: tablets ?? this.tablets,
      time: time ?? this.time,
      container: container ?? this.container,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      takenDate: takenDate ?? this.takenDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'tablets': tablets,
        'time': time,
        'container': container,
        'stock': stock,
        'status': status,
        'takenDate': takenDate,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name']?.toString() ?? '',
      tablets: json['tablets']?.toString() ?? '1',
      time: json['time']?.toString() ?? '',
      container: json['container']?.toString() ?? 'Container 1',
      stock: int.tryParse(json['stock']?.toString() ?? '') ??
          (int.tryParse(json['tablets']?.toString() ?? '') ?? 1),
      status: json['status']?.toString() ?? '⏳ Pending',
      takenDate: json['takenDate']?.toString() ?? '',
    );
  }
}

class DispensingRecord {
  final String medicine;
  final String container;
  final String scheduledTime;
  final String dispensedTime;
  final int tablets;
  final String status;

  const DispensingRecord({
    required this.medicine,
    required this.container,
    required this.scheduledTime,
    required this.dispensedTime,
    required this.tablets,
    this.status = '✅ Taken',
  });

  Map<String, dynamic> toJson() => {
        'medicine': medicine,
        'container': container,
        'scheduledTime': scheduledTime,
        'dispensedTime': dispensedTime,
        'tablets': tablets,
        'status': status,
      };

  factory DispensingRecord.fromJson(Map<String, dynamic> json) {
    return DispensingRecord(
      medicine: json['medicine']?.toString() ?? '',
      container: json['container']?.toString() ?? 'Container 1',
      scheduledTime: json['scheduledTime']?.toString() ?? '',
      dispensedTime: json['dispensedTime']?.toString() ?? '',
      tablets: int.tryParse(json['tablets']?.toString() ?? '') ?? 1,
      status: json['status']?.toString() ?? '✅ Taken',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> medicines = [];
  List<DispensingRecord> history = [];
  bool isLoading = true;
  Timer? statusTimer;

  @override
  void initState() {
    super.initState();
    loadMedicines();
    statusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateAutomaticStatuses(),
    );
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMedicines() async {
    try {
      await loadHistory();

      final prefs = await SharedPreferences.getInstance();
      final savedMedicines = prefs.getString('medicines');

      if (savedMedicines != null && savedMedicines.isNotEmpty) {
        final decoded = jsonDecode(savedMedicines);

        if (decoded is List) {
          medicines = decoded
              .map((item) => Medicine.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          await updateAutomaticStatuses(save: false);
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        }
      }

      medicines = [
        Medicine(
          name: 'Paracetamol',
          tablets: '1',
          time: '8:00 AM',
          container: 'Container 1',
        ),
        Medicine(
          name: 'Vitamin D',
          tablets: '1',
          time: '1:00 PM',
          container: 'Container 2',
        ),
        Medicine(
          name: 'BP Tablet',
          tablets: '1',
          time: '8:00 PM',
          container: 'Container 3',
        ),
      ];

      await updateAutomaticStatuses(save: false);
      if (!mounted) return;
      setState(() => isLoading = false);
      await saveMedicines();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        medicines = [];
        isLoading = false;
      });
    }
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHistory = prefs.getString('dispensingHistory');

      if (savedHistory == null || savedHistory.isEmpty) {
        history = [];
        return;
      }

      final decoded = jsonDecode(savedHistory);
      if (decoded is List) {
        history = decoded
            .map((item) => DispensingRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      history = [];
    }
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'dispensingHistory',
      jsonEncode(history.map((record) => record.toJson()).toList()),
    );
  }

  Future<void> saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final data = medicines.map((medicine) => medicine.toJson()).toList();
    await prefs.setString('medicines', jsonEncode(data));
  }

  String currentTimeText() {
    final now = DateTime.now();
    var hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }

  Future<void> addDispensingHistory(Medicine medicine, int tablets) async {
    history.insert(
      0,
      DispensingRecord(
        medicine: medicine.name,
        container: medicine.container,
        scheduledTime: medicine.time,
        dispensedTime: currentTimeText(),
        tablets: tablets,
      ),
    );

    if (history.length > 100) {
      history = history.take(100).toList();
    }

    await saveHistory();
  }

  Future<void> showHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DispensingHistoryScreen(history: history),
      ),
    );
  }

  String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime? getMedicineDateTime(String time) {
    try {
      final value = time.trim().toUpperCase();
      final regex12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
      final match12 = regex12.firstMatch(value);
      final now = DateTime.now();

      if (match12 != null) {
        var hour = int.parse(match12.group(1)!);
        final minute = int.parse(match12.group(2)!);
        final period = match12.group(3)!;

        if (hour < 1 || hour > 12) return null;

        if (period == 'AM') {
          if (hour == 12) hour = 0;
        } else {
          if (hour != 12) hour += 12;
        }

        return DateTime(now.year, now.month, now.day, hour, minute);
      }

      final regex24 = RegExp(r'^(\d{1,2}):(\d{2})$');
      final match24 = regex24.firstMatch(value);

      if (match24 != null) {
        final hour = int.parse(match24.group(1)!);
        final minute = int.parse(match24.group(2)!);

        if (hour > 23 || minute > 59) return null;

        return DateTime(now.year, now.month, now.day, hour, minute);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAutomaticStatuses({bool save = true}) async {
    if (medicines.isEmpty) return;

    final now = DateTime.now();
    final today = todayString();
    var changed = false;

    for (var index = 0; index < medicines.length; index++) {
      final medicine = medicines[index];
      if (medicine.takenDate == today) {
        if (medicine.status != '✅ Taken') {
          changed = true;
          medicines[index] = medicine.copyWith(status: '✅ Taken');
        }
        continue;
      }

      final scheduled = getMedicineDateTime(medicine.time);
      if (scheduled == null) {
        if (medicine.status != '⚠️ Invalid Time') {
          changed = true;
          medicines[index] = medicine.copyWith(status: '⚠️ Invalid Time');
        }
        continue;
      }

      final difference = now.difference(scheduled);

      if (now.isBefore(scheduled)) {
        if (medicine.status != '⏳ Pending') {
          changed = true;
          medicines[index] = medicine.copyWith(status: '⏳ Pending');
        }
      } else if (difference.inMinutes < 30) {
        if (medicine.status != '🔔 Due') {
          changed = true;
          medicines[index] = medicine.copyWith(status: '🔔 Due');
        }
      } else {
        if (medicine.status != '❌ Missed') {
          changed = true;
          medicines[index] = medicine.copyWith(status: '❌ Missed');
        }
      }
    }

    if (changed && mounted) {
      setState(() {});
      if (save) await saveMedicines();
    }
  }

  Future<void> markTaken(int index) async {
    final medicine = medicines[index];
    medicines[index] = medicine.copyWith(
      status: '✅ Taken',
      takenDate: todayString(),
    );
    setState(() {});
    await saveMedicines();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${medicine.name} marked as taken.')),
    );
  }

  Future<void> addMedicine() async {
    final Medicine? newMedicine = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );

    if (newMedicine == null) return;

    setState(() => medicines.add(newMedicine));
    await saveMedicines();
    await updateAutomaticStatuses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine added successfully.')),
    );
  }

  Future<void> editMedicine(int index) async {
    final oldMedicine = medicines[index];
    final updatedMedicine = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(
          medicine: Medicine(
            name: oldMedicine.name,
            tablets: oldMedicine.tablets,
            time: oldMedicine.time,
            container: oldMedicine.container,
            stock: oldMedicine.stock,
            status: oldMedicine.status,
            takenDate: oldMedicine.takenDate,
          ),
          isEditing: true,
        ),
      ),
    );

    if (updatedMedicine == null) return;

    setState(() => medicines[index] = updatedMedicine);
    await updateAutomaticStatuses();
    await saveMedicines();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine updated successfully.')),
    );
  }

  Future<void> deleteMedicine(int index) async {
    final medicineName = medicines[index].name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete $medicineName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => medicines.removeAt(index));
    await saveMedicines();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$medicineName deleted.')),
    );
  }

  String servoForContainer(String container) {
    switch (container) {
      case 'Container 1':
        return 'Servo 1 (GPIO 18)';
      case 'Container 2':
        return 'Servo 2 (GPIO 19)';
      case 'Container 3':
        return 'Servo 3 (GPIO 21)';
      case 'Container 4':
        return 'Servo 4 (GPIO 22)';
      default:
        return 'Unknown';
    }
  }

  Future<void> dispenseSimulation(int index) async {
    final medicine = medicines[index];
    final dose = int.tryParse(medicine.tablets) ?? 1;

    if (medicine.stock < dose) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Not enough ${medicine.name} in ${medicine.container}. Only ${medicine.stock} tablet(s) left.',
          ),
        ),
      );
      return;
    }

    final updatedMedicine = medicine.copyWith(
      stock: medicine.stock - dose,
      status: '✅ Taken',
      takenDate: todayString(),
    );
    setState(() => medicines[index] = updatedMedicine);

    await saveMedicines();
    await addDispensingHistory(medicine, dose);

    if (!mounted) return;

    final stockMessage = updatedMedicine.stock == 0
        ? '⚠️ Container is now empty.'
        : updatedMedicine.stock <= 2
            ? '⚠️ Low stock: ${updatedMedicine.stock} tablet(s) left.'
            : '${updatedMedicine.stock} tablet(s) left.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulated: ${medicine.name} dispensed from ${medicine.container} → '
          '${servoForContainer(medicine.container)}. $stockMessage',
        ),
      ),
    );
  }

  Color statusColor(String status) {
    if (status.contains('Taken')) return Colors.green;
    if (status.contains('Missed')) return Colors.red;
    if (status.contains('Due')) return Colors.blue;
    if (status.contains('Invalid')) return Colors.red;
    return Colors.orange;
  }

  Widget medicineCard(Medicine medicine, int index) {
    final color = statusColor(medicine.status);
    final canTake = medicine.status == '🔔 Due' || medicine.status == '❌ Missed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medication, color: Colors.blue, size: 28),
              ),
              title: Text(
                medicine.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⏰ ${medicine.time}   •   💊 ${medicine.tablets} tablet(s)\n'
                  '📦 ${medicine.container}   •   ⚙️ ${servoForContainer(medicine.container)}\n'
                  '📊 ${medicine.stock} tablet(s) left',
                  style: const TextStyle(height: 1.5, color: Colors.black87),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medicine.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canTake)
                  ElevatedButton.icon(
                    onPressed: () => dispenseSimulation(index),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Dispense Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (canTake) const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit Medicine',
                  icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                  onPressed: () => editMedicine(index),
                ),
                IconButton(
                  tooltip: 'Delete Medicine',
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () => deleteMedicine(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueMedicines = medicines.where(
      (medicine) => medicine.status == '🔔 Due' || medicine.status == '❌ Missed',
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text(
          '💊 Smart Meds',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Dispensing History',
              icon: const Icon(Icons.history_rounded),
              onPressed: showHistory,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF4F7FF), Color(0xFFEAF3FF)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
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
                                  "Today's Medicines",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$dueMedicines item(s) need attention',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (medicines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.medication_outlined, size: 60, color: Colors.blue),
                            SizedBox(height: 15),
                            Text(
                              'No medicines added yet.',
                              style: TextStyle(fontSize: 17, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ...medicines.asMap().entries.map(
                      (entry) => medicineCard(entry.value, entry.key),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: addMedicine,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Add Medicine',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  final bool isEditing;

  const AddMedicineScreen({
    super.key,
    this.medicine,
    this.isEditing = false,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tabletsController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  String selectedContainer = 'Container 1';
  String selectedHour = '8';
  String selectedMinute = '00';
  String selectedPeriod = 'AM';

  Map<String, String> _parseSavedTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());

    if (match != null) {
      return {
        'hour': match.group(1)!,
        'minute': match.group(2)!,
        'period': match.group(3)!.toUpperCase(),
      };
    }

    return {'hour': '8', 'minute': '00', 'period': 'AM'};
  }

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      tabletsController.text = widget.medicine!.tablets;
      stockController.text = widget.medicine!.stock.toString();

      final parts = _parseSavedTime(widget.medicine!.time);
      selectedHour = parts['hour']!;
      selectedMinute = parts['minute']!;
      selectedPeriod = parts['period']!;
      selectedContainer = widget.medicine!.container;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    tabletsController.dispose();
    stockController.dispose();
    super.dispose();
  }

  void saveMedicine() {
    final name = nameController.text.trim();
    final tablets = tabletsController.text.trim();
    final stockText = stockController.text.trim();
    final time = '$selectedHour:$selectedMinute $selectedPeriod';

    if (name.isEmpty || tablets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the details.')),
      );
      return;
    }

    final tabletNumber = int.tryParse(tablets);
    final stockNumber = int.tryParse(stockText);

    if (tabletNumber == null || tabletNumber <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of tablets.')),
      );
      return;
    }

    if (stockNumber == null || stockNumber < tabletNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stock must be at least the number of tablets dispensed at one time.',
          ),
        ),
      );
      return;
    }

    final medicine = Medicine(
      name: name,
      tablets: tablets,
      time: time,
      container: selectedContainer,
      stock: stockNumber,
      status: widget.medicine?.status ?? '⏳ Pending',
      takenDate: widget.medicine?.takenDate ?? '',
    );

    Navigator.pop(context, medicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F7FF), Color(0xFFEAF3FF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medicine Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Example: Paracetamol',
                  prefixIcon: const Icon(Icons.medication, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Number of Tablets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tabletsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Example: 1',
                  prefixIcon: const Icon(Icons.format_list_numbered, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Example: 10',
                  prefixIcon: const Icon(Icons.inventory_2, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'How many tablets are currently stored in this container?',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Medicine Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedHour,
                      decoration: InputDecoration(
                        labelText: 'Hour',
                        prefixIcon: const Icon(Icons.access_time, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.blue.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: List.generate(12, (index) {
                        final hour = (index + 1).toString();
                        return DropdownMenuItem<String>(
                          value: hour,
                          child: Text(hour),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedHour = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedMinute,
                      decoration: InputDecoration(
                        labelText: 'Minute',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.blue.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: '00', child: Text('00')),
                        DropdownMenuItem(value: '05', child: Text('05')),
                        DropdownMenuItem(value: '10', child: Text('10')),
                        DropdownMenuItem(value: '15', child: Text('15')),
                        DropdownMenuItem(value: '20', child: Text('20')),
                        DropdownMenuItem(value: '25', child: Text('25')),
                        DropdownMenuItem(value: '30', child: Text('30')),
                        DropdownMenuItem(value: '35', child: Text('35')),
                        DropdownMenuItem(value: '40', child: Text('40')),
                        DropdownMenuItem(value: '45', child: Text('45')),
                        DropdownMenuItem(value: '50', child: Text('50')),
                        DropdownMenuItem(value: '55', child: Text('55')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedMinute = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedPeriod,
                      decoration: InputDecoration(
                        labelText: 'AM / PM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.blue.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AM', child: Text('AM')),
                        DropdownMenuItem(value: 'PM', child: Text('PM')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedPeriod = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    'Selected time: $selectedHour:$selectedMinute $selectedPeriod',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Medicine Container',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedContainer,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Container 1', child: Text('Container 1 → Servo 1 (GPIO 18)')),
                  DropdownMenuItem(value: 'Container 2', child: Text('Container 2 → Servo 2 (GPIO 19)')),
                  DropdownMenuItem(value: 'Container 3', child: Text('Container 3 → Servo 3 (GPIO 21)')),
                  DropdownMenuItem(value: 'Container 4', child: Text('Container 4 → Servo 4 (GPIO 22)')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedContainer = value);
                },
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Medicine status is automatic. Before the scheduled time it is Pending, for 30 minutes it is Due, and after that it becomes Missed. Dispense Now reduces the stock by the selected dose and marks the medicine Taken. Later the ESP32 will perform the real dispensing.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: saveMedicine,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.isEditing ? 'Save Changes' : 'Save Medicine',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DispensingHistoryScreen extends StatelessWidget {
  final List<DispensingRecord> history;

  const DispensingHistoryScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final safeHistory = List<DispensingRecord>.from(history);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Dispensing History'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: safeHistory.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 70, color: Colors.blue),
                    SizedBox(height: 15),
                    Text(
                      'No dispensing history yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'History will appear here after a medicine is dispensed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: safeHistory.length,
              itemBuilder: (context, index) {
                final record = safeHistory[index];
                final medicineName = record.medicine.isEmpty ? 'Unknown medicine' : record.medicine;
                final containerName = record.container.isEmpty ? 'Container 1' : record.container;
                final scheduled = record.scheduledTime.isEmpty ? 'Not set' : record.scheduledTime;
                final dispensed = record.dispensedTime.isEmpty ? 'Not recorded' : record.dispensedTime;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.medication, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicineName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('📦 $containerName'),
                              Text('⏰ Scheduled: $scheduled'),
                              Text('🕐 Dispensed: $dispensed'),
                              Text('💊 ${record.tablets} tablet(s)'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record.status.isEmpty ? '✅ Taken' : record.status,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
