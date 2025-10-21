import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

/// A custom calendar widget that starts in single-selection mode,
/// but switches to multi-selection mode upon a long press on any date.
class MultiSelectCalendar extends StatefulWidget {
  /// Callback function to notify the parent when the selected dates change.
  final ValueChanged<List<DateTime>> onDatesChanged;

  /// The color used to highlight selected days and controls.
  final Color highlightColor;

  /// The initial list of selected dates.
  final List<DateTime> initialSelectedDates;

  const MultiSelectCalendar({
    super.key,
    required this.onDatesChanged,
    this.initialSelectedDates = const [],
    this.highlightColor = Colors.blue,
  });

  @override
  State<MultiSelectCalendar> createState() => _MultiSelectCalendarState();
}

class _MultiSelectCalendarState extends State<MultiSelectCalendar> {
  // State 1: Tracks whether the long press has enabled multi-selection.
  bool _isMultiSelectMode = false;

  // State 2: Holds the list of currently selected dates.
  late List<DateTime> _selectedDates;

  @override
  void initState() {
    super.initState();
    // Initialize the list using a copy of the initial dates
    _selectedDates = List<DateTime>.from(widget.initialSelectedDates);
  }

  /// Helper function to update the internal state and notify the parent widget.
  // FIX 1: Accepts List<DateTime?> from the package's onValueChanged
  void _updateSelection(List<DateTime?> newDatesNullable) {
    // Filters out nulls and converts the list to List<DateTime>
    final newDates = newDatesNullable.whereType<DateTime>().toList();

    setState(() {
      _selectedDates = newDates;
    });
    // Passes the non-nullable list to the parent via the callback
    widget.onDatesChanged(newDates);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine the calendar type dynamically based on the state variable
    final calendarMode = _isMultiSelectMode
        ? CalendarDatePicker2Type.multi
        : CalendarDatePicker2Type.single;

    // 2. Configure the calendar appearance
    final config = CalendarDatePicker2Config(
      calendarType: calendarMode,
      selectedDayHighlightColor: widget.highlightColor,
      // Use the highlight color for text controls (like month arrows)
      controlsTextStyle: TextStyle(color: widget.highlightColor, fontSize: 16),
      selectedDayTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),

      // 3. The Custom Day Builder where the core logic resides
      // FIX 2: Correcting the signature to match the package's expected nullability.
      // We must declare all parameters that the package might pass, and use '?'
      // where the package's typedef indicates it's optional/nullable.
      dayBuilder:
          ({
            required DateTime date,
            int? itemIndex, // Removed 'required'
            bool? isSelected, // Removed 'required' and added '?'
            TextStyle? textStyle,
            BoxDecoration? decoration,
            bool? isToday, // Removed 'required' and added '?'
            bool? isCurrentDay, // Removed 'required' and added '?'
            bool? isDisabled, // Removed 'required' and added '?'
          }) {
            // We wrap the default day cell in a GestureDetector to capture custom gestures
            return GestureDetector(
              // === CORE LOGIC: LONG PRESS switches to multi-select ===
              onLongPress: () {
                // Only activate if we are currently in single-select mode
                if (!_isMultiSelectMode) {
                  // 1. Select the date that was long-pressed
                  _updateSelection([date]);

                  // 2. Switch the calendar mode state
                  setState(() {
                    _isMultiSelectMode = true;
                  });

                  // Optional: Provide feedback to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Multi-Select Mode Activated! Tap to select days.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },

              // === TAP: Handles selection based on current mode ===
              onTap: () {
                if (_isMultiSelectMode) {
                  // In multi-mode, we manually toggle the selection
                  final newDates = List<DateTime>.from(_selectedDates);
                  // Check if the date is already selected (by year, month, and day)
                  final existingIndex = newDates.indexWhere(
                    (d) =>
                        d.year == date.year &&
                        d.month == date.month &&
                        d.day == date.day,
                  );

                  if (existingIndex >= 0) {
                    // If selected, deselect it
                    newDates.removeAt(existingIndex);
                  } else {
                    // If not selected, select it
                    newDates.add(date);
                  }
                  // Cast is safe here because we ensure the list only contains non-null dates
                  // We pass the result back to _updateSelection as a List<DateTime?> just for consistency
                  // with the function signature, though it contains only non-nulls.
                  _updateSelection(newDates.cast<DateTime?>());
                } else {
                  // In single mode, a tap simply selects that single date
                  _updateSelection([date]);
                }
              },

              // The visual representation of the day
              child: Container(
                // Use the package's default decoration (which handles selection styling)
                decoration: decoration,
                child: Center(
                  child: Text(date.day.toString(), style: textStyle),
                ),
              ),
            );
          },
    );

    // 4. Return the configured CalendarDatePicker2
    return CalendarDatePicker2(
      config: config,
      value: _selectedDates,
      // onValueChanged now correctly receives the List<DateTime?> and passes it to the fixed _updateSelection
      onValueChanged: _updateSelection,
    );
  }
}
