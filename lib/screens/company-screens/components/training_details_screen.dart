import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klockerapp/screens/company-screens/components/training_status_selector.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

/// Manage a single existing training: start it, extend it, complete it,
/// cancel it, or edit its details.
///
/// Pops with `true` when something changed, so the caller knows to refresh.
class TrainingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> training;

  const TrainingDetailsScreen({super.key, required this.training});

  @override
  State<TrainingDetailsScreen> createState() => _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends State<TrainingDetailsScreen> {
  static const _accent = Color(0xFF00A36C);

  final _service = SupabaseService();

  late Map<String, dynamic> _training;
  bool _isBusy = false;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _training = Map<String, dynamic>.from(widget.training);
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  String get _id => _training['id'] as String;
  String get _topic => _training['topic'] ?? 'No Topic';
  String get _status => _training['status'] ?? 'pending';

  DateTime? get _startDate => _parseDate(_training['start_date']);
  DateTime? get _endDate => _parseDate(_training['end_date']);
  DateTime? get _originalEndDate => _parseDate(_training['original_end_date']);

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _fmt(DateTime? d) =>
      d == null ? '—' : DateFormat('MMM d, yyyy').format(d);

  void _toast(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// Wraps a service call with busy state, error reporting and a local refresh
  /// of the record so the screen reflects the change without a round trip.
  Future<void> _run(
    Future<void> Function() action, {
    required Map<String, dynamic> optimisticPatch,
    required String successMessage,
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _training.addAll(optimisticPatch);
        _didChange = true;
        _isBusy = false;
      });
      _toast(successMessage, color: _accent);
    } catch (e) {
      debugPrint('Training action failed: $e');
      if (mounted) setState(() => _isBusy = false);
      _toast('Error: $e', color: Colors.red);
    }
  }

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  Future<void> _setStatus(String status) async {
    await _run(
      () => _service.updateTrainingStatus(
        trainingId: _id,
        status: status,
        topic: _topic,
        trainerId: _training['trainer_id'],
        traineeId: _training['trainee_id'],
      ),
      optimisticPatch: {'status': status},
      successMessage: 'Training marked ${_label(status).toLowerCase()}',
    );
  }

  Future<void> _extend() async {
    final current = _endDate;
    if (current == null) return;

    // Can't extend to a date that's already passed, and an "extension" that
    // moves the end date earlier isn't an extension.
    final earliest = current.isAfter(_today) ? current : _today;

    final picked = await showDatePicker(
      context: context,
      initialDate: earliest.add(const Duration(days: 1)),
      firstDate: earliest.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      helpText: 'New end date',
    );
    if (picked == null) return;

    await _run(
      () => _service.extendTraining(
        trainingId: _id,
        newEndDate: picked,
        currentEndDate: current,
        originalEndDate: _originalEndDate,
        topic: _topic,
        trainerId: _training['trainer_id'],
        traineeId: _training['trainee_id'],
      ),
      optimisticPatch: {
        'end_date': DateFormat('yyyy-MM-dd').format(picked),
        'original_end_date': DateFormat(
          'yyyy-MM-dd',
        ).format(_originalEndDate ?? current),
        'status': 'extended',
      },
      successMessage: 'Extended to ${_fmt(picked)}',
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await _confirm(
      title: 'Cancel this training?',
      body: 'Both the trainer and trainee will be notified.',
      confirmLabel: 'Cancel training',
      danger: true,
    );
    if (ok) await _setStatus('cancelled');
  }

  Future<void> _onStatusSelected(String next) async {
    if (next == _status) return;

    switch (next) {
      case 'extended':
        await _extend(); // opens the date picker, sets status itself
        break;
      case 'cancelled':
        await _confirmCancel();
        break;
      default:
        await _setStatus(next);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await _confirm(
      title: 'Delete this training?',
      body: 'This permanently removes the record. It cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;

    setState(() => _isBusy = true);
    try {
      await _service.deleteTraining(_id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _isBusy = false);
      _toast('Error: $e', color: Colors.red);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? Colors.red : _accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final trainerName = _training['trainer']?['full_name'] ?? 'Unknown Trainer';
    final traineeName = _training['trainee']?['full_name'] ?? 'Unknown Trainee';
    final description = (_training['description'] ?? '').toString().trim();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _didChange);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Manage Training',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isBusy ? null : _confirmDelete,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _topic,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TrainingStatusSelector(
                      status: _status,
                      enabled: !_isBusy,
                      onSelected: _onStatusSelected,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _Card(
                  child: Column(
                    children: [
                      _row(Icons.school, 'Trainer', trainerName, _accent),
                      const Divider(height: 24),
                      _row(
                        Icons.person,
                        'Trainee',
                        traineeName,
                        Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _Card(
                  child: Column(
                    children: [
                      _row(
                        Icons.play_circle_outline,
                        'Starts',
                        _fmt(_startDate),
                        Colors.grey,
                      ),
                      const Divider(height: 24),
                      _row(
                        Icons.flag_outlined,
                        'Ends',
                        _fmt(_endDate),
                        Colors.grey,
                      ),
                      if (_originalEndDate != null) ...[
                        const Divider(height: 24),
                        _row(
                          Icons.history,
                          'Originally ended',
                          _fmt(_originalEndDate),
                          Colors.orange,
                        ),
                      ],
                      if (_startDate != null && _endDate != null) ...[
                        const Divider(height: 24),
                        _row(
                          Icons.calendar_today,
                          'Length',
                          '${_endDate!.difference(_startDate!).inDays + 1} day(s)',
                          Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(description),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                if (_isBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else if (isMobile)
                  Center(
                    child: Text(
                      'Tap the status above to update this training',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'ACTIONS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildActions(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Which actions make sense depends on where the training currently is.
  List<Widget> _buildActions() {
    final widgets = <Widget>[];

    void add(String label, IconData icon, VoidCallback onTap, {Color? color}) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    switch (_status) {
      case 'pending':
        add(
          'Mark as in progress',
          Icons.play_arrow,
          () => _setStatus('in_progress'),
        );
        add('Extend end date', Icons.update, _extend, color: Colors.orange);
        add('Cancel training', Icons.block, _confirmCancel, color: Colors.red);
        break;

      case 'in_progress':
      case 'extended':
        add(
          'Mark as completed',
          Icons.check_circle,
          () => _setStatus('completed'),
        );
        add('Extend end date', Icons.update, _extend, color: Colors.orange);
        add('Cancel training', Icons.block, _confirmCancel, color: Colors.red);
        break;

      case 'completed':
        add(
          'Re-open as in progress',
          Icons.restart_alt,
          () => _setStatus('in_progress'),
          color: Colors.blueGrey,
        );
        break;

      case 'cancelled':
        add(
          'Restore to pending',
          Icons.restore,
          () => _setStatus('pending'),
          color: Colors.blueGrey,
        );
        break;
    }

    return widgets;
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _label(String status) => switch (status) {
    'in_progress' => 'In Progress',
    'extended' => 'Extended',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => 'Pending',
  };
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}
