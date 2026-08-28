import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';

class GovernmentReportsScreen extends StatelessWidget {
  const GovernmentReportsScreen({super.key});

  static const _reportTypes = [
    _ReportType(
      title: 'Regional Production Summary',
      description: 'Total capacity, farmer count, and crop breakdown by region',
      icon: Icons.map,
    ),
    _ReportType(
      title: 'Supply & Demand Analysis',
      description: 'Compare farmer supply with business and government demand',
      icon: Icons.compare_arrows,
    ),
    _ReportType(
      title: 'Shortage & Surplus Report',
      description: 'Identify imbalances requiring policy intervention',
      icon: Icons.warning_amber,
    ),
    _ReportType(
      title: 'Marketplace Activity Report',
      description: 'Purchase interests, acceptances, and transaction trends',
      icon: Icons.handshake,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Export agricultural data for policy and planning decisions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ..._reportTypes.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  onTap: () => _generateReport(context, report.title),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.government.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(report.icon, color: AppColors.government),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.download, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent Reports'),
          const SizedBox(height: 12),
          _RecentReportTile(
            title: 'Q2 Regional Production Summary',
            date: 'Jun 15, 2026',
            onTap: () => _generateReport(context, 'Q2 Regional Production Summary'),
          ),
          _RecentReportTile(
            title: 'May Supply & Demand Analysis',
            date: 'May 28, 2026',
            onTap: () => _generateReport(context, 'May Supply & Demand Analysis'),
          ),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating "$title" — PDF export in next phase')),
    );
  }
}

class _ReportType {
  const _ReportType({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _RecentReportTile extends StatelessWidget {
  const _RecentReportTile({
    required this.title,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        tileColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
        title: Text(title),
        subtitle: Text(date),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
