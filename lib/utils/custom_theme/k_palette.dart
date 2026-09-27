import 'package:flutter/material.dart';

/// Raw colour values. Nothing outside this file should contain a hex code.
///
/// These are deliberately private to the theme layer — screens reference
/// `Theme.of(context).colorScheme.*` or `context.status.*`, never these.
class KPalette {
  KPalette._();

  // --- Brand -------------------------------------------------------------
  /// Fill colour. Buttons, progress bars, selected states.
  static const brand = Color(0xFF00A36C);

  /// Text colour. Same hue, darkened to clear WCAG AA (4.5:1) on white.
  /// The fill green fails at body size — use this wherever green is TEXT.
  static const brandText = Color(0xFF00875C);

  /// Lighter brand for text on dark surfaces.
  static const brandTextDark = Color(0xFF2ECC94);

  static const brandContainer = Color(0xFFDCEFE5);
  static const brandContainerDark = Color(0xFF0E3325);

  // --- Light surfaces (option C — faint green tint) -----------------------
  static const lightBackground = Color(0xFFF2F7F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFE9F0EC);
  static const lightBorder = Color(0xFFDDE4E0);
  static const lightTextPrimary = Color(0xFF10201A);
  static const lightTextSecondary = Color(0xFF5F7068);
  static const lightTextMuted = Color(0xFF7C8C85);

  // --- Dark surfaces (matches what the app already uses) ------------------
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1C1C1C);
  static const darkSurfaceVariant = Color(0xFF262626);
  static const darkBorder = Color(0xFF2E2E2E);
  static const darkTextPrimary = Color(0xFFF2F5F3);
  static const darkTextSecondary = Color(0xFFA8B3AD);
  static const darkTextMuted = Color(0xFF7D8983);
}

/// Status colours.
///
/// `ColorScheme` has slots for primary, error and so on, but nothing for
/// "pending approval" or "overtime". Those appear in at least six screens
/// and were previously written as `Colors.orange` / `Colors.red` literals,
/// which glare on a white card and can't adapt per mode.
///
/// Access with `context.status.pendingFg` — see the extension at the bottom.
@immutable
class KStatusColors extends ThemeExtension<KStatusColors> {
  final Color approvedBg, approvedFg;
  final Color pendingBg, pendingFg;
  final Color rejectedBg, rejectedFg;
  final Color overtimeBg, overtimeFg;
  final Color earlyLeaveBg, earlyLeaveFg;
  final Color neutralBg, neutralFg;

  const KStatusColors({
    required this.approvedBg,
    required this.approvedFg,
    required this.pendingBg,
    required this.pendingFg,
    required this.rejectedBg,
    required this.rejectedFg,
    required this.overtimeBg,
    required this.overtimeFg,
    required this.earlyLeaveBg,
    required this.earlyLeaveFg,
    required this.neutralBg,
    required this.neutralFg,
  });

  static const light = KStatusColors(
    approvedBg: Color(0xFFE3F4EC),
    approvedFg: Color(0xFF00603F),
    pendingBg: Color(0xFFFDF0DC),
    pendingFg: Color(0xFF8A5200),
    rejectedBg: Color(0xFFFBE9E9),
    rejectedFg: Color(0xFF9B2220),
    overtimeBg: Color(0xFFE4EEFA),
    overtimeFg: Color(0xFF1A4F8A),
    earlyLeaveBg: Color(0xFFEFE9F7),
    earlyLeaveFg: Color(0xFF5B3A8E),
    neutralBg: Color(0xFFEDEFF2),
    neutralFg: Color(0xFF4A525E),
  );

  static const dark = KStatusColors(
    approvedBg: Color(0xFF0E3325),
    approvedFg: Color(0xFF5DCAA5),
    pendingBg: Color(0xFF3A2A0A),
    pendingFg: Color(0xFFEFB45C),
    rejectedBg: Color(0xFF3A1514),
    rejectedFg: Color(0xFFF09595),
    overtimeBg: Color(0xFF0E2440),
    overtimeFg: Color(0xFF85B7EB),
    earlyLeaveBg: Color(0xFF221A38),
    earlyLeaveFg: Color(0xFFAFA9EC),
    neutralBg: Color(0xFF23262B),
    neutralFg: Color(0xFFA8AEB8),
  );

  /// Resolve a status string from the database to its colour pair.
  /// Keeps the mapping in one place instead of a switch in every widget.
  (Color bg, Color fg) forStatus(String? status) {
    final key = (status ?? '').toLowerCase().trim().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );

    switch (key) {
      // --- good / complete / present ---
      case 'approved':
      case 'paid':
      case 'completed':
      case 'on_time':
      case 'present':
      case 'active':
      case 'new':
      case 'fairly_new':
        return (approvedBg, approvedFg);

      // --- waiting / caution ---
      case 'pending':
      case 'draft':
      case 'scheduled':
      case 'late':
      case 'old':
      case 'fairly_used':
        return (pendingBg, pendingFg);

      // --- bad / blocked ---
      case 'rejected':
      case 'failed':
      case 'absent':
      case 'broken':
        return (rejectedBg, rejectedFg);

      // --- running / overtime ---
      case 'in_progress':
      case 'overtime_pending':
        return (overtimeBg, overtimeFg);

      // --- changed / exception ---
      case 'extended':
      case 'early_leave_pending':
      case 'early_leave_approved':
      case 'early_leave_pending_approval':
      case 'early_leave_rejected':
        return (earlyLeaveBg, earlyLeaveFg);

      // --- neutral ---
      case 'cancelled':
      case 'used':
      default:
        return (neutralBg, neutralFg);
    }
  }

  @override
  KStatusColors copyWith({
    Color? approvedBg,
    Color? approvedFg,
    Color? pendingBg,
    Color? pendingFg,
    Color? rejectedBg,
    Color? rejectedFg,
    Color? overtimeBg,
    Color? overtimeFg,
    Color? earlyLeaveBg,
    Color? earlyLeaveFg,
    Color? neutralBg,
    Color? neutralFg,
  }) {
    return KStatusColors(
      approvedBg: approvedBg ?? this.approvedBg,
      approvedFg: approvedFg ?? this.approvedFg,
      pendingBg: pendingBg ?? this.pendingBg,
      pendingFg: pendingFg ?? this.pendingFg,
      rejectedBg: rejectedBg ?? this.rejectedBg,
      rejectedFg: rejectedFg ?? this.rejectedFg,
      overtimeBg: overtimeBg ?? this.overtimeBg,
      overtimeFg: overtimeFg ?? this.overtimeFg,
      earlyLeaveBg: earlyLeaveBg ?? this.earlyLeaveBg,
      earlyLeaveFg: earlyLeaveFg ?? this.earlyLeaveFg,
      neutralBg: neutralBg ?? this.neutralBg,
      neutralFg: neutralFg ?? this.neutralFg,
    );
  }

  @override
  KStatusColors lerp(ThemeExtension<KStatusColors>? other, double t) {
    if (other is! KStatusColors) return this;
    return KStatusColors(
      approvedBg: Color.lerp(approvedBg, other.approvedBg, t)!,
      approvedFg: Color.lerp(approvedFg, other.approvedFg, t)!,
      pendingBg: Color.lerp(pendingBg, other.pendingBg, t)!,
      pendingFg: Color.lerp(pendingFg, other.pendingFg, t)!,
      rejectedBg: Color.lerp(rejectedBg, other.rejectedBg, t)!,
      rejectedFg: Color.lerp(rejectedFg, other.rejectedFg, t)!,
      overtimeBg: Color.lerp(overtimeBg, other.overtimeBg, t)!,
      overtimeFg: Color.lerp(overtimeFg, other.overtimeFg, t)!,
      earlyLeaveBg: Color.lerp(earlyLeaveBg, other.earlyLeaveBg, t)!,
      earlyLeaveFg: Color.lerp(earlyLeaveFg, other.earlyLeaveFg, t)!,
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      neutralFg: Color.lerp(neutralFg, other.neutralFg, t)!,
    );
  }
}

/// Convenience accessors so screens read cleanly.
///
///   context.status.approvedFg
///   context.brandText          // green that is safe as text in either mode
extension KThemeContext on BuildContext {
  KStatusColors get status =>
      Theme.of(this).extension<KStatusColors>() ?? KStatusColors.light;

  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Green for TEXT. Darker than the fill green in light mode so it
  /// clears contrast; lighter in dark mode for the same reason.
  Color get brandText => Theme.of(this).brightness == Brightness.dark
      ? KPalette.brandTextDark
      : KPalette.brandText;
}
