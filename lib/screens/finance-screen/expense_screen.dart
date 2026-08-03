import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase/repo/supabase_service.dart';
import 'components/expense_detail_screen.dart';
import 'components/add_expense_screen.dart';
import 'components/manage_categories_screen.dart'; // We will create this!

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allExpenses = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Filters
  DateTimeRange? _selectedDateRange;
  String _selectedCategory = "All";
  List<String> _categories = ["All"]; // Will fetch from DB

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Assuming SupabaseService has a way to get current user ID
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
      // 🚀 Fetch expenses AND categories simultaneously
      final results = await Future.wait([
        SupabaseService()
            .getAllTenantExpenses(), // You'll need to create this generic fetch
        SupabaseService().getExpenseCategories(), // Fetches custom categories
      ]);

      if (mounted) {
        setState(() {
          _allExpenses = results[0] as List<Map<String, dynamic>>;

          // Populate filter chips
          final fetchedCats = results[1] as List<Map<String, dynamic>>;
          _categories = [
            "All",
            ...fetchedCats.map((c) => c['category_name'].toString()),
          ];

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // --- DYNAMIC FILTERING LOGIC ---
  // --- DYNAMIC FILTERING LOGIC ---
  List<Map<String, dynamic>> _getFilteredExpenses({
    required bool showOnlyMyExpenses,
  }) {
    return _allExpenses.where((expense) {
      final isMyExpense = expense['profile_id'] == _currentUserId;

      // 1. Tab Filtering
      if (showOnlyMyExpenses && !isMyExpense) return false;
      if (!showOnlyMyExpenses && isMyExpense) return false;

      // 2. Category Filtering
      // 🚀 FIX: Look at 'payee' since that's where we saved the category string!
      final expCategory = expense['payee'] ?? 'Uncategorized';
      if (_selectedCategory != "All" && expCategory != _selectedCategory)
        return false;

      // 3. Date Range Filtering
      if (_selectedDateRange != null && expense['expense_date'] != null) {
        final expDate = DateTime.parse(expense['expense_date']);
        if (expDate.isBefore(_selectedDateRange!.start) ||
            expDate.isAfter(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final canManageExpenses = userProvider.can('manage_expenses');
    final currency = userProvider.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🚀 ONLY managers get the gear icon to manage categories
          if (canManageExpenses)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCategoriesScreen(),
                  ),
                );
                _initializeScreen(); // Refresh in case categories changed
              },
            ),
        ],
        bottom: canManageExpenses
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.red,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Team Expenses"),
                  Tab(text: "My Expenses"),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // --- FILTER BAR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories
                          .map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: _selectedCategory == cat,
                                selectedColor: Colors.red.withOpacity(0.2),
                                onSelected: (val) =>
                                    setState(() => _selectedCategory = cat),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.date_range,
                    color: _selectedDateRange != null
                        ? Colors.red
                        : Colors.grey,
                  ),
                  onPressed: _pickDateRange,
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _selectedDateRange = null),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- LIST VIEW ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : canManageExpenses
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExpenseList(
                        _getFilteredExpenses(showOnlyMyExpenses: false),
                        currency,
                      ),
                      _buildExpenseList(
                        _getFilteredExpenses(showOnlyMyExpenses: true),
                        currency,
                      ),
                    ],
                  )
                : _buildExpenseList(
                    _getFilteredExpenses(showOnlyMyExpenses: true),
                    currency,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
          if (result == true) _initializeScreen();
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Expense",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildExpenseList(
    List<Map<String, dynamic>> expenses,
    String currency,
  ) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text("No expenses found.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final amountStr = expense['amount']?.toString() ?? '0.00';
        String dateStr = expense['expense_date']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExpenseDetailScreen(expenseDetails: expense),
                ),
              );
              if (result == true) _initializeScreen();
            },
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.receipt_long, color: Colors.red),
            ),
            title: Text(
              // 🚀 FIX: Display 'payee' which holds the category name
              expense['payee'] ?? 'Uncategorized',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              dateStr,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Text(
              // 🚀 FIX: Injects the dynamic system currency from the provider
              "$currency$amountStr",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
