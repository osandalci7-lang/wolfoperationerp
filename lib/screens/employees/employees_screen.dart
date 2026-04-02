import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../core/constants.dart';

// ─── Light Theme Colors (web ile birebir) ───
const _bgPage = Color(0xFFF5F5F5);
const _bgWhite = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF323130);
const _textSecondary = Color(0xFF605e5c);
const _primary = Color(0xFF0078d4);
const _primaryHover = Color(0xFF106ebe);
const _border = Color(0xFFedebe9);
const _bgHeader = Color(0xFFfaf9f8);

Color _statusBgColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'active': return const Color(0xFFdff6dd);
    case 'inactive': return const Color(0xFFf3f2f1);
    case 'on leave': return const Color(0xFFfff4ce);
    default: return const Color(0xFFf3f2f1);
  }
}

Color _statusTextColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'active': return const Color(0xFF107c10);
    case 'inactive': return const Color(0xFF605e5c);
    case 'on leave': return const Color(0xFF986f0b);
    default: return const Color(0xFF605e5c);
  }
}

// ═══════════════════════════════════════════════
// EMPLOYEES LIST — web admin_employees.html
// ═══════════════════════════════════════════════

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<dynamic> _employees = [];
  bool _isLoading = true;
  String _search = '';
  String _statusFilter = '';
  String _positionFilter = '';
  String _departmentFilter = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/employees', token);
    if (mounted) setState(() { _employees = data['data'] ?? []; _isLoading = false; });
  }

  List<dynamic> get _filtered {
    var list = _employees;
    if (_statusFilter.isNotEmpty) {
      list = list.where((e) => (e['status'] ?? '').toString().toLowerCase() == _statusFilter.toLowerCase()).toList();
    }
    if (_positionFilter.isNotEmpty) {
      list = list.where((e) => (e['position'] ?? '').toString() == _positionFilter).toList();
    }
    if (_departmentFilter.isNotEmpty) {
      list = list.where((e) => (e['department'] ?? '').toString() == _departmentFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) => (e['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int get _activeCount => _employees.where((e) => (e['status'] ?? '').toString().toLowerCase() == 'active').length;

  Set<String> get _positions => _employees.map((e) => (e['position'] ?? '').toString()).where((p) => p.isNotEmpty).toSet();
  Set<String> get _departments => _employees.map((e) => (e['department'] ?? '').toString()).where((d) => d.isNotEmpty).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _bgWhite,
        elevation: 0,
        surfaceTintColor: _bgWhite,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text('Employees ($_activeCount Active)', style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Search + Filters — web'deki gibi
                  Container(
                    color: _bgWhite,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        // Search
                        SizedBox(
                          height: 36,
                          child: TextField(
                            style: const TextStyle(fontSize: 13, color: _textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search name...',
                              hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 18, color: _textSecondary),
                              filled: true,
                              fillColor: _bgWhite,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _primary)),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Filter dropdowns
                        Row(
                          children: [
                            Expanded(child: _FilterDropdown(
                              hint: 'All Statuses',
                              value: _statusFilter.isEmpty ? null : _statusFilter,
                              items: const ['Active', 'Inactive', 'On Leave'],
                              onChanged: (v) => setState(() => _statusFilter = v ?? ''),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _FilterDropdown(
                              hint: 'All Positions',
                              value: _positionFilter.isEmpty ? null : _positionFilter,
                              items: _positions.toList()..sort(),
                              onChanged: (v) => setState(() => _positionFilter = v ?? ''),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _FilterDropdown(
                              hint: 'All Depts',
                              value: _departmentFilter.isEmpty ? null : _departmentFilter,
                              items: _departments.toList()..sort(),
                              onChanged: (v) => setState(() => _departmentFilter = v ?? ''),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _border),

                  // Results count
                  Container(
                    color: _bgWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    child: Text('${_filtered.length} employees', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                  ),

                  // Employee list — web table as cards on mobile
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final emp = _filtered[index];
                        final name = emp['name'] ?? '';
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                        final hasPhoto = emp['profile_photo'] != null && emp['profile_photo'].toString().isNotEmpty;

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => EmployeeDetailScreen(employeeId: emp['id'], employeeName: name),
                          )),
                          child: Container(
                            color: _bgWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5))),
                            child: Row(
                              children: [
                                // Photo / Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFe8e8e8),
                                  backgroundImage: hasPhoto ? NetworkImage('${AppConstants.baseUrl}/static/photos/employees/${emp['profile_photo']}') : null,
                                  child: !hasPhoto ? Text(initial, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 16)) : null,
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${emp['position'] ?? ''} \u2022 ${emp['department'] ?? ''}',
                                      style: const TextStyle(color: _textSecondary, fontSize: 12)),
                                ])),
                                // Status badge — web'deki gibi
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(emp['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    emp['status'] ?? '',
                                    style: TextStyle(color: _statusTextColor(emp['status']), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        style: const TextStyle(fontSize: 12, color: _textPrimary),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _border)),
        ),
        hint: Text(hint, style: const TextStyle(fontSize: 12, color: _textSecondary)),
        items: [
          DropdownMenuItem<String>(value: null, child: Text(hint, style: const TextStyle(fontSize: 12, color: _textSecondary))),
          ...items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// EMPLOYEE DETAIL — web admin_employee_detail.html
// Tabs: Personal Details | Contracts | Certificates | Health | Assets
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
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/employees/${widget.employeeId}', token);
    if (mounted) setState(() { _emp = data['data']; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final name = _emp?['name'] ?? widget.employeeName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasPhoto = _emp?['profile_photo'] != null && _emp!['profile_photo'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: _bgPage,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                // Header with photo + name + status
                SliverAppBar(
                  backgroundColor: _bgWhite,
                  surfaceTintColor: _bgWhite,
                  iconTheme: const IconThemeData(color: _textPrimary),
                  expandedHeight: 180,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: _bgWhite,
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Photo
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFe8e8e8),
                            backgroundImage: hasPhoto ? NetworkImage('${AppConstants.baseUrl}/static/photos/employees/${_emp!['profile_photo']}') : null,
                            child: !hasPhoto ? Text(initial, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 28)) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(name, style: const TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${_emp?['position'] ?? ''} \u2022 ${_emp?['department'] ?? ''}', style: const TextStyle(color: _textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: _statusBgColor(_emp?['status']), borderRadius: BorderRadius.circular(12)),
                              child: Text(_emp?['status'] ?? '', style: TextStyle(color: _statusTextColor(_emp?['status']), fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ])),
                        ],
                      ),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: _primary,
                    labelColor: _primary,
                    unselectedLabelColor: _textSecondary,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    tabs: const [
                      Tab(text: 'Personal Details'),
                      Tab(text: 'Contracts'),
                      Tab(text: 'Certificates'),
                      Tab(text: 'Health'),
                      Tab(text: 'Assets'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _PersonalTab(emp: _emp!),
                  _ContractsTab(emp: _emp!),
                  _CertificatesTab(emp: _emp!),
                  _HealthTab(emp: _emp!),
                  _AssetsTab(emp: _emp!),
                ],
              ),
            ),
    );
  }
}

// ─── PERSONAL DETAILS TAB ───
class _PersonalTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _PersonalTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Information card
          _InfoCard(title: 'Personal Information', rows: [
            _InfoGrid(items: [
              _InfoItem(label: 'ID', value: '${emp['id']}'),
              _InfoItem(label: 'Name', value: emp['name']),
              _InfoItem(label: 'Username', value: emp['username']),
              _InfoItem(label: 'Email', value: emp['email']),
              _InfoItem(label: 'Phone', value: emp['phone']),
              _InfoItem(label: 'Language', value: emp['language']),
            ]),
          ]),
          const SizedBox(height: 12),

          // Role & Status card
          _InfoCard(title: 'Role & Status', rows: [
            _InfoGrid(items: [
              _InfoItem(label: 'Position', value: emp['position']),
              _InfoItem(label: 'Department', value: emp['department']),
              _InfoItem(label: 'Status', value: emp['status']),
              _InfoItem(label: 'Role', value: emp['role']),
            ]),
          ]),
          const SizedBox(height: 12),

          // Contract Information card
          _InfoCard(title: 'Contract Information', rows: [
            _InfoGrid(items: [
              _InfoItem(label: 'Contract Start', value: emp['contract_start']?.toString()),
              _InfoItem(label: 'Contract End', value: emp['contract_end']?.toString()),
              _InfoItem(label: 'Annual Leave', value: emp['annual_leave_hours'] != null ? '${emp['annual_leave_hours']} hours' : null),
            ]),
          ]),
          const SizedBox(height: 12),

          // Contact Information card
          _InfoCard(title: 'Contact Information', rows: [
            _InfoGrid(items: [
              _InfoItem(label: 'Emergency Contact', value: emp['emergency_contact']),
              _InfoItem(label: 'Address', value: emp['address']),
            ]),
          ]),
        ],
      ),
    );
  }
}

// ─── CONTRACTS TAB ───
class _ContractsTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _ContractsTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final contracts = (emp['contracts'] as List?) ?? [];
    final payslips = (emp['payslips'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contracts', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (contracts.isEmpty)
            _EmptyCard(message: 'No contracts')
          else
            ...contracts.map((c) => _DocCard(
              title: 'Contract',
              subtitle: '${c['start_date'] ?? '-'} \u2192 ${c['end_date'] ?? '-'}',
              icon: Icons.description,
            )),
          const SizedBox(height: 24),
          const Text('Payslips', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (payslips.isEmpty)
            _EmptyCard(message: 'No payslips')
          else
            ...payslips.map((p) => _DocCard(
              title: 'Payslip ${p['month']}/${p['year']}',
              subtitle: p['file_name'] ?? '',
              icon: Icons.receipt,
            )),
        ],
      ),
    );
  }
}

// ─── CERTIFICATES TAB ───
class _CertificatesTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _CertificatesTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final certs = (emp['certificates'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Certificates', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (certs.isEmpty)
            _EmptyCard(message: 'No certificates')
          else
            ...certs.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _bgWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['name'] ?? '', style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Issue Date', value: c['issue_date']?.toString()),
                  _DetailRow(label: 'Expiry Date', value: c['expiry_date']?.toString()),
                  _DetailRow(label: 'Issuer', value: c['issuer']),
                  const SizedBox(height: 8),
                  Row(children: [
                    _ActionBtn(label: 'View', color: _primary, bgColor: const Color(0xFFeff6fc), borderColor: const Color(0xFFc7e0f4)),
                  ]),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

// ─── HEALTH TAB ───
class _HealthTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _HealthTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final docs = (emp['health_documents'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Health Documents', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            _EmptyCard(message: 'No health documents')
          else
            ...docs.map((d) => _DocCard(
              title: d['name'] ?? 'Health Document',
              subtitle: 'Issued: ${d['issue_date'] ?? '-'} \u2022 ${d['issuer'] ?? ''}',
              icon: Icons.local_hospital,
            )),
        ],
      ),
    );
  }
}

// ─── ASSETS TAB ───
class _AssetsTab extends StatelessWidget {
  final Map<String, dynamic> emp;
  const _AssetsTab({required this.emp});

  @override
  Widget build(BuildContext context) {
    final assets = (emp['assets'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Assets', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (assets.isEmpty)
            _EmptyCard(message: 'No assigned assets')
          else
            ...assets.map((a) => _DocCard(
              title: a['asset_type'] ?? 'Asset',
              subtitle: 'Date: ${a['issue_date'] ?? '-'}',
              icon: Icons.devices,
            )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS — web EP card style
// ═══════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: _bgWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _bgHeader,
              border: Border(bottom: BorderSide(color: _border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Text(title, style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: Column(children: rows)),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: items.map((item) => SizedBox(
        width: (MediaQuery.of(context).size.width - 80) / 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.label, style: const TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(item.value ?? '-', style: const TextStyle(color: _textPrimary, fontSize: 13)),
          ],
        ),
      )),
    );
  }
}

class _InfoItem {
  final String label;
  final String? value;
  const _InfoItem({required this.label, this.value});
}

class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _DocCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _bgWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _textSecondary, fontSize: 12)),
          ])),
          Row(children: [
            _ActionBtn(label: 'View', color: _primary, bgColor: const Color(0xFFeff6fc), borderColor: const Color(0xFFc7e0f4)),
          ]),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  const _ActionBtn({required this.label, required this.color, required this.bgColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4), border: Border.all(color: borderColor)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _bgWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
      child: Center(child: Text(message, style: const TextStyle(color: _textSecondary, fontSize: 13))),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: _textSecondary, fontSize: 12))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(color: _textPrimary, fontSize: 12))),
        ],
      ),
    );
  }
}
