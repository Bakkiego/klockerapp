import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';

/// The status pill used everywhere a record has a state.
///
/// Colours come from the theme extension, so the same badge reads
/// correctly in light and dark without a single literal at the call site.
class KStatusBadge extends StatelessWidget {
  /// Raw status value from the database. Case and spacing don't matter.
  final String? status;

  /// Override the displayed text. Defaults to the status with underscores
  /// replaced by spaces, upper-cased.
  final String? label;

  /// Optional leading icon.
  final IconData? icon;

  /// Slightly larger padding and text, for use as a page header badge
  /// rather than a list-row badge.
  final bool large;

  const KStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = context.status.forStatus(status);
    final text =
        label ?? (status ?? 'Unknown').replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(large ? 20 : 8),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? 16 : 12, color: fg),
            SizedBox(width: large ? 6 : 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
