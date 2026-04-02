import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import '../widgets/common.dart';
import 'projects/projects_screen.dart';
import 'employees/employees_screen.dart';
import 'warehouse/warehouse_screen.dart';
import 'pms/pms_screen.dart';
import 'more/more_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    ProjectsScreen(),
    PmsScreen(),
    WarehouseScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0xFF1a3a6b), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.anchor, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?['tenant_name'] ?? 'Norden', style: const TextStyle(color: Color(0xFF1a3a6b), fontSize: 14, fontWeight: FontWeight.w700)),
            const Text('ERP', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.grey), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.grey), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1a73e8),
              radius: 15,
              child: Text(
                (user?['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1a73e8),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'PMS'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse_outlined), activeIcon: Icon(Icons.warehouse), label: 'Warehouse'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final res = await ApiService.get('/dashboard', token);
    if (mounted) setState(() { _data = res['data']; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)));
    final ships = (_data?['ships_in_yard'] as List?) ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard başlık
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1a1a1a))),
            ),
            const SizedBox(height: 8),

            // Quick Actions Grid
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.5,
                children: [
                  _QuickAction(icon: Icons.people_outline, label: 'Employees', color: const Color(0xFF1a73e8), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen()))),
                  _QuickAction(icon: Icons.person_outline, label: 'Visitors', color: const Color(0xFF1a73e8), onTap: () {}),
                  _QuickAction(icon: Icons.folder_outlined, label: 'Projects', color: const Color(0xFF1a73e8), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()))),
                  _QuickAction(icon: Icons.directions_boat_outlined, label: 'Ships', color: const Color(0xFF1a73e8), onTap: () {}),
                  _QuickAction(icon: Icons.school_outlined, label: 'Trainings', color: const Color(0xFF1a73e8), onTap: () {}),
                  _QuickAction(icon: Icons.business_outlined, label: 'Customers', color: const Color(0xFF1a73e8), onTap: () {}),
                  _QuickAction(icon: Icons.assignment_outlined, label: 'Permits', color: const Color(0xFF1a73e8), onTap: () {}),
                  _QuickAction(icon: Icons.bar_chart_outlined, label: 'Financial', color: const Color(0xFF1a73e8), onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Ships in Yard
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Ships in Yard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1a1a1a))),
                    TextButton(onPressed: () {}, child: const Text('View →', style: TextStyle(color: Color(0xFF1a73e8), fontSize: 13))),
                  ]),
                  const Divider(height: 16),
                  if (ships.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No ships in yard', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...ships.map((ship) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ship['ship_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1a1a1a))),
                        const SizedBox(height: 2),
                        Text(ship['company_name'] ?? ship['customer'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('Berth: ${ship['berth'] ?? ship['location'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Divider(height: 16),
                      ]),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1a1a1a))),
        ]),
      ),
    );
  }
}
