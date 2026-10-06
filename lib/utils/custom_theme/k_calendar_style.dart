import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'k_palette.dart';

/// TableCalendar is a third-party widget — it doesn't read `ColorScheme`, so
/// its three style objects have to be built by hand or it falls back to the
/// package's own blue/grey defaults.
///
/// Two screens draw a calendar (the company itinerary and the home screen),
/// so these live here rather than being written twice and drifting apart.
///
/// Usage:
///   TableCalendar(
///     ...
///     calendarStyle: kCalendarStyle(context),
///     headerStyle: kCalendarHeaderStyle(context),
///     daysOfWeekStyle: kDaysOfWeekStyle(context),
///   )

CalendarStyle kCalendarStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final body = theme.textTheme.bodyMedium!;

  return CalendarStyle(
    // --- Day numbers -------------------------------------------------------
    defaultTextStyle: body.copyWith(color: scheme.onSurface),
    weekendTextStyle: body.copyWith(color: scheme.onSurfaceVariant),
    // Days bleeding in from the neighbouring month.
    outsideTextStyle: body.copyWith(color: scheme.outline),
    disabledTextStyle: body.copyWith(color: scheme.outline),
    holidayTextStyle: body.copyWith(color: scheme.onSurface),

    todayTextStyle: body.copyWith(
      color: scheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    ),
    selectedTextStyle: body.copyWith(
      color: scheme.onPrimary,
      fontWeight: FontWeight.bold,
    ),

    // --- Day backgrounds ---------------------------------------------------
    todayDecoration: BoxDecoration(
      color: scheme.primaryContainer,
      shape: BoxShape.circle,
    ),
    selectedDecoration: BoxDecoration(
      color: scheme.primary,
      shape: BoxShape.circle,
    ),

    // --- Event dots --------------------------------------------------------
    // Amber, matching the event accents elsewhere in the itinerary screen.
    markerDecoration: BoxDecoration(
      color: context.status.pendingFg,
      shape: BoxShape.circle,
    ),
    markersMaxCount: 3,
    markerSize: 5,
    markersAlignment: Alignment.bottomCenter,
    canMarkersOverflow: true,

    cellMargin: const EdgeInsets.all(6),
    outsideDaysVisible: true,
  );
}

HeaderStyle kCalendarHeaderStyle(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  return HeaderStyle(
    formatButtonVisible: true,
    titleCentered: true,
    headerPadding: const EdgeInsets.symmetric(vertical: 12),
    titleTextStyle: theme.textTheme.titleMedium!.copyWith(
      color: scheme.onSurface,
    ),
    leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
    rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
    formatButtonShowsNext: false,
    formatButtonTextStyle: theme.textTheme.labelMedium!.copyWith(
      color: scheme.onPrimaryContainer,
    ),
    formatButtonDecoration: BoxDecoration(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    formatButtonPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
  );
}

DaysOfWeekStyle kDaysOfWeekStyle(BuildContext context) {
  final theme = Theme.of(context);
  final style = theme.textTheme.labelMedium!.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );

  return DaysOfWeekStyle(weekdayStyle: style, weekendStyle: style);
}
