import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/projects', token);
    if (mounted) {
      setState(() {
        _projects = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredProjects {
    if (_searchQuery.isEmpty) return _projects;
    return _projects
        .where((p) =>
            (p['project_title'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (p['project_code'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Projects', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadProjects();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search projects...',
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

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = _filteredProjects[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                projectId: project['id'],
                                projectTitle: project['project_title'] ?? '',
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1a73e8)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        project['project_code'] ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFF1a73e8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(project['status'])
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        project['status'] ?? '',
                                        style: TextStyle(
                                          color:
                                              _statusColor(project['status']),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  project['project_title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (project['ship_name'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_boat,
                                          color: Colors.grey, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        project['ship_name'],
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                                if (project['start_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Colors.grey, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${project['start_date'] ?? ''} → ${project['end_date'] ?? 'ongoing'}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
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

// Project Detail Screen
class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
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
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: Text(widget.projectTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1a73e8),
          labelColor: const Color(0xFF1a73e8),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
            Tab(text: 'Permits'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(project: _project!),
                _NotesTab(projectId: widget.projectId),
                _PermitsTab(project: _project!),
              ],
            ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> project;
  const _OverviewTab({required this.project});

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _infoRow('Code', project['project_code']),
            const Divider(color: Colors.white12),
            _infoRow('Status', project['status']),
            const Divider(color: Colors.white12),
            _infoRow('Ship', project['ship_name']),
            const Divider(color: Colors.white12),
            _infoRow('Customer', project['customer_name']),
            const Divider(color: Colors.white12),
            _infoRow('Start Date', project['start_date']),
            const Divider(color: Colors.white12),
            _infoRow('End Date', project['end_date']),
            const Divider(color: Colors.white12),
            _infoRow('Location', project['location']),
            const Divider(color: Colors.white12),
            _infoRow('Manager', project['project_manager']),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends StatefulWidget {
  final int projectId;
  const _NotesTab({required this.projectId});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  List<dynamic> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final token = context.read<AuthService>().token!;
    final data =
        await ApiService.get('/projects/${widget.projectId}/notes', token);
    if (mounted) {
      setState(() {
        _notes = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a73e8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            note['note_type'] ?? 'Note',
                            style: const TextStyle(
                                color: Color(0xFF1a73e8), fontSize: 11),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          note['created_at'] ?? '',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note['note'] ?? note['body'] ?? '',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

class _PermitsTab extends StatelessWidget {
  final Map<String, dynamic> project;
  const _PermitsTab({required this.project});

  @override
  Widget build(BuildContext context) {
    final permits = project['permits'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permits.length,
      itemBuilder: (context, index) {
        final permit = permits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, color: Color(0xFF1a73e8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permit['permit_type'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      permit['status'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
