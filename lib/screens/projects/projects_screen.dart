import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> _projects = [];
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
    final query = _statusFilter.isNotEmpty ? '/projects?status=$_statusFilter' : '/projects';
    final data = await ApiService.get(query, token);
    if (mounted) {
      setState(() {
        _projects = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _projects;
    final q = _searchQuery.toLowerCase();
    return _projects.where((p) =>
      (p['project_title'] ?? '').toString().toLowerCase().contains(q) ||
      (p['project_code'] ?? '').toString().toLowerCase().contains(q) ||
      (p['ship_name'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  // Web'deki status renkleri
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return AppColors.msGreen;
      case 'in progress':
        return const Color(0xFF835b00);
      case 'waiting customer':
        return AppColors.textSecondary;
      case 'closed':
        return AppColors.msRed;
      case 'active':
        return AppColors.msGreen;
      case 'on hold':
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
        title: 'Projects',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Status filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search projects...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isActive: _statusFilter.isEmpty, onTap: () { setState(() { _statusFilter = ''; _isLoading = true; }); _load(); }),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Open', isActive: _statusFilter == 'open', onTap: () { setState(() { _statusFilter = 'open'; _isLoading = true; }); _load(); }),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'In Progress', isActive: _statusFilter == 'in progress', onTap: () { setState(() { _statusFilter = 'in progress'; _isLoading = true; }); _load(); }),
                  const SizedBox(width: 6),
                  _FilterChip(label: 'Closed', isActive: _statusFilter == 'closed', onTap: () { setState(() { _statusFilter = 'closed'; _isLoading = true; }); _load(); }),
                ],
              ),
            ),
          ),
          // Project list
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final p = _filtered[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProjectDetailScreen(projectId: p['id'], projectTitle: p['project_title'] ?? ''),
                          )),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(p['project_code'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(p['status']).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(p['status'] ?? '', style: TextStyle(color: _statusColor(p['status']), fontSize: 11)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(p['project_title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                if (p['ship_name'] != null || p['ship_full_name'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.directions_boat, color: AppColors.textSecondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(p['ship_full_name'] ?? p['ship_name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ]),
                                ],
                                if (p['berth'] != null) ...[
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.location_on, color: AppColors.textSecondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text(p['berth'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ]),
                                ],
                                if (p['entry_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${p['entry_date'] ?? ''} \u2192 ${p['exit_date'] ?? 'ongoing'}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ]),
                                ],
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

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
// PROJECT DETAIL — web'deki 5-tab yapısı
// ═══════════════════════════════════════════════

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  const ProjectDetailScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/projects/${widget.projectId}', token);
    if (mounted) {
      setState(() {
        _project = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectTitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            if (_project?['project_code'] != null)
              Text(_project!['project_code'], style: const TextStyle(color: AppColors.primary, fontSize: 11)),
          ],
        ),
        actions: [
          if (_project?['status'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: StatusBadge.fromStatus(_project!['status'])),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
            Tab(text: 'Documents'),
            Tab(text: 'Permits'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(project: _project!),
                _NotesTab(projectId: widget.projectId, notes: _project!['notes'] ?? []),
                _DocumentsTab(documents: _project!['documents'] ?? []),
                _PermitsTab(permits: _project!['permits'] ?? []),
                _ReportsTab(),
              ],
            ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> project;
  const _OverviewTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            InfoRow(label: 'Code', value: project['project_code']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Status', value: project['status']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Ship', value: project['ship_name']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Customer', value: project['customer_name']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Project Leader', value: project['project_leader'] ?? project['project_manager']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Berth', value: project['berth']),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Entry Date', value: project['entry_date']?.toString()),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Exit Date', value: project['exit_date']?.toString()),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Tonnage', value: project['tonnage']?.toString()),
            const Divider(color: AppColors.border, height: 1),
            InfoRow(label: 'Flag', value: project['flag']),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends StatefulWidget {
  final int projectId;
  final List<dynamic> notes;
  const _NotesTab({required this.projectId, required this.notes});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late List<dynamic> _notes;
  final _noteCtrl = TextEditingController();
  String _noteType = 'general';

  @override
  void initState() {
    super.initState();
    _notes = widget.notes;
  }

  Future<void> _addNote() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    final token = context.read<AuthService>().token!;
    final res = await ApiService.post('/projects/${widget.projectId}/notes', token, {
      'note_type': _noteType,
      'note': _noteCtrl.text.trim(),
    });
    if (mounted) {
      if (res['status'] == 200) {
        _noteCtrl.clear();
        // Reload notes
        final data = await ApiService.get('/projects/${widget.projectId}/notes', token);
        setState(() => _notes = data['data'] ?? []);
        showSuccess(context, 'Note added');
      } else {
        showError(context, res['message'] ?? 'Failed');
      }
    }
  }

  Color _noteTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'admin note':
        return AppColors.msRed;
      case 'daily update':
        return AppColors.msBlue;
      case 'request':
        return AppColors.msOrange;
      case 'remark':
        return AppColors.msPurple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add note
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.bgCard,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _noteType,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgDark,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'admin note', child: Text('Admin Note')),
                        DropdownMenuItem(value: 'daily update', child: Text('Daily Update')),
                        DropdownMenuItem(value: 'request', child: Text('Request')),
                        DropdownMenuItem(value: 'remark', child: Text('Remark')),
                      ],
                      onChanged: (v) => setState(() => _noteType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Write a note...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.bgDark,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addNote,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final n = _notes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _noteTypeColor(n['note_type']).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(n['note_type'] ?? 'Note', style: TextStyle(color: _noteTypeColor(n['note_type']), fontSize: 11)),
                        ),
                        const Spacer(),
                        Text(n['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(n['note_text'] ?? n['note'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    if (n['author_name'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('- ${n['author_name']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final List<dynamic> documents;
  const _DocumentsTab({required this.documents});

  IconData _docIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'drawing':
        return Icons.architecture;
      case 'certificate':
        return Icons.verified;
      case 'report':
        return Icons.description;
      case 'invoice':
        return Icons.receipt;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const EmptyState(icon: Icons.folder_open, message: 'No documents');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final d = documents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(_docIcon(d['document_type']), color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['title'] ?? d['file_path'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                Text(d['document_type'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              Text(d['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

class _PermitsTab extends StatelessWidget {
  final List<dynamic> permits;
  const _PermitsTab({required this.permits});

  Color _permitStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.msGreen;
      case 'rejected':
        return AppColors.msRed;
      case 'pending':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (permits.isEmpty) return const EmptyState(icon: Icons.assignment, message: 'No permits');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permits.length,
      itemBuilder: (context, index) {
        final p = permits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.assignment, color: _permitStatusColor(p['status']), size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['permit_type'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                Text(p['filled_at']?.toString() ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              StatusBadge(text: p['status'] ?? '', color: _permitStatusColor(p['status'])),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reports = [
      'Propeller & Rudder Clearances',
      'Inspection Overboard Valves',
      'Chain Measurement',
      'Garbage Receipt',
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.description, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(reports[index], style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }
}
