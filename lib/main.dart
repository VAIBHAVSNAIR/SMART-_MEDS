import 'package:flutter/material.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

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
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Medicine> medicines = [
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
    ),
  ];

  void addMedicine(Medicine medicine) {
    setState(() {
      medicines.add(medicine);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("💊 Smart Meds"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Today's Medicines",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ...medicines.map(
              (medicine) => medicineCard(
                medicine.name,
                medicine.time,
                medicine.status,
                medicine.tablets,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newMedicine = await Navigator.push<Medicine>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMedicineScreen(),
                    ),
                  );

                  if (newMedicine != null) {
                    addMedicine(newMedicine);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Medicine",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget medicineCard(
    String name,
    String time,
    String status,
    String tablets,
  ) {
    Color statusColor = Colors.orange;

    if (status.contains("Taken")) {
      statusColor = Colors.green;
    } else if (status.contains("Missed")) {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.medication,
          color: Colors.blue,
          size: 35,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "⏰ $time  •  💊 $tablets tablet(s)",
        ),
        trailing: Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tabletsController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    tabletsController.dispose();
    timeController.dispose();
    super.dispose();
  }

  void saveMedicine() {
    String name = nameController.text.trim();
    String tablets = tabletsController.text.trim();
    String time = timeController.text.trim();

    if (name.isEmpty || tablets.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all the details."),
        ),
      );
      return;
    }

    final medicine = Medicine(
      name: name,
      tablets: tablets,
      time: time,
    );

    Navigator.pop(context, medicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medicine"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Medicine Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: tabletsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of Tablets",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: "Time (Example: 8:00 AM)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveMedicine,
                child: const Text(
                  "Save Medicine",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}