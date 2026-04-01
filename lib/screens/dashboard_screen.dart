import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'projects/projects_screen.dart';
import 'warehouse/warehouse_screen.dart';
import 'pms/pms_screen.dart';

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
    _PlaceholderScreen('More', Icons.menu),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1a73e8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.anchor, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('WolfOperation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: const Color(0xFF1a73e8),
              radius: 16,
              child: Text(
                (user?['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            color: const Color(0xFF161b22),
            itemBuilder: (_) => [
              PopupMenuItem(
                child:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => context.read<AuthService>().logout(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF161b22),
        indicatorColor: const Color(0xFF1a73e8).withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1a73e8)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.folder, color: Color(0xFF1a73e8)),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.build, color: Color(0xFF1a73e8)),
            label: 'PMS',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.warehouse, color: Color(0xFF1a73e8)),
            label: 'Warehouse',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.menu, color: Color(0xFF1a73e8)),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Coming soon...',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
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
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/dashboard', token);
    if (mounted) {
      setState(() {
        _dashboardData = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().user;

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
        : RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?['full_name'] ?? user?['username'] ?? 'User'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Norden Shipyard ERP',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: 'Active Projects',
                        value: '${_dashboardData?['active_projects'] ?? 0}',
                        icon: Icons.folder_open,
                        color: const Color(0xFF1a73e8),
                      ),
                      _StatCard(
                        title: 'PMS Overdue',
                        value: '${_dashboardData?['overdue_pms'] ?? 0}',
                        icon: Icons.build_circle,
                        color: Colors.red,
                      ),
                      _StatCard(
                        title: 'Pending NCR',
                        value: '${_dashboardData?['pending_ncr'] ?? 0}',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Pending Invoices',
                        value: '${_dashboardData?['pending_invoices'] ?? 0}',
                        icon: Icons.receipt_long,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Actions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _QuickAction(
                          icon: Icons.folder,
                          label: 'Projects',
                          color: const Color(0xFF1a73e8),
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.people,
                          label: 'Employees',
                          color: Colors.purple,
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.warehouse,
                          label: 'Warehouse',
                          color: Colors.teal,
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.build,
                          label: 'PMS',
                          color: Colors.orange,
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.shield,
                          label: 'Safety',
                          color: Colors.red,
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.receipt,
                          label: 'Invoices',
                          color: Colors.green,
                          onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Activity',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_dashboardData?['recent_activities'] != null)
                    ...(_dashboardData!['recent_activities'] as List)
                        .map((a) => _ActivityItem(activity: a)),
                ],
              ),
            ),
          );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1a73e8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(activity['description'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Text(activity['time'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
