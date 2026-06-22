import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // 🚀 Added
import '../../../providers/user_provider.dart'; // 🚀 Added
import '../../../supabase/repo/supabase_service.dart';
import 'components/add_ticket_screen.dart';
import 'components/ticket_detail_screen.dart';

class TicketingScreen extends StatefulWidget {
  const TicketingScreen({super.key});

  @override
  State<TicketingScreen> createState() => _TicketingScreenState();
}

class _TicketingScreenState extends State<TicketingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = "";
  String _selectedStatus = "All";

  List<Map<String, dynamic>> _allTickets = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging || !_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _initializeScreen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);
    try {
      // 🚀 No need to fetch legacy roles anymore, our Provider handles security!
      final data = await SupabaseService().getTickets();
      if (mounted) {
        setState(() {
          _allTickets = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DYNAMIC FILTERING LOGIC ---
  List<Map<String, dynamic>> _getFilteredTickets({
    required bool showOnlyMyTickets,
  }) {
    return _allTickets.where((ticket) {
      final isMyTicket = ticket['employee_id'] == _currentUserId;

      // Filter by Ownership
      if (showOnlyMyTickets && !isMyTicket) return false;
      if (!showOnlyMyTickets && isMyTicket)
        return false; // Hides my tickets from the "Team" tab

      // Filter by Search Query
      final title = (ticket['title'] ?? '').toLowerCase();
      final category = (ticket['category'] ?? '').toLowerCase();
      final matchesSearch =
          title.contains(_searchQuery.toLowerCase()) ||
          category.contains(_searchQuery.toLowerCase());

      // Filter by Status Chip
      final status = ticket['status'] ?? 'Open';
      final matchesFilter =
          _selectedStatus == "All" || status == _selectedStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🚀 THE BOUNCER: Check if they are a Ticket Manager
    final userProvider = context.watch<UserProvider>();
    final canManageTickets = userProvider.can('manage_tickets');
    final canViewCompanyTickets = userProvider.can('view_company_tickets');

    // 🚀 COMBINED LOGIC: If they can manage OR view, they get the Team tab!
    final canSeeTeamTab = canManageTickets || canViewCompanyTickets;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Helpdesk",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 🚀 SMART UI: Show tabs if they have either permission
        bottom: canSeeTeamTab
            ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00A36C),
                labelColor: const Color(0xFF00A36C),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Team Tickets"),
                  Tab(text: "My Tickets"),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search issues or categories...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF00A36C)),
                ),
              ),
            ),
          ),

          // --- 2. STATUS FILTER CHIPS ---
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _filterChip("All"),
                const SizedBox(width: 10),
                _filterChip("Open"),
                const SizedBox(width: 10),
                _filterChip("Pending"),
                const SizedBox(width: 10),
                _filterChip("Resolved"),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // --- 3. SMART BODY RENDERING ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  )
                : canManageTickets
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketList(
                        _getFilteredTickets(showOnlyMyTickets: false),
                        "No Team Tickets",
                        "Your team hasn't submitted any issues.",
                      ),
                      _buildTicketList(
                        _getFilteredTickets(showOnlyMyTickets: true),
                        "No Personal Tickets",
                        "You haven't submitted any issues.",
                      ),
                    ],
                  )
                // If normal Employee, skip the TabView and just render their personal list directly!
                : _buildTicketList(
                    _getFilteredTickets(showOnlyMyTickets: true),
                    "No Tickets Yet",
                    "You haven't submitted any issues. Click below to start.",
                  ),
          ),
        ],
      ),

      // --- 4. FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTicketScreen()),
          );
          if (result == true) {
            // Only attempt to animate tabs if they actually have tabs!
            if (canManageTickets) _tabController.animateTo(1);
            _initializeScreen();
          }
        },
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Ticket",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildTicketList(
    List<Map<String, dynamic>> tickets,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(emptySubtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeScreen,
      color: const Color(0xFF00A36C),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          return _ticketCard(context, tickets[index]);
        },
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedStatus == label;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF00A36C),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : theme.dividerColor.withOpacity(0.1),
      ),
      onSelected: (bool selected) => setState(() => _selectedStatus = label),
    );
  }

  Widget _ticketCard(BuildContext context, Map<String, dynamic> ticket) {
    final theme = Theme.of(context);
    final status = ticket['status'] ?? 'Open';

    Color statusColor = status == "Open"
        ? Colors.redAccent
        : (status == "Resolved" ? Colors.green : Colors.orange);
    final employeeName = ticket['employee']?['full_name'] ?? 'Unknown User';
    final hasAttachment = ticket['attachment_url'] != null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: ticket),
          ),
        );
        _initializeScreen();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket['category'] ?? 'General',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket['title'] ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        ticket['priority'] ?? 'Low',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "By: $employeeName",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (hasAttachment) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attachment, size: 14, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        "Contains Attachment",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
