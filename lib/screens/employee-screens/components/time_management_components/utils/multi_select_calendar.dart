import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

/// A custom calendar widget that starts in single-selection mode,
/// but switches to multi-selection mode via toggle switch or long-press.
class MultiSelectCalendar extends StatefulWidget {
  final ValueChanged<List<DateTime>> onDatesChanged;
  final Color highlightColor;
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
  bool _isMultiSelectMode = false;
  late List<DateTime> _selectedDates;

  @override
  void initState() {
    super.initState();
    _selectedDates = List<DateTime>.from(widget.initialSelectedDates);

    // Auto-enable multi-select mode if they pass in multiple dates initially
    if (_selectedDates.length > 1) {
      _isMultiSelectMode = true;
    }
  }

  void _updateSelection(List<DateTime?> newDatesNullable) {
    final newDates = newDatesNullable.whereType<DateTime>().toList();
    setState(() {
      _selectedDates = newDates;
    });
    widget.onDatesChanged(newDates);
  }

  @override
  Widget build(BuildContext context) {
    final calendarMode = _isMultiSelectMode
        ? CalendarDatePicker2Type.multi
        : CalendarDatePicker2Type.single;

    final config = CalendarDatePicker2Config(
      calendarType: calendarMode,
      selectedDayHighlightColor: widget.highlightColor,
      controlsTextStyle: TextStyle(color: widget.highlightColor, fontSize: 16),
      selectedDayTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      dayBuilder:
          ({
            required DateTime date,
            int? itemIndex,
            bool? isSelected,
            TextStyle? textStyle,
            BoxDecoration? decoration,
            bool? isToday,
            bool? isCurrentDay,
            bool? isDisabled,
          }) {
            return GestureDetector(
              // 🚀 Mobile Power User Feature: Retains the long-press functionality
              onLongPress: () {
                if (!_isMultiSelectMode) {
                  _updateSelection([date]);
                  setState(() => _isMultiSelectMode = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Multi-Select Mode Activated!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              onTap: () {
                if (_isMultiSelectMode) {
                  final newDates = List<DateTime>.from(_selectedDates);
                  final existingIndex = newDates.indexWhere(
                    (d) =>
                        d.year == date.year &&
                        d.month == date.month &&
                        d.day == date.day,
                  );

                  if (existingIndex >= 0) {
                    newDates.removeAt(existingIndex);
                  } else {
                    newDates.add(date);
                  }
                  _updateSelection(newDates);
                } else {
                  _updateSelection([date]);
                }
              },
              child: Container(
                decoration: decoration,
                child: Center(
                  child: Text(date.day.toString(), style: textStyle),
                ),
              ),
            );
          },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🚀 Web / Desktop UI Enhancment: The explicitly visible toggle switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Enable Multiple Dates",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Switch(
                activeColor: widget.highlightColor,
                value: _isMultiSelectMode,
                onChanged: (val) {
                  setState(() {
                    _isMultiSelectMode = val;
                    // Automatically clear previous extra dates if user turns toggle off
                    if (!val && _selectedDates.length > 1) {
                      _selectedDates = [_selectedDates.last];
                      _updateSelection(_selectedDates);
                    }
                  });
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        CalendarDatePicker2(
          config: config,
          value: _selectedDates,
          onValueChanged: _updateSelection,
        ),
      ],
    );
  }
}
