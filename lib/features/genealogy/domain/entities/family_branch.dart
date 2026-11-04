/// Thực thể nhánh gia phả (Domain Entity)
class FamilyBranchDetail {
  final String branchId;
  final String clanId;
  final String clanName;
  final String branchName;
  final int generationLevel;
  final String? parentBranchId;
  final String? representativeId;
  final String? representativeName;
  final String? description;
  final DateTime? createdAt;

  const FamilyBranchDetail({
    required this.branchId,
    required this.clanId,
    required this.clanName,
    required this.branchName,
    required this.generationLevel,
    this.parentBranchId,
    this.representativeId,
    this.representativeName,
    this.description,
    this.createdAt,
  });

  bool get isRoot => generationLevel == 1 && (parentBranchId == null || parentBranchId!.isEmpty);
}
