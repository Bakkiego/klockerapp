import 'package:flutter/material.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_review_screen.dart'; // Make sure these files exist!
import 'components/add_goal_screen.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

// 🚀 Notice the SingleTickerProviderStateMixin required for TabBars!
class _PerformanceScreenState extends State<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _avgScore = "0.0";
  String _goalsMet = "0%";
  List<dynamic> _activeGoals = [];

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes so we can rebuild the FAB dynamically
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || !_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _fetchMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPerformanceDashboard();
      if (mounted) {
        setState(() {
          _avgScore = data['avgScore'] ?? "0.0";
          _goalsMet = data['goalsMetPercentage'] ?? "0%";
          _activeGoals = data['activeGoals'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverviewTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Performance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 🚀 THE TAB BAR 🚀
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00A36C),
          labelColor: const Color(0xFF00A36C),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Overview & Reviews"),
            Tab(text: "Active Goals"),
          ],
        ),
      ),

      // 🚀 THE DYNAMIC FAB 🚀
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (isOverviewTab) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReviewScreen()),
            );
            if (result == true) _fetchMetrics();
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddGoalScreen()),
            );
            if (result == true) _fetchMetrics();
          }
        },
        backgroundColor: const Color(0xFF00A36C),
        foregroundColor: Colors.white,
        icon: Icon(isOverviewTab ? Icons.rate_review : Icons.flag),
        label: Text(
          isOverviewTab ? "Log Review" : "Create Goal",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // ==========================================
                // TAB 1: OVERVIEW & REVIEWS
                // ==========================================
                RefreshIndicator(
                  onRefresh: _fetchMetrics,
                  color: const Color(0xFF00A36C),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "Company Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              context,
                              "Avg Score",
                              "$_avgScore/10",
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _statCard(
                              context,
                              "Goals Met",
                              _goalsMet,
                              Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // You could add a list of recently logged reviews down here in the future!
                    ],
                  ),
                ),

                // ==========================================
                // TAB 2: ACTIVE GOALS
                // ==========================================
                RefreshIndicator(
                  onRefresh: _fetchMetrics,
                  color: const Color(0xFF00A36C),
                  child: _activeGoals.isEmpty
                      ? ListView(
                          // Using ListView so Pull-to-Refresh still works
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 64,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No Active Goals",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    "Set OKRs for your teams and employees.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _activeGoals.length,
                          itemBuilder: (context, index) {
                            final goal = _activeGoals[index];
                            final progress =
                                (goal['progress'] as num?)?.toDouble() ?? 0.0;
                            return _goalProgress(
                              goal['title'] ?? 'Unknown Goal',
                              progress,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Helper widget for the top stats
  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00A36C),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the goal progress bars
  Widget _goalProgress(String title, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A36C)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
