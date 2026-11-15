import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/event_models.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../providers/event_providers.dart';

typedef SaveExportedFileCallback = Future<void> Function(
  Uint8List bytes,
  String fileName,
  String ext,
  MimeType mimeType,
);

/// Dashboard Hậu Cần Sự Kiện cho Ban Tổ Chức (US-42):
/// - Thẻ số liệu tổng hợp tức thời: hộ gia đình, cá nhân, cỗ mặn, cỗ chay, chỗ ngồi xe đưa đón
/// - Bộ lọc theo chi/nhánh gia đình
/// - Bảng chi tiết từng hộ & nút Xuất danh sách điểm danh / chia cỗ (.xlsx / .csv)
class EventLogisticsDashboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  final SaveExportedFileCallback? onSaveFile;

  const EventLogisticsDashboardScreen({
    super.key,
    required this.eventId,
    this.onSaveFile,
  });

  @override
  ConsumerState<EventLogisticsDashboardScreen> createState() =>
      _EventLogisticsDashboardScreenState();
}

class _EventLogisticsDashboardScreenState
    extends ConsumerState<EventLogisticsDashboardScreen> {
  String? _selectedBranchId;
  bool _isExporting = false;

  Future<void> _exportFile(String format) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final bytes = await repo.exportEventRegistrationSummary(
        widget.eventId,
        branchId: _selectedBranchId,
        format: format,
      );

      final isCsv = format.toLowerCase() == 'csv';
      final ext = isCsv ? 'csv' : 'xlsx';
      final mimeType = isCsv ? MimeType.csv : MimeType.microsoftExcel;
      final branchSuffix =
          (_selectedBranchId != null && _selectedBranchId!.isNotEmpty)
              ? '_${_selectedBranchId!}'
              : '';
      final fileName =
          'danh_sach_diem_danh_chia_co_${widget.eventId}$branchSuffix';

      if (widget.onSaveFile != null) {
        await widget.onSaveFile!(bytes, fileName, ext, mimeType);
      } else if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          fileExtension: ext,
          mimeType: mimeType,
        );
      } else {
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          fileExtension: ext,
          mimeType: mimeType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xuất danh sách điểm danh & chia cỗ ($fileName.$ext)',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = (eventId: widget.eventId, branchId: _selectedBranchId);
    final summaryAsync = ref.watch(eventLogisticsSummaryProvider(query));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A1518),
        foregroundColor: Colors.white,
        title: const Text(
          'Dashboard Hậu Cần Sự Kiện (BTC)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới số liệu tức thời',
            onPressed: () => ref.invalidate(eventLogisticsSummaryProvider(query)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7A1518)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFC62828)),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF5D4037)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(eventLogisticsSummaryProvider(query)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) => RefreshIndicator(
          color: const Color(0xFF7A1518),
          onRefresh: () async =>
              ref.invalidate(eventLogisticsSummaryProvider(query)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(summary),
              const SizedBox(height: 16),
              _buildFilterAndExportBar(summary),
              const SizedBox(height: 16),
              _buildKpiGrid(summary),
              const SizedBox(height: 20),
              _buildHouseholdListSection(summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(EventLogisticsSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7A1518), Color(0xFF9C2024)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: Color(0xFFFFD54F), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.eventName.isNotEmpty
                      ? summary.eventName
                      : 'Sự kiện ${summary.eventId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary.branchName != null && summary.branchName!.isNotEmpty
                ? 'Phạm vi đang lọc: ${summary.branchName}'
                : 'Phạm vi đang lọc: Toàn bộ chi/nhánh dòng họ',
            style: const TextStyle(color: Color(0xFFFFECB3), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndExportBar(EventLogisticsSummaryModel summary) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<String?>(
            key: const Key('logistics_branch_filter'),
            initialValue: _selectedBranchId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Lọc theo chi / nhánh gia đình',
              prefixIcon: const Icon(Icons.account_tree_outlined, size: 18),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0CFC2)),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'Tất cả chi nhánh',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...summary.availableBranches.map(
                (branch) => DropdownMenuItem<String?>(
                  value: branch.branchId,
                  child: Text(
                    branch.branchName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedBranchId = value);
            },
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              key: const Key('export_logistics_excel_button'),
              onPressed: _isExporting ? null : () => _exportFile('xlsx'),
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: const Text('Xuất danh sách điểm danh/chia cỗ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('export_logistics_csv_button'),
              onPressed: _isExporting ? null : () => _exportFile('csv'),
              icon: const Icon(Icons.table_view_outlined, size: 17),
              label: const Text('CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7A1518),
                side: const BorderSide(color: Color(0xFF7A1518)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGrid(EventLogisticsSummaryModel summary) {
    final cards = [
      _KpiItem(
        key: const Key('kpi_total_registrations'),
        label: 'Số hộ gia đình',
        value: summary.totalRegistrations.toString(),
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF7A1518),
      ),
      _KpiItem(
        key: const Key('kpi_total_attendees'),
        label: 'Tổng số cá nhân',
        value: summary.totalAttendees.toString(),
        icon: Icons.groups_rounded,
        color: const Color(0xFF1565C0),
      ),
      _KpiItem(
        key: const Key('kpi_total_savory_meals'),
        label: 'Tổng suất cỗ mặn',
        value: summary.totalSavoryMeals.toString(),
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFD84315),
      ),
      _KpiItem(
        key: const Key('kpi_total_vegetarian_meals'),
        label: 'Tổng suất cỗ chay',
        value: summary.totalVegetarianMeals.toString(),
        icon: Icons.eco_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _KpiItem(
        key: const Key('kpi_total_shuttle_seats'),
        label: 'Chỗ ngồi xe đưa đón',
        value: summary.totalShuttleSeats.toString(),
        icon: Icons.directions_bus_rounded,
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 960
            ? 5
            : width >= 640
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: cards.length,
          itemBuilder: (_, index) => _KpiCard(item: cards[index]),
        );
      },
    );
  }

  Widget _buildHouseholdListSection(EventLogisticsSummaryModel summary) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBD9C8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  color: Color(0xFF7A1518), size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết hộ đăng ký (${summary.registrations.length} hộ)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.registrations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Chưa có hộ gia đình nào đăng ký trong phạm vi chi/nhánh này.',
                  style: TextStyle(color: Color(0xFF8A7A70)),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFFFF8EE)),
                columns: const [
                  DataColumn(label: Text('Đại diện hộ')),
                  DataColumn(label: Text('Chi / Nhánh')),
                  DataColumn(label: Text('Số người'), numeric: true),
                  DataColumn(label: Text('Cỗ mặn'), numeric: true),
                  DataColumn(label: Text('Cỗ chay'), numeric: true),
                  DataColumn(label: Text('Chỗ xe'), numeric: true),
                  DataColumn(label: Text('Ghi chú ăn uống')),
                  DataColumn(label: Text('Phương tiện')),
                  DataColumn(label: Text('Thời gian ĐK')),
                ],
                rows: summary.registrations.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        item.representativeName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )),
                      DataCell(Text(item.branchName ?? '-')),
                      DataCell(Text('${item.totalAttendees}')),
                      DataCell(Text('${item.savoryMeals}')),
                      DataCell(Text('${item.vegetarianMeals}')),
                      DataCell(Text('${item.shuttleSeats}')),
                      DataCell(Text(
                        (item.dietaryRequirements?.isNotEmpty ?? false)
                            ? item.dietaryRequirements!
                            : '-',
                      )),
                      DataCell(Text(
                        (item.transportationNotes?.isNotEmpty ?? false)
                            ? item.transportationNotes!
                            : '-',
                      )),
                      DataCell(Text(
                        item.registrationDate != null
                            ? dateFmt.format(item.registrationDate!.toLocal())
                            : '-',
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiItem {
  final Key key;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiItem({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: item.key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}
