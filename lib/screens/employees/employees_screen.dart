import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
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
    if (_searchQuery.isEmpty) return _employees;
    final q = _searchQuery.toLowerCase();
    return _employees.where((e) =>
      '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.toLowerCase().contains(q) ||
      (e['department'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Employees', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or department...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161b22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
                : RefreshIndicator(
                    onRefresh: _loadEmployees,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final emp = _filtered[index];
                        final name = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
                        final initials = '${(emp['first_name'] ?? '?')[0]}${(emp['last_name'] ?? '?')[0]}'.toUpperCase();
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeeDetailScreen(
                                employeeId: emp['id'],
                                employeeName: name,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF1a73e8),
                                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(emp['position'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text(emp['department'] ?? '', style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
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

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _employee;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEmployee();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployee() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/employees/${widget.employeeId}', token);
    if (mounted) {
      setState(() {
        _employee = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: Text(widget.employeeName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1a73e8),
          labelColor: const Color(0xFF1a73e8),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Working Hours'),
            Tab(text: 'Training'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(employee: _employee!),
                _WorkingHoursTab(employee: _employee!),
                _TrainingTab(employee: _employee!),
              ],
            ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> employee;
  const _OverviewTab({required this.employee});

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final initials = '${(employee['first_name'] ?? '?')[0]}${(employee['last_name'] ?? '?')[0]}'.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF1a73e8),
            backgroundImage: employee['profile_photo'] != null
                ? NetworkImage(employee['profile_photo'])
                : null,
            child: employee['profile_photo'] == null
                ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(employee['position'] ?? '', style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 14)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161b22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow('Department', employee['department']),
                const Divider(color: Colors.white12),
                _infoRow('Position', employee['position']),
                const Divider(color: Colors.white12),
                _infoRow('Email', employee['email']),
                const Divider(color: Colors.white12),
                _infoRow('Phone', employee['phone']),
                const Divider(color: Colors.white12),
                _infoRow('Start Date', employee['start_date']),
                const Divider(color: Colors.white12),
                _infoRow('Employee ID', employee['employee_number']?.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingHoursTab extends StatelessWidget {
  final Map<String, dynamic> employee;
  const _WorkingHoursTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    final hours = employee['working_hours'] as Map<String, dynamic>? ?? {};
    final totalHours = _toDouble(hours['total_hours']);
    final overtimeHours = _toDouble(hours['overtime_hours']);
    final daysWorked = _toDouble(hours['days_worked']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Month Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Total Hours', value: totalHours.toStringAsFixed(1), color: const Color(0xFF1a73e8))),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Overtime', value: overtimeHours.toStringAsFixed(1), color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Days Worked', value: daysWorked.toStringAsFixed(0), color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Avg/Day', value: daysWorked > 0 ? (totalHours / daysWorked).toStringAsFixed(1) : '0', color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          if (hours['daily'] != null) ...[
            const Text('Daily Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(hours['daily'] as List).map((d) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161b22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(d['date'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('${_toDouble(d['hours']).toStringAsFixed(1)}h', style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  final Map<String, dynamic> employee;
  const _TrainingTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    final trainings = employee['trainings'] as List? ?? [];
    if (trainings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text('No training records', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trainings.length,
      itemBuilder: (context, index) {
        final t = trainings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['name'] ?? t['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(t['completed_date'] ?? t['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (t['certificate'] != null)
                const Icon(Icons.verified, color: Color(0xFF1a73e8), size: 20),
            ],
          ),
        );
      },
    );
  }
}
