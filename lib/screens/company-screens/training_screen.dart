import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:intl/intl.dart';

import 'components/training_details_screen.dart'; // adjust path if you file it elsewhere

class TrainingDesignatorScreen extends StatefulWidget {
  const TrainingDesignatorScreen({super.key});

  @override
  State<TrainingDesignatorScreen> createState() =>
      _TrainingDesignatorScreenState();
}

class _TrainingDesignatorScreenState extends State<TrainingDesignatorScreen> {
  static const _accent = Color(0xFF00A36C);

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

      final profileData = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', _currentUserId as Object)
          .single();

      _tenantId = profileData['tenant_id'];

      if (_tenantId != null) {
        final employeeResponse = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .eq('tenant_id', _tenantId as Object)
            .order('full_name');

        _employees = List<Map<String, dynamic>>.from(employeeResponse);

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
      if (mounted) setState(() => _trainings = data);
    } catch (e) {
      debugPrint("Error refreshing trainings: $e");
    }
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _fmt(DateTime? d) =>
      d == null ? '—' : DateFormat('MMM d, yyyy').format(d);

  DateTime? _parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  // ==========================================
  // --- ASSIGN TRAINING DIALOG ---
  // ==========================================
  void _showAssignTrainingDialog() {
    String? selectedTrainerId;
    String? selectedTraineeId;
    DateTime? startDate;
    DateTime? endDate;
    final topicController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            // Date field used for both start and end.
            Widget dateField({
              required String label,
              required DateTime? value,
              required IconData icon,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: Icon(icon, color: _accent),
                  ),
                  child: Text(
                    value == null ? 'Select a date' : _fmt(value),
                    style: TextStyle(
                      color: value == null ? Colors.grey : null,
                      fontWeight: value == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
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

                        // 1. TRAINER
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Trainer",
                            prefixIcon: Icon(Icons.school, color: _accent),
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

                        // 2. TRAINEE
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

                        // 4. START DATE — cannot be in the past
                        dateField(
                          label: "Start date",
                          value: startDate,
                          icon: Icons.play_circle_outline,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: startDate ?? _today,
                              firstDate: _today, // blocks past dates
                              lastDate: DateTime(2100),
                              helpText: 'Training start date',
                            );
                            if (picked != null) {
                              setSheetState(() {
                                startDate = picked;
                                // Keep the range coherent.
                                if (endDate != null &&
                                    endDate!.isBefore(picked)) {
                                  endDate = picked;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // 5. END DATE — cannot precede the start
                        dateField(
                          label: "End date",
                          value: endDate,
                          icon: Icons.flag_outlined,
                          onTap: () async {
                            final floor = startDate ?? _today;
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: endDate ?? floor,
                              firstDate: floor,
                              lastDate: DateTime(2100),
                              helpText: 'Training end date',
                            );
                            if (picked != null) {
                              setSheetState(() => endDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // 6. DESCRIPTION
                        TextField(
                          controller: descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Notes / Description (Optional)",
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                        const SizedBox(height: 32),

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
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("Cancel"),
                                ),
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
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  // --- validation (dialog still open, so
                                  //     dialogContext is safe to use) ---
                                  if (selectedTrainerId == null ||
                                      selectedTraineeId == null ||
                                      topicController.text.trim().isEmpty ||
                                      startDate == null ||
                                      endDate == null) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
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
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Trainer and Trainee cannot be the same person!",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  if (startDate!.isBefore(_today)) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Training cannot start in the past.",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  if (endDate!.isBefore(startDate!)) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "End date must be on or after the start date.",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  // 🚀 Capture these BEFORE popping. The old
                                  // code called ScaffoldMessenger.of(context)
                                  // after Navigator.pop, on a dead context.
                                  final navigator = Navigator.of(dialogContext);
                                  final messenger = ScaffoldMessenger.of(
                                    dialogContext,
                                  );
                                  final desc = descController.text.trim();

                                  navigator.pop();
                                  setState(() => _isLoading = true);

                                  try {
                                    await SupabaseService().createTraining(
                                      tenantId: _tenantId!,
                                      adminId: _currentUserId!,
                                      trainerId: selectedTrainerId!,
                                      traineeId: selectedTraineeId!,
                                      topic: topicController.text.trim(),
                                      startDate: startDate!,
                                      endDate: endDate!,
                                      description: desc.isEmpty ? null : desc,
                                    );

                                    await _fetchTrainings();

                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Training assigned successfully!",
                                        ),
                                        backgroundColor: _accent,
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint("Create training error: $e");
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text("Error: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    // 🚀 The old code never reset this on the
                                    // success path — hence the endless spinner.
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Assign Training",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
    ).then((_) {
      topicController.dispose();
      descController.dispose();
    });
  }

  Future<void> _openTraining(Map<String, dynamic> training) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingDetailsScreen(training: training),
      ),
    );
    if (changed == true) await _fetchTrainings();
  }

  // ==========================================
  // --- UI ---
  // ==========================================
  @override
  Widget build(BuildContext context) {
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
            onPressed: () async {
              setState(() => _isLoading = true);
              await _fetchTrainings();
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAssignTrainingDialog,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Assign Training",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _trainings.isEmpty
          ? _buildEmptyState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: _fetchTrainings,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 0 : 16,
                      vertical: 24,
                    ),
                    itemCount: _trainings.length,
                    itemBuilder: (context, index) =>
                        _buildTrainingCard(_trainings[index]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final trainerName = training['trainer']?['full_name'] ?? 'Unknown Trainer';
    final traineeName = training['trainee']?['full_name'] ?? 'Unknown Trainee';
    final topic = training['topic'] ?? 'No Topic';
    final status = training['status'] ?? 'pending';

    final start = _parseDate(training['start_date']);
    final end = _parseDate(training['end_date']);
    final dayCount = (start != null && end != null)
        ? end.difference(start).inDays + 1
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 🚀 Tap through to the management screen.
        onTap: () => _openTraining(training),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

              Row(
                children: [
                  Expanded(
                    child: _buildParticipantColumn(
                      title: "Trainer",
                      name: trainerName,
                      icon: Icons.school,
                      color: _accent,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(Icons.arrow_forward, color: Colors.grey),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.date_range,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${_fmt(start)} → ${_fmt(end)}",
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dayCount != null)
                    Text(
                      "$dayCount day${dayCount == 1 ? '' : 's'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final (bgColor, textColor) = switch (status) {
      'completed' => (Colors.green.withOpacity(0.1), Colors.green),
      'in_progress' => (Colors.orange.withOpacity(0.1), Colors.orange),
      'extended' => (Colors.purple.withOpacity(0.1), Colors.purple),
      'cancelled' => (Colors.red.withOpacity(0.1), Colors.red),
      _ => (Colors.blue.withOpacity(0.1), Colors.blue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
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
