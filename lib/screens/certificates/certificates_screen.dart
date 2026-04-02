import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    // Try /certificates endpoint, then try web admin endpoint
    var data = await ApiService.get('/certificates', token);
    if (data['data'] == null) {
      data = await ApiService.get('/admin/certificates', token);
    }
    if (mounted) {
      setState(() {
        _certificates = data['data'] is List ? data['data'] : [];
        _isLoading = false;
      });
    }
  }

  int _daysRemaining(String? dateStr) {
    if (dateStr == null) return 999;
    try {
      return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
    } catch (_) {
      return 999;
    }
  }

  // Web'deki status dot renkleri
  Color _expiryColor(int days) {
    if (days < 0) return AppColors.msRed;
    if (days <= 30) return AppColors.msOrange;
    if (days <= 60) return const Color(0xFFffc107);
    if (days <= 90) return AppColors.msBlue;
    return AppColors.msGreen;
  }

  // Web'deki category renkleri
  Color _categoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'classification':
        return const Color(0xFF1565c0);
      case 'safety':
        return const Color(0xFFc62828);
      case 'environmental':
        return const Color(0xFF2e7d32);
      case 'quality':
        return const Color(0xFF6a1b9a);
      case 'operational':
        return const Color(0xFFe65100);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _certificates.length;
    final valid = _certificates.where((c) => _daysRemaining(c['expiry_date']?.toString()) > 90).length;
    final expiring30 = _certificates.where((c) { final d = _daysRemaining(c['expiry_date']?.toString()); return d >= 0 && d <= 30; }).length;
    final expiring60 = _certificates.where((c) { final d = _daysRemaining(c['expiry_date']?.toString()); return d > 30 && d <= 60; }).length;
    final expired = _certificates.where((c) => _daysRemaining(c['expiry_date']?.toString()) < 0).length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Certificates', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats row — web'deki gibi
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatChip(label: 'Total', value: '$total', color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Valid', value: '$valid', color: AppColors.msGreen),
                        const SizedBox(width: 8),
                        _StatChip(label: '30 Days', value: '$expiring30', color: AppColors.msOrange),
                        const SizedBox(width: 8),
                        _StatChip(label: '31-60', value: '$expiring60', color: const Color(0xFF835b00)),
                        const SizedBox(width: 8),
                        _StatChip(label: 'Expired', value: '$expired', color: AppColors.msRed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Certificate cards
                  ..._certificates.map((cert) {
                    final days = _daysRemaining(cert['expiry_date']?.toString());
                    final expiryColor = _expiryColor(days);
                    final catColor = _categoryColor(cert['category']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
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
                              // Category badge
                              if (cert['category'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(cert['category'], style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              const Spacer(),
                              // Status dot
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: expiryColor, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(cert['name'] ?? cert['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          if (cert['issuing_authority'] != null)
                            Text(cert['issuing_authority'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (cert['certificate_number'] != null)
                            Text(cert['certificate_number'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.event, color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text('Expires: ${cert['expiry_date'] ?? '-'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const Spacer(),
                              Text(
                                days < 0 ? 'Expired ${-days}d ago' : days == 0 ? 'Expires today' : '$days days left',
                                style: TextStyle(color: expiryColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
