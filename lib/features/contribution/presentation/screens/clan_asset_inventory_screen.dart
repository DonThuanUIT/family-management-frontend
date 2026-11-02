import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/contribution_models.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../providers/contribution_ui_provider.dart';
import '../widgets/electronic_receipt_dialog.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';

/// Task #74: Màn hình Quản lý Kho Bảo Vật – Di Sản Dòng Họ và Vòng Đời Hiện Vật Sự Kiện.
/// Chuẩn hóa theo phong cách Warm Editorial Heritage & UI/UX Pro Max:
/// - Tone màu Di sản Hoàng gia: Đỏ son (#8B1E1E), Vàng kim (#D4A017), Xanh ngọc (#2E8B43).
/// - Vùng chạm chuẩn Thumb-friendly >= 42-44pt.
/// - Độ tương phản văn bản cao đạt chuẩn WCAG AA/AAA (>= 4.5:1).
/// - Bộ lọc phân loại danh mục bảo vật tức thì kết hợp tìm kiếm từ khóa thời gian thực.
/// - Tem QR định danh chuẩn khổ in 50x30mm với tính năng sao chép mã 1-chạm.
class ClanAssetInventoryScreen extends ConsumerStatefulWidget {
  const ClanAssetInventoryScreen({super.key});

  @override
  ConsumerState<ClanAssetInventoryScreen> createState() =>
      _ClanAssetInventoryScreenState();
}

class _ClanAssetInventoryScreenState
    extends ConsumerState<ClanAssetInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  String _selectedCategory = 'all';
  String _selectedProcessedFilter = 'all';
  final Map<String, String> _categories = {
    'all': 'Tất cả phân loại',
    'altar': 'Đồ đồng & Thờ tự',
    'wood': 'Đồ gỗ mỹ nghệ',
    'ceramic': 'Gốm sứ cổ',
    'genealogy': 'Gia phả & Văn tự',
    'feast': 'Cỗ bàn & Đồ lễ tế',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = 'all';
        _selectedProcessedFilter = 'all';
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesItemCategory(String name, String cat) {
    if (cat == 'all') return true;
    final lower = name.toLowerCase();
    if (cat == 'altar') {
      return lower.contains('đồng') ||
          lower.contains('đỉnh') ||
          lower.contains('lư') ||
          lower.contains('hương') ||
          lower.contains('thờ') ||
          lower.contains('nến') ||
          lower.contains('đài');
    }
    if (cat == 'wood') {
      return lower.contains('gỗ') ||
          lower.contains('ngai') ||
          lower.contains('hoành phi') ||
          lower.contains('câu đối') ||
          lower.contains('hương án') ||
          lower.contains('sập') ||
          lower.contains('kỷ');
    }
    if (cat == 'ceramic') {
      return lower.contains('gốm') ||
          lower.contains('sứ') ||
          lower.contains('lục bình') ||
          lower.contains('bát tràng') ||
          lower.contains('bình hoa');
    }
    if (cat == 'genealogy') {
      return lower.contains('phả') ||
          lower.contains('sách') ||
          lower.contains('văn tự') ||
          lower.contains('sắc phong') ||
          lower.contains('phổ');
    }
    if (cat == 'feast') {
      return lower.contains('cỗ') ||
          lower.contains('heo') ||
          lower.contains('lợn') ||
          lower.contains('gà') ||
          lower.contains('xôi') ||
          lower.contains('bánh') ||
          lower.contains('rượu') ||
          lower.contains('chè') ||
          lower.contains('trầu') ||
          lower.contains('cau') ||
          lower.contains('quả') ||
          lower.contains('hoa') ||
          lower.contains('nếp') ||
          lower.contains('đài') ||
          lower.contains('loa');
    }
    return true;
  }

  int _getCategoryCount(String catKey, ContributionUiState uiState) {
    if (_tabController.index == 0) {
      return catKey == 'all'
          ? uiState.clanAssets.length
          : uiState.clanAssets
              .where((a) => _matchesItemCategory(a.assetName, catKey))
              .length;
    } else if (_tabController.index == 1) {
      final pendings = uiState.inKindReceipts
          .where((i) => i.processingStatus == InKindProcessingStatus.Pending);
      return catKey == 'all'
          ? pendings.length
          : pendings
              .where((i) => _matchesItemCategory(i.itemName, catKey))
              .length;
    } else {
      final processeds = uiState.inKindReceipts
          .where((i) => i.processingStatus != InKindProcessingStatus.Pending);
      return catKey == 'all'
          ? processeds.length
          : processeds
              .where((i) => _matchesItemCategory(i.itemName, catKey))
              .length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(contributionUiProvider);
    final isWide = MediaQuery.of(context).size.width > 850;

    final filteredAssets = uiState.clanAssets.where((a) {
      if (!_matchesItemCategory(a.assetName, _selectedCategory)) return false;
      if (uiState.searchQuery.isEmpty) return true;
      final query = uiState.searchQuery.toLowerCase();
      return a.assetName.toLowerCase().contains(query) ||
          a.storageLocation.toLowerCase().contains(query) ||
          a.assetId.toLowerCase().contains(query);
    }).toList();

    final filteredPending = uiState.inKindReceipts.where((item) {
      if (item.processingStatus != InKindProcessingStatus.Pending) return false;
      if (!_matchesItemCategory(item.itemName, _selectedCategory)) return false;
      if (uiState.searchQuery.isEmpty) return true;
      final q = uiState.searchQuery.toLowerCase();
      final payer = (item.payerMemberName ?? item.payerMemberId).toLowerCase();
      return item.itemName.toLowerCase().contains(q) ||
          item.receiptNumber.toLowerCase().contains(q) ||
          payer.contains(q);
    }).toList();

    // Danh sách lịch sử gốc khớp với phân loại và tìm kiếm
    final processedBase = uiState.inKindReceipts.where((item) {
      if (item.processingStatus == InKindProcessingStatus.Pending) return false;
      if (!_matchesItemCategory(item.itemName, _selectedCategory)) return false;
      if (uiState.searchQuery.isEmpty) return true;
      final q = uiState.searchQuery.toLowerCase();
      final payer = (item.payerMemberName ?? item.payerMemberId).toLowerCase();
      return item.itemName.toLowerCase().contains(q) ||
          item.receiptNumber.toLowerCase().contains(q) ||
          payer.contains(q);
    }).toList();

    final filteredProcessed = processedBase.where((item) {
      if (_selectedProcessedFilter == 'consumed' &&
          item.processingStatus != InKindProcessingStatus.Consumed) {
        return false;
      }
      if (_selectedProcessedFilter == 'returned' &&
          item.processingStatus != InKindProcessingStatus.Returned) {
        return false;
      }
      if (_selectedProcessedFilter == 'assets' &&
          item.processingStatus != InKindProcessingStatus.AddedToCommonAssets) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: const HeritageNavBar(currentRoute: '/clan-assets'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/clan-assets'),
      body: Column(
        children: [
          // Header summary statistics & Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4A017), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.temple_buddhist,
                              color: Color(0xFFD4A017),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kho Bảo Vật & Di Sản Dòng Họ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF2B1810),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  'TỪ ĐƯỜNG TỔ • ĐỊNH DANH MÃ QR',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF54433E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAssetModal(context),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Đăng Ký Bảo Vật Mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildOverviewStats(uiState, isWide),
                const SizedBox(height: 14),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => ref
                      .read(contributionUiProvider.notifier)
                      .setSearchQuery(val),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2B1810),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tìm kiếm bảo vật, đồ thờ theo tên hoặc vị trí lưu kho...',
                    hintStyle: const TextStyle(color: Color(0xFF78655C)),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF8B1E1E)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF4A3B32)),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(contributionUiProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.entries.map((entry) {
                      final isSelected = _selectedCategory == entry.key;
                      final count = _getCategoryCount(entry.key, uiState);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${entry.value} ($count)'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = entry.key;
                            });
                          },
                          backgroundColor: const Color(0xFFFAF9F6),
                          selectedColor: const Color(0xFF8B1E1E),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A3B32),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF8B1E1E)
                                  : const Color(0xFFE6DFD8),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Thanh hiển thị bộ lọc đang kích hoạt kèm nút xóa nhanh 1-chạm
                if (_selectedCategory != 'all' || uiState.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2AA36).withAlpha(120)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 15, color: Color(0xFF8B1E1E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang lọc theo: ${_categories[_selectedCategory]}${uiState.searchQuery.isNotEmpty ? ' • Từ khóa: "${uiState.searchQuery}"' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            ref.read(contributionUiProvider.notifier).setSearchQuery('');
                            setState(() {
                              _selectedCategory = 'all';
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, size: 14, color: Color(0xFF8B1E1E)),
                                SizedBox(width: 4),
                                Text(
                                  'Bỏ lọc',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          Container(
            color: const Color(0xFFF5F0E8),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B1E1E),
              unselectedLabelColor: const Color(0xFF54433E),
              indicatorColor: const Color(0xFF8B1E1E),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.inventory, size: 20),
                  text: 'Sổ Kho Bảo Vật Từ Đường (${filteredAssets.length})',
                ),
                Tab(
                  icon: const Icon(Icons.pending_actions, size: 20),
                  text:
                      'Hiện Vật Chờ Xử Lý Vòng Đời (${filteredPending.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history_edu, size: 20),
                  text:
                      'Nhật Ký Đã Tiêu Hao & Hoàn Trả (${processedBase.length})',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssetList(filteredAssets, isWide),
                _buildPendingList(filteredPending),
                _buildProcessedList(
                  filteredProcessed,
                  processedBase,
                  uiState,
                  isWide,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(ContributionUiState state, bool isWide) {
    final widgets = [
      _statMini(
        'TỔNG SỐ BẢO VẬT',
        '${state.totalAssetItemCount} hiện vật',
        Icons.account_balance,
        const Color(0xFF8B1E1E),
        'Lưu giữ tại nhà thờ tổ',
      ),
      _statMini(
        'TỔNG GIÁ TRỊ QUY ĐỔI ƯỚC TÍNH',
        currencyFormatter.format(state.totalAssetValue),
        Icons.monetization_on,
        const Color(0xFF2E8B43),
        'Đã hội đồng thẩm định',
      ),
      _statMini(
        'HIỆN VẬT LỄ CHỜ NHẬP KHO',
        '${state.pendingInKindCount} món',
        Icons.hourglass_bottom,
        const Color(0xFFB45309),
        'Chờ phân loại sau đại lễ',
      ),
      _statMini(
        'ĐÃ TIÊU HAO & HOÀN TRẢ',
        '${state.processedInKindCount} món',
        Icons.fact_check,
        const Color(0xFF475569),
        'Lưu vĩnh viễn trên sổ cái',
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1150) {
      return Row(
        children: widgets
            .map((w) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: w,
                  ),
                ))
            .toList(),
      );
    } else if (screenWidth > 680) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 8),
                  child: widgets[0],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: widgets[1],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: widgets[2],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: widgets[3],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: widgets
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: w,
                ))
            .toList(),
      );
    }
  }

  Widget _statMini(String label, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF4A3B32), // Tương phản cao >= 4.5:1
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách bảo vật trong kho dòng họ
  Widget _buildAssetList(List<ClanAssetDto> assets, bool isWide) {
    if (assets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 44, color: Color(0xFF78655C)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy bảo vật phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1810),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy thử tìm kiếm với từ khóa khác hoặc đặt lại bộ lọc danh mục.',
                style: TextStyle(color: Color(0xFF4A3B32), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(contributionUiProvider.notifier).setSearchQuery('');
                  setState(() {
                    _selectedCategory = 'all';
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Đặt Lại Bộ Lọc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E1E),
                  side: const BorderSide(color: Color(0xFF8B1E1E)),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _buildAssetCard(asset);
      },
    );
  }

  Widget _buildAssetCard(ClanAssetDto asset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mã định danh tem kèm nút sao chép nhanh
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: asset.assetId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép mã bảo vật: ${asset.assetId}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF8B1E1E),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E1E).withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF8B1E1E).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        asset.assetId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1E1E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 12, color: Color(0xFF8B1E1E)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFD4A017).withAlpha(120),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, size: 12, color: Color(0xFF8A5300)),
                    SizedBox(width: 4),
                    Text(
                      'Bảo Vật Từ Đường',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A5300),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                currencyFormatter.format(asset.assessedValue),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            asset.assetName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: Color(0xFF8B1E1E)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  asset.storageLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A3B32), // Độ tương phản cao >= 4.5:1
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Text(
                  'Số lượng: ${asset.quantity} ${asset.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B1810),
                  ),
                ),
              ),
            ],
          ),
          if (asset.originDonorName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.volunteer_activism,
                    size: 14, color: Color(0xFF8B1E1E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cúng tiến: ${asset.originDonorName}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A3B32),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 22, color: Color(0xFFF0EDEB)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAssetQrDialog(asset),
                icon: const Icon(Icons.qr_code_2, size: 16),
                label: const Text('In Tem QR Bảo Vật'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E1E),
                  side: const BorderSide(color: Color(0xFF8B1E1E)),
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showOriginReceiptDialog(asset),
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Xem Phiếu Cúng Tiến'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F0E8),
                  foregroundColor: const Color(0xFF8B1E1E),
                  elevation: 0,
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE6DFD8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Danh sách hiện vật sự kiện chờ phân loại vòng đời
  Widget _buildPendingList(List<InKindElectronicReceiptDto> pendingItems) {
    if (pendingItems.isEmpty) {
      final isFiltered = _selectedCategory != 'all' ||
          ref.read(contributionUiProvider).searchQuery.isNotEmpty;
      if (isFiltered) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE6DFD8)),
                  ),
                  child: const Icon(Icons.filter_list_off,
                      size: 44, color: Color(0xFF78655C)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không tìm thấy hiện vật chờ xử lý phù hợp bộ lọc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Không có hiện vật nào thuộc phân loại "${_categories[_selectedCategory]}" đang chờ phân loại.',
                  style: const TextStyle(color: Color(0xFF4A3B32), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(contributionUiProvider.notifier).setSearchQuery('');
                    setState(() => _selectedCategory = 'all');
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Đặt Lại Bộ Lọc'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B1E1E),
                    side: const BorderSide(color: Color(0xFF8B1E1E)),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B43).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 48, color: Color(0xFF2E8B43)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tất cả hiện vật sự kiện đã được phân loại vòng đời!',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B43),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Không còn món đồ lễ nào ở trạng thái chờ phân loại.',
                style: TextStyle(color: Color(0xFF4A3B32), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pendingItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = pendingItems[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6DFD8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.schedule, size: 13, color: Color(0xFFB45309)),
                        SizedBox(width: 4),
                        Text(
                          'ĐANG DÂNG LỄ (PENDING)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(item.convertedMonetaryValue),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${item.itemName} (${item.quantity} ${item.unit})',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1810),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Người cúng tiến: ${item.payerMemberName ?? item.payerMemberId} • ${item.conversionMethod.displayName}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A3B32), // Tương phản cao
                ),
              ),
              const Divider(height: 20, color: Color(0xFFF0EDEB)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(contributionUiProvider.notifier)
                          .processInKindLifecycle(
                            contributionId: item.contributionId,
                            targetStatus: InKindProcessingStatus.Consumed,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã đánh dấu "${item.itemName}" là ĐÃ TIÊU HAO CHO CỖ BÀN!'),
                          backgroundColor: const Color(0xFF475569),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('Đã Tiêu Hao Cỗ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFF94A3B8)),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(contributionUiProvider.notifier)
                          .processInKindLifecycle(
                            contributionId: item.contributionId,
                            targetStatus: InKindProcessingStatus.Returned,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã đánh dấu "${item.itemName}" là ĐÃ HOÀN TRẢ GIA CHỦ!'),
                          backgroundColor: const Color(0xFF0284C7),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_return, size: 16),
                    label: const Text('Đã Hoàn Trả Gia Chủ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _promptAddToAssetsDialog(item),
                    icon: const Icon(Icons.account_balance, size: 16),
                    label: const Text('Nhập Kho Từ Đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E1E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Danh sách hiện vật đã xử lý vòng đời (Đã tiêu hao cỗ bàn / Hoàn trả / Nhập kho)
  Widget _buildProcessedList(
    List<InKindElectronicReceiptDto> processedItems,
    List<InKindElectronicReceiptDto> processedBase,
    ContributionUiState state,
    bool isWide,
  ) {
    return Column(
      children: [
        // Heritage Audit Notice & Sub-filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F2),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFD4A017).withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user,
                        color: Color(0xFF8B1E1E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF4A3B32),
                            height: 1.35,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Lưu Trữ Lịch Sử Vĩnh Viễn: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B1E1E),
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Mọi hiện vật cúng tiến dù đã tiêu hao cho cỗ bàn hay hoàn trả gia chủ đều được lưu vĩnh viễn trong Sổ cái & CSDL. Công đức gia chủ luôn được bảo toàn và có thể tra cứu phiếu thu bất cứ lúc nào.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildProcessedFilterChip(
                      'Tất cả lịch sử',
                      'all',
                      processedBase.length,
                    ),
                    const SizedBox(width: 8),
                    _buildProcessedFilterChip(
                      'Đã tiêu hao cỗ bàn',
                      'consumed',
                      processedBase
                          .where((i) =>
                              i.processingStatus ==
                              InKindProcessingStatus.Consumed)
                          .length,
                      color: const Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    _buildProcessedFilterChip(
                      'Đã hoàn trả gia chủ',
                      'returned',
                      processedBase
                          .where((i) =>
                              i.processingStatus ==
                              InKindProcessingStatus.Returned)
                          .length,
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    _buildProcessedFilterChip(
                      'Đã nhập kho từ đường',
                      'assets',
                      processedBase
                          .where((i) =>
                              i.processingStatus ==
                              InKindProcessingStatus.AddedToCommonAssets)
                          .length,
                      color: const Color(0xFF8B1E1E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE6DFD8)),

        // Body list
        Expanded(
          child: processedItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE6DFD8)),
                          ),
                          child: const Icon(Icons.filter_alt_off,
                              size: 44, color: Color(0xFF78655C)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Không tìm thấy hiện vật phù hợp bộ lọc',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedCategory != 'all'
                              ? 'Không có hiện vật nào thuộc danh mục "${_categories[_selectedCategory]}" trong mục này.'
                              : 'Chưa có hiện vật nào ở nhóm xử lý đã chọn.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Color(0xFF54433E), fontSize: 13),
                        ),
                        if (_selectedCategory != 'all' ||
                            _selectedProcessedFilter != 'all' ||
                            state.searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(contributionUiProvider.notifier).setSearchQuery('');
                              setState(() {
                                _selectedCategory = 'all';
                                _selectedProcessedFilter = 'all';
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Xem Tất Cả Lịch Sử'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8B1E1E),
                              side: const BorderSide(color: Color(0xFF8B1E1E)),
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: processedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = processedItems[index];
                    return _buildProcessedItemCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProcessedFilterChip(String label, String key, int count,
      {Color color = const Color(0xFF8B1E1E)}) {
    final isSelected = _selectedProcessedFilter == key;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedProcessedFilter = key;
        });
      },
      backgroundColor: const Color(0xFFFAF9F6),
      selectedColor: color,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF4A3B32),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : const Color(0xFFE6DFD8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: false,
    );
  }

  Widget _buildProcessedItemCard(InKindElectronicReceiptDto item) {
    IconData statusIcon;
    String statusTitle;
    Color statusColor;
    Color statusBg;

    switch (item.processingStatus) {
      case InKindProcessingStatus.Consumed:
        statusIcon = Icons.restaurant;
        statusTitle = 'ĐÃ TIÊU HAO CHO CỖ BÀN';
        statusColor = const Color(0xFF475569);
        statusBg = const Color(0xFFF1F5F9);
        break;
      case InKindProcessingStatus.Returned:
        statusIcon = Icons.assignment_return;
        statusTitle = 'ĐÃ HOÀN TRẢ GIA CHỦ';
        statusColor = const Color(0xFF0284C7);
        statusBg = const Color(0xFFE0F2FE);
        break;
      case InKindProcessingStatus.AddedToCommonAssets:
        statusIcon = Icons.account_balance;
        statusTitle = 'ĐÃ NHẬP KHO BẢO VẬT TỪ ĐƯỜNG';
        statusColor = const Color(0xFF8B1E1E);
        statusBg = const Color(0xFFFEF2F2);
        break;
      case InKindProcessingStatus.Pending:
        statusIcon = Icons.schedule;
        statusTitle = 'CHỜ XỬ LÝ';
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFFEF3C7);
        break;
    }

    final dateStr = item.contributionDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(item.contributionDate!)
        : '02/11/2026';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.receiptNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Đã sao chép mã phiếu: ${item.receiptNumber}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF8B1E1E),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE6DFD8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.receiptNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF54433E),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.copy, size: 10, color: Color(0xFF54433E)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                currencyFormatter.format(item.convertedMonetaryValue),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B43),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${item.itemName} (${item.quantity} ${item.unit})',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.person, size: 15, color: Color(0xFF8B1E1E)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Cúng tiến: ${item.payerMemberName ?? item.payerMemberId} • ${item.conversionMethod.displayName}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A3B32),
                  ),
                ),
              ),
              const Icon(Icons.access_time, size: 13, color: Color(0xFF78655C)),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF78655C),
                ),
              ),
            ],
          ),
          if (item.processingStatus == InKindProcessingStatus.Consumed) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hiện vật đã được dùng cho lễ cúng tế & cỗ bàn thụ lộc. Công đức gia chủ được lưu trữ vĩnh viễn trên Sổ cái.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 20, color: Color(0xFFF0EDEB)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(contributionUiProvider.notifier)
                      .processInKindLifecycle(
                        contributionId: item.contributionId,
                        targetStatus: InKindProcessingStatus.Pending,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Đã hoàn tác "${item.itemName}" về hàng đợi Chờ Xử Lý!'),
                      backgroundColor: const Color(0xFFB45309),
                    ),
                  );
                },
                icon: const Icon(Icons.replay, size: 15),
                label: const Text('Phân loại lại'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        ElectronicReceiptDialog(inKindReceipt: item),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Xem Phiếu Thu Điện Tử'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E1E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _promptAddToAssetsDialog(InKindElectronicReceiptDto item) {
    final locationCtrl = TextEditingController(
        text: 'Gian thờ chính - Nhà thờ tổ đại gia tộc');

    final locationPresets = [
      'Gian thờ chính - Nhà thờ tổ',
      'Hậu cung từ đường',
      'Tủ bảo vật số 1',
      'Nhà bia tổ dòng họ',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.temple_buddhist, color: Color(0xFF8B1E1E), size: 24),
              SizedBox(width: 8),
              Text(
                'Nhập Kho Bảo Vật Từ Đường',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1E1E),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE6DFD8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Số lượng: ${item.quantity} ${item.unit} • Thẩm định: ${currencyFormatter.format(item.convertedMonetaryValue)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF4A3B32),
                        ),
                      ),
                      if (item.payerMemberName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Cúng tiến: ${item.payerMemberName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A3B32),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn nhanh vị trí lưu kho:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3B32),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: locationPresets.map((loc) {
                    final isCurrent = locationCtrl.text == loc;
                    return ActionChip(
                      label: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isCurrent
                              ? const Color(0xFF8B1E1E)
                              : const Color(0xFF4A3B32),
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isCurrent
                          ? const Color(0xFF8B1E1E).withAlpha(20)
                          : const Color(0xFFFAF9F6),
                      side: BorderSide(
                        color: isCurrent
                            ? const Color(0xFF8B1E1E)
                            : const Color(0xFFE6DFD8),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          locationCtrl.text = loc;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: locationCtrl,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF2B1810),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Vị trí lưu kho chi tiết *',
                    labelStyle: TextStyle(color: Color(0xFF54433E)),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(contributionUiProvider.notifier)
                    .processInKindLifecycle(
                      contributionId: item.contributionId,
                      targetStatus: InKindProcessingStatus.AddedToCommonAssets,
                      storageLocation: locationCtrl.text.trim(),
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Đã kết chuyển "${item.itemName}" vào Sổ kho bảo vật Từ Đường thành công!'),
                    backgroundColor: const Color(0xFF2E8B43),
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Xác Nhận Nhập Kho'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssetQrDialog(ClanAssetDto asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4A017), width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: Color(0xFF8B1E1E), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'TEM QR ĐỊNH DANH BẢO VẬT',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1E1E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6DFD8)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2,
                      size: 140, color: Color(0xFF8B1E1E)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: asset.assetId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Đã sao chép mã định danh: ${asset.assetId}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF8B1E1E),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            asset.assetId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy,
                              size: 14, color: Color(0xFF8B1E1E)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.assetName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF2B1810),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vị trí: ${asset.storageLocation}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A3B32), // Tương phản cao
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tem mã QR decal bạc chống ẩm mốc (khổ tiêu chuẩn 50x30mm), dán trực tiếp tại đế hoặc khung hiện vật phục vụ công tác kiểm kê định kỳ.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF334155), // WCAG AA compliant >= 4.5:1
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E1E),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('In Tem QR (Khổ 50x30mm)'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Đang gửi lệnh in tem QR cho "${asset.assetName}"...'),
                  backgroundColor: const Color(0xFF8B1E1E),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showOriginReceiptDialog(ClanAssetDto asset) {
    final receipt = InKindElectronicReceiptDto(
      receiptNumber:
          'PT-ASSET-${asset.assetId.replaceAll(RegExp(r'[^0-9]'), '')}',
      contributionId: asset.originContributionId ?? 'CTRIB-DEMO',
      eventId: 'EVT-GIO-TO-2026',
      eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
      payerMemberId: 'MEM-DONOR',
      payerMemberName: asset.originDonorName ?? 'Hội Đồng Tộc Biểu',
      receiverAccountId: 'ACC-TREASURER-01',
      itemName: asset.assetName,
      quantity: asset.quantity.toDouble(),
      unit: asset.unit,
      conversionMethod: ConversionMethod.Agreement,
      convertedMonetaryValue: asset.assessedValue,
      convertedMonetaryValueInWords: 'Đã thẩm định giá trị',
      processingStatus: InKindProcessingStatus.AddedToCommonAssets,
      storageLocation: asset.storageLocation,
      contributionDate: asset.createdAt,
    );

    showDialog(
      context: context,
      builder: (_) => ElectronicReceiptDialog(inKindReceipt: receipt),
    );
  }

  // Modal Đăng Ký Trực Tiếp Bảo Vật Mới Vào Kho Từ Đường (Task #74)
  void _showAddAssetModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'bộ');
    final valCtrl = TextEditingController(text: '10000000');
    final locCtrl = TextEditingController(text: 'Gian chính từ đường đại gia tộc');
    final donorCtrl = TextEditingController();
    String valWords = VietnameseMoneyConverter.toWords(10000000);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 30,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1E1E).withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_box_outlined,
                                    color: Color(0xFF8B1E1E), size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Đăng Ký Bảo Vật Vào Kho',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF54433E)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Định danh và quản lý các đồ thờ gia bảo, cổ vật lưu giữ tại nhà thờ tổ dòng họ.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF78655C)),
                      ),
                      const Divider(height: 24, color: Color(0xFFE6DFD8)),

                      // Tên bảo vật
                      const Text(
                        'Tên hiện vật / Đồ thờ gia bảo *',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: Đỉnh đồng chạm tam khí, Hoành phi Phúc Mãn Đường...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF78655C)),
                          filled: true,
                          fillColor: const Color(0xFFFAF9F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên hiện vật' : null,
                      ),
                      const SizedBox(height: 14),

                      // Số lượng & Đơn vị
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số lượng *',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2B1810)),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFFAF9F6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Hợp lệ > 0' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đơn vị tính *',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2B1810)),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: unitCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'bộ, chiếc, pho...',
                                    filled: true,
                                    fillColor: const Color(0xFFFAF9F6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập đơn vị' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Giá trị thẩm định ước tính
                      const Text(
                        'Giá trị thẩm định ước tính (VNĐ) *',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2B1810)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: valCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFAF9F6),
                          suffixText: 'VNĐ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          setModalState(() {
                            valWords = VietnameseMoneyConverter.toWords(parsed);
                          });
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nhập giá trị';
                          final num = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                          return (num == null || num <= 0) ? 'Giá trị phải lớn hơn 0' : null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF8F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD4A017).withAlpha(80)),
                        ),
                        child: Text(
                          'Bằng chữ: $valWords',
                          style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF7A1518), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Vị trí lưu kho
                      const Text(
                        'Vị trí lưu kho tại từ đường *',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2B1810)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: locCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: Ban thờ cụ Thủy Tổ, Hậu cung, Tủ kính số 1...',
                          filled: true,
                          fillColor: const Color(0xFFFAF9F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập vị trí' : null,
                      ),
                      const SizedBox(height: 14),

                      // Nguồn gốc / Người cung tiến
                      const Text(
                        'Nguồn gốc / Người cung tiến (Tùy chọn)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2B1810)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: donorCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: Gia bảo tiền nhân để lại, Chi 1 hiến tặng...',
                          filled: true,
                          fillColor: const Color(0xFFFAF9F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // CTA Button
                      ElevatedButton.icon(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final parsedVal = double.tryParse(valCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          final parsedQty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                          ref.read(contributionUiProvider.notifier).addDirectClanAsset(
                            assetName: nameCtrl.text.trim(),
                            quantity: parsedQty,
                            unit: unitCtrl.text.trim(),
                            assessedValue: parsedVal,
                            storageLocation: locCtrl.text.trim(),
                            originDonorName: donorCtrl.text.trim().isNotEmpty ? donorCtrl.text.trim() : 'Gia phả tiền nhân',
                          );

                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã đăng ký "${nameCtrl.text.trim()}" vào kho từ đường thành công!'),
                              backgroundColor: const Color(0xFF2E8B43),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2, size: 20),
                        label: const Text(
                          'Lưu Vào Kho & Cấp Mã Định Danh QR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E1E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
