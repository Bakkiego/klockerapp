class LeaderSeats {
  final String tier;

  /// null = no cap configured for this tier.
  final int? limit;
  final int used;

  const LeaderSeats({
    required this.tier,
    required this.limit,
    required this.used,
  });

  bool get unlimited => limit == null;

  int get remaining => limit == null ? 9999 : (limit! - used);

  /// Already over the cap — possible for a tenant that downgraded, or
  /// one that existed before the caps were introduced. They aren't
  /// demoted, they just can't add more.
  bool get overCap => limit != null && used > limit!;

  bool get canAddLeader => limit == null || used < limit!;

  String get label => limit == null
      ? '$used admin/manager${used == 1 ? '' : 's'}'
      : '$used of $limit admin/manager seats used';
}
