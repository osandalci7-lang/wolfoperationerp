import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../employees/employees_screen.dart';
import '../safety/safety_screen.dart';
import '../ncr/ncr_screen.dart';
import '../vendors/vendors_screen.dart';
import '../planning/planning_screen.dart';
import '../certificates/certificates_screen.dart';
import '../financial/financial_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Web sidebar'daki tüm modüller
    final items = [
      _MenuItem(icon: Icons.people, label: 'Employees', color: AppColors.msPurple, screen: const EmployeesScreen()),
      _MenuItem(icon: Icons.shield, label: 'Safety', color: AppColors.msRed, screen: const SafetyScreen()),
      _MenuItem(icon: Icons.report_problem, label: 'NCR', color: AppColors.msOrange, screen: const NcrScreen()),
      _MenuItem(icon: Icons.business, label: 'Vendors', color: AppColors.msTeal, screen: const VendorsScreen()),
      _MenuItem(icon: Icons.calendar_month, label: 'Planning', color: AppColors.msBlue, screen: const PlanningScreen()),
      _MenuItem(icon: Icons.verified, label: 'Certificates', color: AppColors.msGreen, screen: const CertificatesScreen()),
      _MenuItem(icon: Icons.attach_money, label: 'Financial', color: const Color(0xFFd29922), screen: const FinancialScreen()),
      _MenuItem(icon: Icons.request_quote, label: 'Quotes', color: const Color(0xFF6366f1), screen: null),
      _MenuItem(icon: Icons.badge, label: 'Visitors', color: AppColors.msTeal, screen: null),
      _MenuItem(icon: Icons.group, label: 'Customers', color: AppColors.msBlue, screen: null),
      _MenuItem(icon: Icons.directions_boat, label: 'Ships', color: AppColors.navyDark, screen: null),
      _MenuItem(icon: Icons.settings, label: 'Settings', color: AppColors.textSecondary, screen: null),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                if (item.screen != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} - Coming soon'), backgroundColor: AppColors.bgCard),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(item.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? screen;

  const _MenuItem({required this.icon, required this.label, required this.color, required this.screen});
}
