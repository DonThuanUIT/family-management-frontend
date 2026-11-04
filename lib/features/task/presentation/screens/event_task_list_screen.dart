import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../event/data/models/event_models.dart';
import '../../../event/data/repositories/event_repository_impl.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../data/models/task_models.dart';
import '../providers/task_providers.dart';
import '../widgets/assign_task_dialog.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/task_card.dart';

/// Màn hình danh sách công việc chuẩn bị cho sự kiện (US-07).
/// Hỗ trợ thích ứng đa nền tảng (Web 1280px + Mobile 390px) và đủ 5 trạng thái màn hình:
/// Đang tải, Rỗng, Lỗi, Không đủ quyền (Chế độ Thành viên), và Chỉ đọc (Sự kiện Closed).
class EventTaskListScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventTaskListScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventTaskListScreen> createState() =>
      _EventTaskListScreenState();
}

class _EventTaskListScreenState extends ConsumerState<EventTaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  EventModel? _cachedEvent;
  bool _isLoadingEvent = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEventDetail() async {
    // 1. Kiểm tra trước trong eventListProvider
    final eventListState = ref.read(eventListProvider);
    for (final e in eventListState.events) {
      if (e.eventId == widget.eventId) {
        setState(() => _cachedEvent = e);
        break;
      }
    }

    // 2. Tải chi tiết sự kiện từ repository để đảm bảo có đầy đủ mảng personnel
    setState(() => _isLoadingEvent = _cachedEvent == null);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final detailed = await repo.getEventDetail(widget.eventId);
      if (mounted) {
        setState(() {
          _cachedEvent = detailed;
          _isLoadingEvent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingEvent = false);
      }
    }
  }

  void _openCreateTask(EventModel event) {
    CreateTaskDialog.show(context, event: event);
  }

  void _openAssignTask(EventModel event, TaskModel task) {
    AssignTaskDialog.show(context, event: event, task: task);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider(widget.eventId));
    final session = ref.watch(dualRbacSessionProvider);

    final event = _cachedEvent;
    final isClosed = event?.isClosed ?? false;
    final canManage = event != null &&
        session.canManageTasks(
          isClosed: isClosed,
          personnel: event.personnel,
          eventId: widget.eventId,
        );

    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCrimson,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hạng Mục Công Việc Chuẩn Bị',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (event != null)
              Text(
                '${event.eventName} • ${event.formattedSolarDayMonth}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        bottom: _isLoadingEvent
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppTheme.secondaryGold,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Tải lại danh sách',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(taskListProvider(widget.eventId).notifier)
                .loadTasks(showLoading: true),
          ),
          if (canManage && !isClosed && isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openCreateTask(event),
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Tạo Công Việc',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGold,
                  foregroundColor: const Color(0xFF1F1610),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!isDesktop && canManage && !isClosed)
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateTask(event),
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text(
                'Tạo việc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(taskListProvider(widget.eventId).notifier)
              .loadTasks(showLoading: false);
          await _fetchEventDetail();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 16,
              ),
              children: [
                // 1. Banner trạng thái Sự kiện Closed (Chỉ đọc)
                if (isClosed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 18, color: AppTheme.warningExplanationAmber),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sự kiện đã kết thúc và khóa sổ (Closed)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Toàn bộ quyền hạn thao tác chuẩn bị sự kiện đã tự động chuyển sang Chế độ Chỉ đọc. Nút tạo và gán việc đã bị khóa.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Banner Không đủ quyền (Chế độ Thành viên)
                if (!canManage && !isClosed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: Color(0xFF475569)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bạn đang xem danh sách công việc ở chế độ Thành viên. Chỉ Ban tổ chức, Trưởng tộc hoặc Quản trị viên mới có quyền tạo và điều chuyển công việc.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Header Card tổng quan sự kiện
                if (event != null)
                  _buildEventHeaderCard(event, isDesktop, canManage, isClosed),

                const SizedBox(height: 14),

                // 4. Thanh lọc & Tìm kiếm
                _buildFilterToolbar(taskState, isDesktop),

                const SizedBox(height: 14),

                // 5. Nội dung danh sách công việc theo 5 trạng thái
                if (taskState.isLoading && taskState.tasks.isEmpty)
                  _buildLoadingState()
                else if (taskState.errorMessage != null)
                  _buildErrorState(taskState.errorMessage!)
                else if (taskState.tasks.isEmpty)
                  _buildEmptyState(canManage, isClosed, event)
                else
                  _buildTaskGrid(
                    taskState.filteredTasks,
                    isDesktop,
                    canManage,
                    isClosed,
                    event,
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Khung tổng quan sự kiện
  Widget _buildEventHeaderCard(
    EventModel event,
    bool isDesktop,
    bool canManage,
    bool isClosed,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E4DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  event.eventName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1610),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isClosed
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Text(
                  event.lifecycleStatus.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isClosed
                        ? const Color(0xFF4B5563)
                        : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month,
                      size: 15, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 5),
                  Text(
                    '${event.formattedSolarTime} - ${event.formattedSolarDate} (${event.eventDateLunar ?? ""})',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B5E55)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 15, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 5),
                  Text(
                    event.location,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B5E55)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 15, color: AppTheme.immutableLedgerTeal),
                  const SizedBox(width: 5),
                  Text(
                    'Dự toán: ${event.formattedBudgetMillion}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1610),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Thanh công cụ lọc & tìm kiếm
  Widget _buildFilterToolbar(TaskListState state, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'Tất cả (${state.totalCount})',
                  isSelected: state.selectedStatus == null,
                  onSelected: () => ref
                      .read(taskListProvider(widget.eventId).notifier)
                      .setStatusFilter(null),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  label: 'Chưa giao (${state.unassignedCount})',
                  isSelected:
                      state.selectedStatus == TaskStatusEnum.unassigned,
                  onSelected: () => ref
                      .read(taskListProvider(widget.eventId).notifier)
                      .setStatusFilter(TaskStatusEnum.unassigned),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  label: 'Đang làm (${state.inProgressCount})',
                  isSelected:
                      state.selectedStatus == TaskStatusEnum.inProgress,
                  onSelected: () => ref
                      .read(taskListProvider(widget.eventId).notifier)
                      .setStatusFilter(TaskStatusEnum.inProgress),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  label: 'Đã xong (${state.completedCount})',
                  isSelected: state.selectedStatus == TaskStatusEnum.completed,
                  onSelected: () => ref
                      .read(taskListProvider(widget.eventId).notifier)
                      .setStatusFilter(TaskStatusEnum.completed),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  label: 'Quá hạn (${state.overdueCount})',
                  isSelected: state.selectedStatus == TaskStatusEnum.overdue,
                  onSelected: () => ref
                      .read(taskListProvider(widget.eventId).notifier)
                      .setStatusFilter(TaskStatusEnum.overdue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên việc hoặc người nhận...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(taskListProvider(widget.eventId).notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) {
              ref
                  .read(taskListProvider(widget.eventId).notifier)
                  .setSearchQuery(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF6B5E55),
      ),
      selectedColor: AppTheme.primaryCrimson,
      backgroundColor: const Color(0xFFF9F8F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryCrimson : const Color(0xFFE8E4DF),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryCrimson),
            SizedBox(height: 14),
            Text(
              'Đang tải danh sách công việc...',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6B5E55)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Không thể tải danh sách công việc',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1610),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B5E55)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref
                .read(taskListProvider(widget.eventId).notifier)
                .loadTasks(showLoading: true),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool canManage,
    bool isClosed,
    EventModel? event,
  ) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E4DF)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 32,
              color: Color(0xFF8A7A70),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có hạng mục công việc nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1610),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sự kiện này chưa có công việc chuẩn bị nào được phân công.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B5E55)),
          ),
          if (canManage && !isClosed && event != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCreateTask(event),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tạo Công Việc Đầu Tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskGrid(
    List<TaskModel> tasks,
    bool isDesktop,
    bool canManage,
    bool isClosed,
    EventModel? event,
  ) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Không tìm thấy công việc phù hợp với bộ lọc.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
      );
    }

    if (!isDesktop) {
      return Column(
        children: tasks.map((task) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              canManage: canManage,
              isClosed: isClosed,
              onReassign: () {
                if (event != null) _openAssignTask(event, task);
              },
            ),
          );
        }).toList(),
      );
    }

    // Grid layout for Desktop / Tablet
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 960 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 310,
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              canManage: canManage,
              isClosed: isClosed,
              onReassign: () {
                if (event != null) _openAssignTask(event, task);
              },
            );
          },
        );
      },
    );
  }
}
