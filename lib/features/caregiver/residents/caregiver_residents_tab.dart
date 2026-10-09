import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/responsive/responsive.dart';
import '../../../components/cards/carevora_card.dart';
import '../../../components/indicators/carevora_badges.dart';
import '../../../core/providers/app_providers.dart';
import 'caregiver_resident_detail_view.dart';
import '../../../models/carevora_models.dart';

class CaregiverResidentsTab extends ConsumerStatefulWidget {
  const CaregiverResidentsTab({super.key});

  @override
  ConsumerState<CaregiverResidentsTab> createState() => _CaregiverResidentsTabState();
}

class _CaregiverResidentsTabState extends ConsumerState<CaregiverResidentsTab> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final residentsAsync = ref.watch(residentsProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resident Directory', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Continuous emotional and social wellness tracking', style: AppTypography.body),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Resident Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 44),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Bar
            CarevoraCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search by resident name or room number...',
                          hintStyle: AppTypography.bodySmall,
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          fillColor: AppColors.surfaceSecondary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Residents')),
                      DropdownMenuItem(value: 'Needs Attention', child: Text('Needs Attention')),
                      DropdownMenuItem(value: 'Stable', child: Text('Stable')),
                      DropdownMenuItem(value: 'Looking Good', child: Text('Looking Good')),
                    ],
                    onChanged: (val) => setState(() => _selectedFilter = val ?? 'All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Resident Table / List
            residentsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error loading directory: $e')),
              data: (residents) {
                final filtered = residents.where((r) {
                  final matchQuery = r.name.toLowerCase().contains(_searchQuery) || r.roomNumber.toLowerCase().contains(_searchQuery);
                  if (!matchQuery) return false;
                  if (_selectedFilter == 'Needs Attention') return r.currentStatus.name == 'needsAttention';
                  if (_selectedFilter == 'Stable') return r.currentStatus.name == 'stable';
                  if (_selectedFilter == 'Looking Good') return r.currentStatus.name == 'lookingGood';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('No residents match your criteria', style: AppTypography.h3),
                        ],
                      ),
                    ),
                  );
                }

                if (isDesktop) {
                  return _buildDesktopResidentTable(filtered);
                } else {
                  return _buildMobileResidentCards(filtered);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopResidentTable(List<ResidentModel> residents) {
    return CarevoraCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Resident', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Wellness Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Trajectory', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Emotional Score', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: residents.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primarySoft,
                              child: Text(r.name.substring(0, 2).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(r.name, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                Text('${r.age} years old', style: AppTypography.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(r.roomNumber, style: AppTypography.bodySmall)),
                      DataCell(StatusBadge(status: r.currentStatus)),
                      DataCell(RiskBadge(riskLevel: r.riskLevel)),
                      DataCell(TrajectoryBadge(trajectory: r.trajectory)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${r.emotionalScore.toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(
                                value: r.emotionalScore / 100,
                                backgroundColor: AppColors.surfaceSecondary,
                                color: AppColors.primary,
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: () {
                            ref.read(selectedResidentIdProvider.notifier).select(r.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CaregiverResidentDetailView(resident: r)),
                            );
                          },
                          child: const Text('View Profile'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileResidentCards(List<ResidentModel> residents) {
    return Column(
      children: residents.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CarevoraCard(
            onTap: () {
              ref.read(selectedResidentIdProvider.notifier).select(r.id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CaregiverResidentDetailView(resident: r)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.name, style: AppTypography.h3),
                    StatusBadge(status: r.currentStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${r.roomNumber} • ${r.age} yrs', style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RiskBadge(riskLevel: r.riskLevel),
                    TrajectoryBadge(trajectory: r.trajectory),
                    Text('Score: ${r.emotionalScore.toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
