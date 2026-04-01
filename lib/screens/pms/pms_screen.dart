import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class PmsScreen extends StatefulWidget {
  const PmsScreen({super.key});
  @override
  State<PmsScreen> createState() => _PmsScreenState();
}

class _PmsScreenState extends State<PmsScreen> {
  List<dynamic> _overdue = [];
  List<dynamic> _dueSoon = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/pms/overdue', token);
    if (mounted) setState(() {
      _overdue = data['data']?['overdue'] ?? [];
      _dueSoon = data['data']?['due_soon'] ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('PMS', style: TextStyle(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _isLoading = true); _load(); })],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (_overdue.isNotEmpty) ...[
                const Text('OVERDUE', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._overdue.map((t) => _TaskCard(task: t, isOverdue: true)),
                const SizedBox(height: 16),
              ],
              if (_dueSoon.isNotEmpty) ...[
                const Text('DUE SOON', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._dueSoon.map((t) => _TaskCard(task: t, isOverdue: false)),
              ],
              if (_overdue.isEmpty && _dueSoon.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(48),
                  child: Column(children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text('All maintenance up to date!', style: TextStyle(color: Colors.green, fontSize: 16)),
                  ]))),
            ])));
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isOverdue;
  const _TaskCard({required this.task, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.build_circle, color: isOverdue ? Colors.red : Colors.orange, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['task_name'] ?? task['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(task['equipment_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text('Due: ', style: TextStyle(color: isOverdue ? Colors.red : Colors.orange, fontSize: 12)),
        ])),
      ]),
    );
  }
}
