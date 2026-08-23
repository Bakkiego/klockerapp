import 'package:flutter/material.dart';

/// Dropdown that can offer a "create a new one" action inline.
///
/// Pass [onCreateNew] and an extra item appears at the bottom of the list.
/// Picking it fires the callback instead of selecting a value, so the parent
/// can show a dialog, save the new option, and refresh [items].
class KDropDownField extends StatelessWidget {
  /// Sentinel used for the create action. Never stored as a real value.
  static const createNewValue = '__k_create_new__';

  const KDropDownField({
    super.key,
    required this.items,
    required this.hintText,
    this.onChanged,
    this.value,
    this.icon = Icons.location_city,
    this.onCreateNew,
    this.createLabel,
    this.validator,
  });

  final List<String> items;
  final String hintText;
  final String? value;
  final IconData icon;
  final void Function(String?)? onChanged;

  /// When non-null, adds a create action to the bottom of the list.
  final VoidCallback? onCreateNew;

  /// Label for that action. Defaults to "Create a new one".
  final String? createLabel;

  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    // DropdownButtonFormField asserts that `value` matches exactly one item.
    // An employee whose stored title was later deleted would otherwise crash
    // this screen, so fall back to null when there's no match.
    final safeValue = (value != null && items.contains(value)) ? value : null;

    final canCreate = onCreateNew != null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      hint: Text(
        items.isEmpty && canCreate ? "None yet — tap to create one" : hintText,
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00A36C)),
        border: const OutlineInputBorder(),
      ),
      dropdownColor: Colors.grey,
      onChanged: (val) {
        if (val == createNewValue) {
          // Not a selection — run the create flow and leave the value alone.
          onCreateNew!.call();
          return;
        }
        onChanged?.call(val);
      },
      items: [
        ...items.map(
          (val) => DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(color: Colors.white)),
          ),
        ),
        if (canCreate)
          DropdownMenuItem<String>(
            value: createNewValue,
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF00A36C)),
                const SizedBox(width: 8),
                Text(
                  createLabel ?? "Create a new one",
                  style: const TextStyle(
                    color: Color(0xFF00A36C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
      validator:
          validator ??
          (val) {
            if (val == null || val.isEmpty || val == createNewValue) {
              return 'Please select an option';
            }
            return null;
          },
    );
  }
}
