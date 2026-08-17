import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const SmartMedsApp());
}

// ============================================================
// SMART MEDS APP
// ============================================================

class SmartMedsApp extends StatelessWidget {
  const SmartMedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Meds',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        useMaterial3: false,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// MEDICINE MODEL
// ============================================================

class Medicine {
  String name;
  String tablets;
  String time;
  String status;

  Medicine({
    required this.name,
    required this.tablets,
    required this.time,
    this.status = "⏳ Pending",
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tablets': tablets,
      'time': time,
      'status': status,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name']?.toString() ?? '',
      tablets: json['tablets']?.toString() ?? '1',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? "⏳ Pending",
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> medicines = [];

  bool isLoading = true;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  // ==========================================================
  // LOAD MEDICINES FROM LOCAL STORAGE
  // ==========================================================

  Future<void> loadMedicines() async {
    try {
      final savedMedicines = html.window.localStorage['medicines'];

      if (savedMedicines != null && savedMedicines.isNotEmpty) {
        final decoded = jsonDecode(savedMedicines);

        if (decoded is List) {
          final loadedMedicines = decoded
              .map(
                (medicine) => Medicine.fromJson(
                  Map<String, dynamic>.from(medicine),
                ),
              )
              .toList();

          setState(() {
            medicines = loadedMedicines;
            isLoading = false;
          });

          return;
        }
      }

      // --------------------------------------------------------
      // FIRST TIME DEFAULT MEDICINES
      // --------------------------------------------------------

      setState(() {
        medicines = [
          Medicine(
            name: "Paracetamol",
            tablets: "1",
            time: "8:00 AM",
            status: "✅ Taken",
          ),
          Medicine(
            name: "Vitamin D",
            tablets: "1",
            time: "1:00 PM",
            status: "⏳ Pending",
          ),
          Medicine(
            name: "BP Tablet",
            tablets: "1",
            time: "8:00 PM",
            status: "❌ Missed",
          ),
          Medicine(
            name: "Calcium",
            tablets: "1",
            time: "10:00 PM",
            status: "⏳ Pending",
          ),
        ];

        isLoading = false;
      });

      await saveMedicines();
    } catch (e) {
      setState(() {
        medicines = [];
        isLoading = false;
      });
    }
  }

  // ==========================================================
  // SAVE MEDICINES TO LOCAL STORAGE
  // ==========================================================

  Future<void> saveMedicines() async {
    final List<Map<String, dynamic>> medicineData =
        medicines.map((medicine) => medicine.toJson()).toList();

    html.window.localStorage['medicines'] =
        jsonEncode(medicineData);
  }

  // ==========================================================
  // ADD MEDICINE
  // ==========================================================

  Future<void> addMedicine() async {
    final Medicine? newMedicine =
        await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (newMedicine != null) {
      setState(() {
        medicines.add(newMedicine);
      });

      await saveMedicines();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medicine added successfully."),
        ),
      );
    }
  }

  // ==========================================================
  // EDIT MEDICINE
  // ==========================================================

  Future<void> editMedicine(int index) async {
    final Medicine medicine = medicines[index];

    final Medicine? updatedMedicine =
        await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicine: Medicine(
            name: medicine.name,
            tablets: medicine.tablets,
            time: medicine.time,
            status: medicine.status,
          ),
          isEditing: true,
        ),
      ),
    );

    if (updatedMedicine != null) {
      setState(() {
        medicines[index] = updatedMedicine;
      });

      await saveMedicines();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medicine updated successfully."),
        ),
      );
    }
  }

  // ==========================================================
  // DELETE MEDICINE
  // ==========================================================

  Future<void> deleteMedicine(int index) async {
    final medicineName = medicines[index].name;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Medicine"),
          content: Text(
            "Are you sure you want to delete $medicineName?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        medicines.removeAt(index);
      });

      await saveMedicines();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$medicineName deleted."),
        ),
      );
    }
  }

  // ==========================================================
  // CHANGE STATUS
  // ==========================================================

  Future<void> changeStatus(int index) async {
    final Medicine medicine = medicines[index];

    final String? selectedStatus =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text(
                  "⏳",
                  style: TextStyle(fontSize: 22),
                ),
                title: const Text("Pending"),
                onTap: () {
                  Navigator.pop(context, "⏳ Pending");
                },
              ),
              ListTile(
                leading: const Text(
                  "✅",
                  style: TextStyle(fontSize: 22),
                ),
                title: const Text("Taken"),
                onTap: () {
                  Navigator.pop(context, "✅ Taken");
                },
              ),
              ListTile(
                leading: const Text(
                  "❌",
                  style: TextStyle(fontSize: 22),
                ),
                title: const Text("Missed"),
                onTap: () {
                  Navigator.pop(context, "❌ Missed");
                },
              ),
            ],
          ),
        );
      },
    );

    if (selectedStatus != null) {
      setState(() {
        medicine.status = selectedStatus;
      });

      await saveMedicines();
    }
  }

  // ==========================================================
  // STATUS COLOR
  // ==========================================================

  Color getStatusColor(String status) {
    if (status.contains("Taken")) {
      return Colors.green;
    }

    if (status.contains("Missed")) {
      return Colors.red;
    }

    return Colors.orange;
  }

  // ==========================================================
  // MEDICINE CARD
  // ==========================================================

  Widget medicineCard(
    Medicine medicine,
    int index,
  ) {
    final statusColor = getStatusColor(medicine.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
        child: ListTile(
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication,
              color: Colors.blue,
              size: 30,
            ),
          ),

          // ----------------------------------------------------
          // MEDICINE NAME
          // ----------------------------------------------------

          title: Text(
            medicine.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ----------------------------------------------------
          // TIME + TABLETS
          // ----------------------------------------------------

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "⏰ ${medicine.time}   •   💊 ${medicine.tablets} tablet(s)",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),

          // ----------------------------------------------------
          // ACTION BUTTONS
          // ----------------------------------------------------

          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  changeStatus(index);
                },
                child: Text(
                  medicine.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // EDIT BUTTON
              IconButton(
                tooltip: "Edit Medicine",
                icon: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),
                onPressed: () {
                  editMedicine(index);
                },
              ),

              // DELETE BUTTON
              IconButton(
                tooltip: "Delete Medicine",
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  deleteMedicine(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD HOME SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          "💊 Smart Meds",
          style: TextStyle(
            fontSize: 23,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  const Text(
                    "Today's Medicines",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // MEDICINES
                  // ------------------------------------------------

                  if (medicines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 60,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "No medicines added yet.",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...medicines.asMap().entries.map(
                    (entry) {
                      return medicineCard(
                        entry.value,
                        entry.key,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // ADD MEDICINE BUTTON
                  // ------------------------------------------------

                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: addMedicine,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        "Add Medicine",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// ADD / EDIT MEDICINE SCREEN
// ============================================================

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  final bool isEditing;

  const AddMedicineScreen({
    super.key,
    this.medicine,
    this.isEditing = false,
  });

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState
    extends State<AddMedicineScreen> {

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController tabletsController =
      TextEditingController();

  final TextEditingController timeController =
      TextEditingController();

  String selectedStatus = "⏳ Pending";

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    if (widget.medicine != null) {
      nameController.text = widget.medicine!.name;
      tabletsController.text = widget.medicine!.tablets;
      timeController.text = widget.medicine!.time;
      selectedStatus = widget.medicine!.status;
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    nameController.dispose();
    tabletsController.dispose();
    timeController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SAVE MEDICINE
  // ==========================================================

  void saveMedicine() {
    final String name =
        nameController.text.trim();

    final String tablets =
        tabletsController.text.trim();

    final String time =
        timeController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty ||
        tablets.isEmpty ||
        time.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill in all the details.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // VALIDATE TABLET NUMBER
    // ----------------------------------------------------------

    final int? tabletNumber =
        int.tryParse(tablets);

    if (tabletNumber == null ||
        tabletNumber <= 0) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid number of tablets.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CREATE MEDICINE
    // ----------------------------------------------------------

    final Medicine medicine = Medicine(
      name: name,
      tablets: tablets,
      time: time,
      status: selectedStatus,
    );

    // ----------------------------------------------------------
    // RETURN MEDICINE TO HOME SCREEN
    // ----------------------------------------------------------

    Navigator.pop(
      context,
      medicine,
    );
  }

  // ==========================================================
  // STATUS SELECTOR
  // ==========================================================

  Widget statusOption(
    String status,
    String label,
  ) {
    final bool selected =
        selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.shade50
              : Colors.white,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: selected
                ? Colors.blue
                : Colors.grey.shade300,

            width: selected ? 2 : 1,
          ),
        ),

        child: Row(
          children: [
            Text(
              status,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(width: 12),

            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD ADD / EDIT SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? "Edit Medicine"
              : "Add Medicine",
        ),
        backgroundColor: Colors.blue,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // --------------------------------------------------
            // MEDICINE NAME
            // --------------------------------------------------

            const Text(
              "Medicine Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,
              textCapitalization:
                  TextCapitalization.words,

              decoration: InputDecoration(
                hintText: "Example: Paracetamol",
                prefixIcon: const Icon(
                  Icons.medication,
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TABLET COUNT
            // --------------------------------------------------

            const Text(
              "Number of Tablets",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: tabletsController,
              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                hintText: "Example: 1",
                prefixIcon: const Icon(
                  Icons.format_list_numbered,
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TIME
            // --------------------------------------------------

            const Text(
              "Medicine Time",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: timeController,
              decoration: InputDecoration(
                hintText: "Example: 8:00 AM",
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // STATUS
            // --------------------------------------------------

            const Text(
              "Medicine Status",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            statusOption(
              "⏳ Pending",
              "Pending",
            ),

            statusOption(
              "✅ Taken",
              "Taken",
            ),

            statusOption(
              "❌ Missed",
              "Missed",
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // SAVE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: saveMedicine,

                icon: Icon(
                  widget.isEditing
                      ? Icons.save
                      : Icons.add,
                ),

                label: Text(
                  widget.isEditing
                      ? "Save Changes"
                      : "Save Medicine",

                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // CANCEL BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}