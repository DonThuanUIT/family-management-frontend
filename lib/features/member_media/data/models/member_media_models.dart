enum MediaVisibility {
  clan('CLAN', 'Trong dòng họ'),
  branch('BRANCH', 'Trong nhánh'),
  restricted('RESTRICTED', 'Giới hạn');

  const MediaVisibility(this.value, this.label);
  final String value;
  final String label;
  static MediaVisibility parse(Object? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => restricted);
}

class MemberMedia {
  final String memberId, fullName;
  final String? branchName, avatarUrl;
  final int generation, mediaVersion;
  final bool canEdit, canUpload, biographyRestricted;
  final Map<String, dynamic>? biography;
  final MediaVisibility visibility;
  MemberMedia.fromJson(Map<String, dynamic> json)
    : memberId = json['memberId'] as String,
      fullName = json['fullName'] as String,
      branchName = json['branchName'] as String?,
      avatarUrl = json['avatarUrl'] as String?,
      generation = (json['generation'] as num?)?.toInt() ?? 1,
      mediaVersion = (json['mediaVersion'] as num).toInt(),
      canEdit = (json['capabilities'] as Map?)?['canEditMedia'] == true,
      canUpload =
          (json['capabilities'] as Map?)?['canUploadAttachment'] == true,
      biographyRestricted = json['biographyAccess'] != 'VISIBLE',
      biography = json['biographyAccess'] == 'VISIBLE'
          ? (json['biography'] as Map?)?.cast<String, dynamic>()
          : null,
      visibility = MediaVisibility.parse(json['biographyVisibility']);
}

class FamilyAttachment {
  final String id, memberId, title, originalFilename, mimeType;
  final String? description;
  final int sizeBytes, version;
  final bool canEdit, canDelete;
  final MediaVisibility visibility;
  final DateTime? createdAt;
  bool get isImage => mimeType == 'image/jpeg' || mimeType == 'image/png';
  FamilyAttachment.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      memberId = json['memberId'] as String,
      title = json['title'] as String,
      originalFilename = json['originalFilename'] as String,
      mimeType = json['mimeType'] as String,
      description = json['description'] as String?,
      sizeBytes = (json['sizeBytes'] as num).toInt(),
      version = (json['version'] as num).toInt(),
      canEdit = json['canEdit'] == true,
      canDelete = json['canDelete'] == true,
      visibility = MediaVisibility.parse(json['visibility']),
      createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
}

class AttachmentPage {
  final List<FamilyAttachment> items;
  final int page, totalPages, totalElements;
  AttachmentPage.fromJson(Map<String, dynamic> json)
    : items = (json['items'] as List)
          .map(
            (e) =>
                FamilyAttachment.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt(),
      totalElements = (json['totalElements'] as num).toInt();
}
