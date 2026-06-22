import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:intl/intl.dart';

class TrainingDesignatorScreen extends StatefulWidget {
  const TrainingDesignatorScreen({super.key});

  @override
  State<TrainingDesignatorScreen> createState() =>
      _TrainingDesignatorScreenState();
}

class _TrainingDesignatorScreenState extends State<TrainingDesignatorScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _tenantId;
  String? _currentUserId;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _trainings = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _fetchInitialData();
  }

  // ==========================================
  // --- DATA FETCHING ---
  // ==========================================
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUserId == null) return;

      // 1. Get the admin's tenant_id (Company ID)
      final profileData = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', _currentUserId as Object)
          .single();

      _tenantId = profileData['tenant_id'];

      if (_tenantId != null) {
        // 2. Fetch all employees in this company for the Dropdowns
        final employeeResponse = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .eq('tenant_id', _tenantId as Object)
            .order('full_name');

        _employees = List<Map<String, dynamic>>.from(employeeResponse);

        // 3. Fetch the existing trainings
        await _fetchTrainings();
      }
    } catch (e) {
      debugPrint("Error loading training data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTrainings() async {
    if (_tenantId == null) return;
    try {
      final data = await SupabaseService().getCompanyTrainings(_tenantId!);
      if (mounted) {
        setState(() {
          _trainings = data;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing trainings: $e");
    }
  }

  // ==========================================
  // --- ASSIGN TRAINING DIALOG (WEB & MOBILE) ---
  // ==========================================
  void _showAssignTrainingDialog() {
    String? selectedTrainerId;
    String? selectedTraineeId;
    final topicController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Assign New Training",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 1. SELECT TRAINER
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Trainer",
                            prefixIcon: Icon(
                              Icons.school,
                              color: Color(0xFF00A36C),
                            ),
                          ),
                          value: selectedTrainerId,
                          items: _employees.map((emp) {
                            return DropdownMenuItem<String>(
                              value: emp['id'],
                              child: Text(emp['full_name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedTrainerId = val),
                        ),
                        const SizedBox(height: 16),

                        // 2. SELECT TRAINEE
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Trainee",
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.blueAccent,
                            ),
                          ),
                          value: selectedTraineeId,
                          items: _employees.map((emp) {
                            return DropdownMenuItem<String>(
                              value: emp['id'],
                              child: Text(emp['full_name'] ?? 'Unknown'),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedTraineeId = val),
                        ),
                        const SizedBox(height: 16),

                        // 3. TOPIC
                        TextField(
                          controller: topicController,
                          decoration: const InputDecoration(
                            labelText: "Training Topic (e.g. POS System)",
                            prefixIcon: Icon(Icons.topic),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. DURATION
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Duration (in minutes)",
                            prefixIcon: Icon(Icons.timer),
                            hintText: "e.g. 60",
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. DESCRIPTION (Optional)
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Notes / Description (Optional)",
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SUBMIT & CANCEL BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF00A36C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (selectedTrainerId == null ||
                                      selectedTraineeId == null ||
                                      topicController.text.isEmpty ||
                                      durationController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please fill all required fields.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (selectedTrainerId == selectedTraineeId) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Trainer and Trainee cannot be the same person!",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(context); // Close dialog
                                  setState(() => _isLoading = true);

                                  try {
                                    await SupabaseService().createTraining(
                                      tenantId: _tenantId!,
                                      adminId: _currentUserId!,
                                      trainerId: selectedTrainerId!,
                                      traineeId: selectedTraineeId!,
                                      topic: topicController.text.trim(),
                                      durationMinutes: int.parse(
                                        durationController.text.trim(),
                                      ),
                                      description: descController.text.trim(),
                                    );

                                    await _fetchTrainings(); // Refresh the list!

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Training Assigned Successfully!",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Error: $e"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                                child: const Text(
                                  "Assign Training",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Training Designator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchTrainings().then((_) => setState(() => _isLoading = false));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignTrainingDialog,
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Assign Training",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _trainings.isEmpty
          ? _buildEmptyState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchTrainings();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 0 : 16,
                      vertical: 24,
                    ),
                    itemCount: _trainings.length,
                    itemBuilder: (context, index) {
                      final training = _trainings[index];

                      // Extract joined data cleanly
                      final trainerName =
                          training['trainer']?['full_name'] ??
                          'Unknown Trainer';
                      final traineeName =
                          training['trainee']?['full_name'] ??
                          'Unknown Trainee';
                      final topic = training['topic'] ?? 'No Topic';
                      final duration =
                          training['duration_minutes']?.toString() ?? '0';
                      final status = training['status'] ?? 'pending';

                      // Parse creation date
                      final createdAt = DateTime.parse(
                        training['created_at'],
                      ).toLocal();
                      final dateString = DateFormat(
                        'MMM d, yyyy',
                      ).format(createdAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      topic,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // The VS Layout (Trainer vs Trainee)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildParticipantColumn(
                                      title: "Trainer",
                                      name: trainerName,
                                      icon: Icons.school,
                                      color: const Color(0xFF00A36C),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildParticipantColumn(
                                      title: "Trainee",
                                      name: traineeName,
                                      icon: Icons.person,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$duration mins",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Assigned: $dateString",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  // UI Helpers
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.model_training,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Trainings Assigned",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the button below to schedule your first training session.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'in_progress':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default: // pending
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParticipantColumn({
    required String title,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
