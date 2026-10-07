import 'package:flutter/material.dart';

/// A horizontal row of selectable filter pills.
///
/// The attendance and leave screens each had their own copy of this, written
/// out inline with hardcoded colours — and they'd already drifted apart in
/// padding and text weight. One widget keeps them in step.
///
///   KFilterPills(
///     filters: const ['All', 'Overtime', 'Early Leave'],
///     selected: _activeFilter,
///     onSelected: (f) => setState(() => _activeFilter = f),
///   )
class KFilterPills extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Padding around the scrolling row — give it the screen's horizontal
  /// inset so the first pill lines up with the content beside it.
  final EdgeInsetsGeometry padding;

  const KFilterPills({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;

          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
              ),
              child: Text(
                filter,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
