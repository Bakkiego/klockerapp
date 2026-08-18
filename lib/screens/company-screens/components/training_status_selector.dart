import 'package:flutter/material.dart';

/// Status pill that doubles as a picker.
///
/// Renders like the read-only badge when [onSelected] is null, and grows a
/// chevron + tap target when it isn't. Selecting a status just reports it —
/// the parent decides what that means (extending needs a date, cancelling
/// needs a confirmation, and so on).
class TrainingStatusSelector extends StatelessWidget {
  static const statuses = <String>[
    'pending',
    'in_progress',
    'extended',
    'completed',
    'cancelled',
  ];

  final String status;
  final ValueChanged<String>? onSelected;
  final bool enabled;

  const TrainingStatusSelector({
    super.key,
    required this.status,
    this.onSelected,
    this.enabled = true,
  });

  static (Color bg, Color fg) colorsFor(String status) => switch (status) {
    'completed' => (Colors.green.withOpacity(0.12), Colors.green),
    'in_progress' => (Colors.orange.withOpacity(0.12), Colors.orange),
    'extended' => (Colors.purple.withOpacity(0.12), Colors.purple),
    'cancelled' => (Colors.red.withOpacity(0.12), Colors.red),
    _ => (Colors.blue.withOpacity(0.12), Colors.blue),
  };

  static String labelFor(String status) => switch (status) {
    'in_progress' => 'In Progress',
    'extended' => 'Extended',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => 'Pending',
  };

  static IconData iconFor(String status) => switch (status) {
    'in_progress' => Icons.play_arrow_rounded,
    'extended' => Icons.update_rounded,
    'completed' => Icons.check_circle_outline_rounded,
    'cancelled' => Icons.block_rounded,
    _ => Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colorsFor(status);
    final interactive = onSelected != null && enabled;

    final pill = Container(
      padding: EdgeInsets.only(
        left: 14,
        right: interactive ? 8 : 14,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelFor(status).toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (interactive) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, color: fg, size: 20),
          ],
        ],
      ),
    );

    if (!interactive) return pill;

    return PopupMenuButton<String>(
      tooltip: 'Change status',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final s in statuses)
          PopupMenuItem<String>(
            value: s,
            enabled: s != status,
            child: Row(
              children: [
                Icon(iconFor(s), size: 18, color: colorsFor(s).$2),
                const SizedBox(width: 12),
                Text(
                  labelFor(s),
                  style: TextStyle(
                    fontWeight: s == status
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (s == status) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}
