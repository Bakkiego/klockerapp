import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        // Open the native Flutter date picker
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2024), // Adjust based on your needs
          lastDate: DateTime(2030),
          builder: (context, child) {
            // Force the calendar to match your green theme
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? const ColorScheme.dark(
                        primary: Color(0xFF00A36C),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E1E1E),
                        onSurface: Colors.white,
                      )
                    : const ColorScheme.light(
                        primary: Color(0xFF00A36C),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
              ),
              child: child!,
            );
          },
        );

        // If they picked a date and didn't just hit cancel, trigger the callback
        if (picked != null && picked != initialDate) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFF00A36C).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🚀 FIX STEP 1: Wrap this inner row in an Expanded layout block
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF00A36C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 🚀 FIX STEP 2: Wrap the text widget in an Expanded layout block with ellipsis protection
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(initialDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Safe guard for tight spaces!
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ), // Little space block before drop-down arrow
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
