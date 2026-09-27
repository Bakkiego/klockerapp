import 'package:flutter/material.dart';
import 'package:klockerapp/utils/custom_theme/k_palette.dart';
import 'package:klockerapp/utils/widgets/k_status_badge.dart';

import '../main.dart';

/// Every themed component on one screen, in both modes.
///
/// A migration aid, not a product screen. Route to it while converting
/// hardcoded colours so you can check a token in two seconds instead of
/// clicking through the app. Delete it when the migration is done, or
/// keep it behind a debug flag — it is genuinely useful when adding a
/// component later.
///
/// Add a temporary route:
///   '/theme': (_) => const ThemePreviewScreen(),
///
/// Nothing in this file contains a colour literal. If something here
/// looks wrong, the theme is wrong — that is the point.
class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  bool _switchOn = true;
  String _chipSelection = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Dialog title'),
                content: const Text(
                  'Dialog body text. Check the background, the corner '
                  'radius, and that both text colours are legible.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              MyApp.themeMode.value =
                  Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Action'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _section(context, 'Mode'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          theme.brightness == Brightness.dark
                              ? 'Dark mode'
                              : 'Light mode',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        'Change your device theme to compare',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Colour scheme'),
              _swatches(context, [
                ('primary', scheme.primary, scheme.onPrimary),
                (
                  'primaryContainer',
                  scheme.primaryContainer,
                  scheme.onPrimaryContainer,
                ),
                ('surface', scheme.surface, scheme.onSurface),
                ('error', scheme.error, scheme.onError),
              ]),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 14, color: context.brandText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'context.brandText — use this whenever green is '
                          'text. The fill green fails contrast at body size '
                          'on a light surface.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.brandText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Typography'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Headline large',
                        style: theme.textTheme.headlineLarge,
                      ),
                      Text(
                        'Headline medium',
                        style: theme.textTheme.headlineMedium,
                      ),
                      Text('Title large', style: theme.textTheme.titleLarge),
                      Text('Title medium', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Body large — the quick brown fox.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        'Body medium — the quick brown fox.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Body small — the quick brown fox.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text('LABEL SMALL', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 12),
                      Text(
                        'Secondary text sits on onSurfaceVariant.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Status badges'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      KStatusBadge(status: 'approved'),
                      KStatusBadge(status: 'pending'),
                      KStatusBadge(status: 'rejected'),
                      KStatusBadge(status: 'in_progress'),
                      KStatusBadge(status: 'overtime_pending'),
                      KStatusBadge(status: 'early_leave_pending'),
                      KStatusBadge(status: 'extended'),
                      KStatusBadge(status: 'completed'),
                      KStatusBadge(status: 'cancelled'),
                      KStatusBadge(status: 'Present'),
                      KStatusBadge(status: 'Late'),
                      KStatusBadge(status: 'Absent'),
                      KStatusBadge(status: 'New'),
                      KStatusBadge(status: 'Fairly Used'),
                      KStatusBadge(status: 'Broken'),
                      KStatusBadge(status: 'paid'),
                      KStatusBadge(status: 'draft'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      KStatusBadge(
                        status: 'overtime_pending',
                        label: 'OVERTIME',
                        icon: Icons.timer_outlined,
                        large: true,
                      ),
                      SizedBox(width: 8),
                      KStatusBadge(
                        status: 'approved',
                        icon: Icons.check_circle_outline,
                        large: true,
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Buttons'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Elevated button'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('With icon'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: null,
                        child: const Text('Disabled'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Outlined button'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Text button'),
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Inputs'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          hintText: 'Hint text',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'With error',
                          errorText: 'Something is wrong',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: 'One',
                        decoration: const InputDecoration(
                          labelText: 'Dropdown',
                          prefixIcon: Icon(Icons.list),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'One', child: Text('One')),
                          DropdownMenuItem(value: 'Two', child: Text('Two')),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Chips'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: ['All', 'Pending', 'Approved', 'Rejected']
                        .map(
                          (c) => ChoiceChip(
                            label: Text(c),
                            selected: _chipSelection == c,
                            onSelected: (_) =>
                                setState(() => _chipSelection = c),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              _section(context, 'List tiles'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          'D',
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ),
                      title: const Text('Daniel Ayomidotun'),
                      subtitle: const Text('Architect · Downtown Office'),
                      trailing: const KStatusBadge(status: 'approved'),
                    ),
                    Divider(height: 1, color: scheme.outline),
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: scheme.primary),
                      title: const Text('Change password'),
                      subtitle: const Text(
                        'Update the password you sign in with',
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              _section(context, 'Progress and switches'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(value: 0.6),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('A setting'),
                        value: _switchOn,
                        onChanged: (v) => setState(() => _switchOn = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Pickers'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'These are the ones that broke before. No local '
                        'Theme() override here — if the calendar is legible, '
                        'the datePickerTheme is right.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Open date picker'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        ),
                        icon: const Icon(Icons.schedule),
                        label: const Text('Open time picker'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ),
                        icon: const Icon(Icons.date_range),
                        label: const Text('Open range picker'),
                      ),
                    ],
                  ),
                ),
              ),

              _section(context, 'Snackbar'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A message to the user')),
                    ),
                    child: const Text('Show snackbar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _swatches(BuildContext context, List<(String, Color, Color)> entries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: entries.map((e) {
            final (name, bg, fg) = e;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: fg),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
