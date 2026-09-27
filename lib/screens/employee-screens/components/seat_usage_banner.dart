import 'package:flutter/material.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';

class SeatUsageBanner extends StatefulWidget {
  /// Whether to show administrator seats rather than employee seats.
  final bool forAdmin;

  const SeatUsageBanner({super.key, this.forAdmin = false});

  @override
  State<SeatUsageBanner> createState() => _SeatUsageBannerState();
}

class _SeatUsageBannerState extends State<SeatUsageBanner> {
  Map<String, dynamic>? _usage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final usage = await SupabaseService().getSeatUsage();
      if (mounted)
        setState(() {
          _usage = usage;
          _isLoading = false;
        });
    } catch (e) {
      debugPrint('Seat usage error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _usage == null) return const SizedBox.shrink();

    final max = widget.forAdmin
        ? _usage!['max_admins']
        : _usage!['max_employees'];

    // Unlimited plan — nothing worth showing.
    if (max == null) return const SizedBox.shrink();

    final used =
        (widget.forAdmin ? _usage!['admins_used'] : _usage!['employees_used'])
            as int;
    final limit = max as int;
    final label = widget.forAdmin ? 'administrator' : 'employee';

    final atLimit = used >= limit;
    final nearLimit = !atLimit && used >= (limit * 0.8);

    final color = atLimit
        ? Colors.red
        : nearLimit
        ? Colors.orange
        : const Color(0xFF00A36C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            atLimit ? Icons.lock_outline : Icons.people_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$used of $limit ${label}s',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  atLimit
                      ? 'You have used every $label seat on the '
                            '${_usage!['tier']} plan.'
                      : '${limit - used} seat(s) remaining on the '
                            '${_usage!['tier']} plan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: limit == 0 ? 1 : (used / limit).clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
