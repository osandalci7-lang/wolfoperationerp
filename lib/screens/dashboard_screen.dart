import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';
import 'projects/projects_screen.dart';
import 'warehouse/warehouse_screen.dart';
import 'pms/pms_screen.dart';
import 'more/more_screen.dart';
import 'employees/employees_screen.dart';
import 'safety/safety_screen.dart';
import 'ncr/ncr_screen.dart';

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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.anchor, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('WolfOperation',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Text(
                (user?['name'] ?? user?['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            color: AppColors.bgCard,
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                onTap: () => context.read<AuthService>().logout(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bgCard,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.folder, color: AppColors.primary),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.build, color: AppColors.primary),
            label: 'PMS',
          ),
          NavigationDestination(
            icon: Icon(Icons.warehouse_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.warehouse, color: AppColors.primary),
            label: 'Warehouse',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.menu, color: AppColors.primary),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HOME TAB — web dashboard ile birebir
// ═══════════════════════════════════════════════

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/dashboard', token);
    if (mounted) {
      setState(() {
        _data = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().user;

    return _isLoading
        ? const LoadingState()
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User greeting
                  Text(
                    'Welcome, ${user?['name'] ?? user?['username'] ?? 'User'}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['position'] ?? 'Norden Shipyard ERP',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // HR Stats — web'deki 5'li grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: 'Active Projects',
                        value: '${_data?['active_projects'] ?? 0}',
                        icon: Icons.folder_open,
                        color: AppColors.msBlue,
                      ),
                      StatCard(
                        title: 'PMS Overdue',
                        value: '${_data?['overdue_pms'] ?? 0}',
                        icon: Icons.build_circle,
                        color: AppColors.msRed,
                      ),
                      StatCard(
                        title: 'Pending NCR',
                        value: '${_data?['pending_ncr'] ?? 0}',
                        icon: Icons.warning_amber,
                        color: AppColors.msOrange,
                      ),
                      StatCard(
                        title: 'Pending Invoices',
                        value: '${_data?['pending_invoices'] ?? 0}',
                        icon: Icons.receipt_long,
                        color: AppColors.msPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions — web'deki module links
                  const SectionHeader(title: 'Quick Actions'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _QuickAction(icon: Icons.folder, label: 'Projects', color: AppColors.msBlue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()))),
                      _QuickAction(icon: Icons.people, label: 'Employees', color: AppColors.msPurple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen()))),
                      _QuickAction(icon: Icons.warehouse, label: 'Warehouse', color: AppColors.msTeal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseScreen()))),
                      _QuickAction(icon: Icons.build, label: 'PMS', color: AppColors.msOrange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PmsScreen()))),
                      _QuickAction(icon: Icons.shield, label: 'Safety', color: AppColors.msRed,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyScreen()))),
                      _QuickAction(icon: Icons.report_problem, label: 'NCR', color: AppColors.danger,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NcrScreen()))),
                      _QuickAction(icon: Icons.directions_boat, label: 'Ships', color: AppColors.msTeal,
                          onTap: () {}),
                      _QuickAction(icon: Icons.attach_money, label: 'Financial', color: AppColors.msGreen,
                          onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Low stock alert
                  if (toInt(_data?['low_stock_alerts']) > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.msOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.msOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory, color: AppColors.msOrange, size: 20),
                          const SizedBox(width: 10),
                          Text('${_data?['low_stock_alerts']} low stock items',
                              style: const TextStyle(color: AppColors.msOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Activity
                  const SectionHeader(title: 'Recent Activity'),
                  if (_data?['recent_activities'] != null)
                    ...(_data!['recent_activities'] as List).map((a) => _ActivityItem(activity: a)),
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11), textAlign: TextAlign.center),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity['project_code'] != null)
                  Text('[${activity['project_code']}] ${activity['project_title'] ?? ''}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  activity['note_text'] ?? activity['description'] ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (activity['author_name'] != null)
                      Text(activity['author_name'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    if (activity['note_type'] != null) ...[
                      const SizedBox(width: 8),
                      StatusBadge(text: activity['note_type'], color: AppColors.primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (activity['created_at'] != null)
            Text(_formatTime(activity['created_at']),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatTime(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${d.day}/${d.month}';
    } catch (_) {
      return dt.length > 10 ? dt.substring(0, 10) : dt;
    }
  }
}
