import 'package:flutter/material.dart';
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
    final items = [
      _MenuItem(icon: Icons.people, label: 'Employees', color: Colors.purple, screen: const EmployeesScreen()),
      _MenuItem(icon: Icons.shield, label: 'Safety', color: Colors.red, screen: const SafetyScreen()),
      _MenuItem(icon: Icons.warning_amber, label: 'NCR', color: Colors.orange, screen: const NcrScreen()),
      _MenuItem(icon: Icons.business, label: 'Vendors', color: Colors.teal, screen: const VendorsScreen()),
      _MenuItem(icon: Icons.calendar_month, label: 'Planning', color: const Color(0xFF1a73e8), screen: const PlanningScreen()),
      _MenuItem(icon: Icons.verified, label: 'Certificates', color: Colors.green, screen: const CertificatesScreen()),
      _MenuItem(icon: Icons.attach_money, label: 'Financial', color: Colors.amber, screen: const FinancialScreen()),
      _MenuItem(icon: Icons.request_quote, label: 'Quotes', color: Colors.indigo, screen: null),
      _MenuItem(icon: Icons.settings, label: 'Settings', color: Colors.grey, screen: null),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
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
                    SnackBar(
                      content: Text('${item.label} - Coming soon'),
                      backgroundColor: const Color(0xFF161b22),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.screen,
  });
}
