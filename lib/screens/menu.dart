import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_item_design.dart';
import 'package:klockerapp/components/menu_expansion_tile.dart';
import 'package:klockerapp/screens/employee-screens/time_management.dart';
import 'package:klockerapp/screens/hr-screens/announcements_screen.dart';
import 'package:klockerapp/screens/hr-screens/awards_screen.dart';
import 'package:klockerapp/screens/hr-screens/promotion_screen.dart';
import 'package:klockerapp/screens/hr-screens/resignation_screen.dart';
import 'package:klockerapp/screens/hr-screens/termination_screen.dart';
import 'package:klockerapp/screens/hr-screens/transfer_screen.dart';
import 'package:klockerapp/screens/hr-screens/warning_screen.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';
import 'company-screens/branch_screen.dart';
import 'company-screens/department_screen.dart';
import 'company-screens/payslip_screen.dart';
import 'company-screens/salary_screen.dart';
import 'package:klockerapp/screens/employee-screens/employees.dart';
import 'package:klockerapp/screens/finance-screen/accounts_list_screen.dart';
import 'package:klockerapp/screens/finance-screen/deposit_screen.dart';
import 'package:klockerapp/screens/finance-screen/expense_screen.dart';
import 'package:klockerapp/screens/finance-screen/payee_screen.dart';
import 'package:klockerapp/screens/finance-screen/payers_screen.dart';
import 'package:klockerapp/screens/finance-screen/transfer_balance_screen.dart';
import 'package:klockerapp/screens/finance-screen/company_screen.dart';
import 'package:klockerapp/screens/finance-screen/report_screen.dart';
import 'package:klockerapp/screens/help-screens/settings_screen.dart';
import 'package:klockerapp/screens/help-screens/help_screen.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    List<MenuExpansionOBJ> hrmList = [
      MenuExpansionOBJ(
        title: 'Awards',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AwardsScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Termination',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TerminationScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Transfer',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransferScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Warning',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WarningScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Announcements',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnnouncementsScreen(),
            ),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Promotion',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromotionScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Resignation',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResignationScreen()),
          );
        },
      ),
    ];
    List<MenuExpansionOBJ> financeList = [
      MenuExpansionOBJ(
        title: 'Accounts List',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountsListScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Payee',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayeeScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Payers',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayersScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Deposit',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DepositScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Expense',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: 'Transfer Balance',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageTransferScreen(),
            ),
          );
        },
      ),
    ];
    List<MenuExpansionOBJ> companyList = [
      MenuExpansionOBJ(
        title: 'Branch & Departments',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CompanyScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: "Salary",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalaryScreen()),
          );
        },
      ),
      MenuExpansionOBJ(
        title: "Payslip",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PayslipScreen()),
          );
        },
      ),
    ];
    return ListView(
      children: [
        Title(
          color: Colors.white,
          child: Text('Menu', style: KAppTextTheme.darkTextTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Employee',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuItemDesign('Employee', Icons.person, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Employees()),
          );
        }),
        MenuItemDesign('Time Management', Icons.timer, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimeManagement()),
          );
        }),
        // MenuItemDesign('HRM', Icons.perm_contact_calendar, () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => const Employees()),
        //   );
        // })
        MenuExpansionTile(hrmList, "HRM", Icons.perm_contact_calendar),
        SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Finances',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuExpansionTile(financeList, "Finance", Icons.monetization_on),
        MenuExpansionTile(companyList, "Company", Icons.business),
        MenuItemDesign(
          'Report',
          Icons.auto_graph_rounded,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportScreen()),
            ),
          },
        ),
        SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Help',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuItemDesign(
          'Support',
          Icons.add_ic_call_outlined,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          },
        ),
        MenuItemDesign(
          'Help',
          Icons.add_comment,
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            ),
          },
        ),
      ],
    );
  }
}
