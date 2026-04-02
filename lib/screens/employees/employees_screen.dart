import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/employees', token);
    if (mounted) {
      setState(() {
        _employees = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    var list = _employees;
    if (_statusFilter.isNotEmpty) {
      list = list.where((e) => (e['status'] ?? '').toString().toLowerCase() == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
        (e['name'] ?? '').toString().toLowerCase().contains(q) ||
        (e['position'] ?? '').toString().toLowerCase().contains(q) ||
        (e['department'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppColors.msGreen;
      case 'inactive':
        return AppColors.textSecondary;
      case 'on leave':
        return AppColors.msOrange;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(
        title: 'Employees (${_filtered.length})',
        showBack: true,
      ),
      body: Column(
        children: [
          AppSearchBar(hint: 'Search by name, position, department...', onChanged: (v) => setState(() => _searchQuery = v)),
          // Status filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(label: 'All', isActive: _statusFilter.isEmpty, onTap: () => setState(() => _statusFilter = '')),
                  const SizedBox(width: 6),
                  _Chip(label: 'Active', isActive: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = 'active')),
                  const SizedBox(width: 6),
                  _Chip(label: 'Inactive', isActive: _statusFilter == 'inactive', onTap: () => setState(() => _statusFilter = 'inactive')),
                  const SizedBox(width: 6),
                  _Chip(label: 'On Leave', isActive: _statusFilter == 'on leave', onTap: () => setState(() => _statusFilter = 'on leave')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final emp = _filtered[index];
                        final name = emp['name'] ?? '';
                        final initials = name.isNotEmpty ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase() : '?';

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => EmployeeDetailScreen(employeeId: emp['id'], employeeName: name),
                          )),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: emp['profile_photo'] != null && emp['profile_photo'].toString().isNotEmpty
                                      ? NetworkImage('${AppConstants.baseUrl}${emp['profile_photo']}')
                                      : null,
                                  child: emp['profile_photo'] == null || emp['profile_photo'].toString().isEmpty
                                      ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(emp['position'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      Text(emp['department'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                StatusBadge(text: emp['status'] ?? '', color: _statusColor(emp['status'])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// EMPLOYEE DETAIL — web'deki tab yapısı
// ═══════════════════════════════════════════════

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const EmployeeDetailScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _emp;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/employees/${widget.employeeId}', token);
    if (mounted) {
      setState(() {
        _emp = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _emp?['name'] ?? widget.employeeName;
    final initials = name.isNotEmpty ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.employeeName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Contracts'),
            Tab(text: 'Certificates'),
            Tab(text: 'Working Hours'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _GeneralTab(emp: _emp!, initials: initials),
                _ContractsTab(emp: _emp!),
                _CertificatesTab(emp: _emp!),
                _WorkingHoursTab(employeeId: widget.employeeId),
              ],
            ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  final String initials;
  const _GeneralTab({required this.emp, required this.initials});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar + name header
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            backgroundImage: emp['profile_photo'] != null && emp['profile_photo'].toString().isNotEmpty
                ? NetworkImage('${AppConstants.baseUrl}${emp['profile_photo']}')
                : null,
            child: emp['profile_photo'] == null || emp['profile_photo'].toString().isEmpty
                ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 12),
          Text(emp['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(emp['position'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 14)),
          if (emp['status'] != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: StatusBadge.fromStatus(emp['status'])),
          const SizedBox(height: 24),

          // Personal Info
          _InfoCard(title: 'Personal Information', rows: [
            InfoRow(label: 'Username', value: emp['username']),
            InfoRow(label: 'Email', value: emp['email']),
            InfoRow(label: 'Phone', value: emp['phone']),
          ]),
          const SizedBox(height: 12),

          // Role & Status
          _InfoCard(title: 'Role & Status', rows: [
            InfoRow(label: 'Position', value: emp['position']),
            InfoRow(label: 'Department', value: emp['department']),
            InfoRow(label: 'Role', value: emp['role']),
            InfoRow(label: 'Status', value: emp['status']),
          ]),
          const SizedBox(height: 12),

          // Contact
          _InfoCard(title: 'Contact Information', rows: [
            InfoRow(label: 'Emergency', value: emp['emergency_contact']),
            InfoRow(label: 'Address', value: emp['address']),
          ]),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const Divider(color: AppColors.border),
          ...rows.expand((r) => [r, const Divider(color: AppColors.border, height: 1)]).take(rows.length * 2 - 1),
        ],
      ),
    );
  }
}

class _ContractsTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _ContractsTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _InfoCard(title: 'Contract Information', rows: [
        InfoRow(label: 'Contract Start', value: emp['contract_start']?.toString()),
        InfoRow(label: 'Contract End', value: emp['contract_end']?.toString()),
        InfoRow(label: 'Annual Leave', value: '${emp['annual_leave_hours'] ?? '-'} hours'),
      ]),
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _CertificatesTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(icon: Icons.verified, message: 'Certificates coming soon');
  }
}

class _WorkingHoursTab extends StatefulWidget {
  final int employeeId;
  const _WorkingHoursTab({required this.employeeId});

  @override
  State<_WorkingHoursTab> createState() => _WorkingHoursTabState();
}

class _WorkingHoursTabState extends State<_WorkingHoursTab> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/working-hours/my', token);
    if (mounted) {
      setState(() {
        _data = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingState();
    if (_data == null) return const EmptyState(icon: Icons.access_time, message: 'No data');

    final entries = (_data!['entries'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Total Hours', value: '${toDouble(_data!['total_hours']).toStringAsFixed(1)}', color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Work Days', value: '${_data!['work_count'] ?? 0}', color: AppColors.msGreen)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Leave Days', value: '${_data!['leave_count'] ?? 0}', color: AppColors.msOrange)),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(e['work_date']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                const Spacer(),
                if (e['project_code'] != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(e['project_code'], style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                  ),
                Text('${toDouble(e['hours']).toStringAsFixed(1)}h',
                    style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
