// Các model dữ liệu cho tính năng nhập hàng loạt thành viên từ Excel/CSV (US-31).

class ImportMemberPreviewRowDto {
  final int rowNumber;
  final bool valid;
  final List<String> errors;
  final String? memberId;
  final String? fullName;
  final String? dateOfBirth;
  final String? rawDateOfBirth;
  final String? gender;
  final int? generation;
  final String? branchId;
  final String? branchName;
  final String? status;
  final String? deathDate;
  final String? rawDeathDate;
  final String? deathDateLunar;
  final String? burialPlace;

  const ImportMemberPreviewRowDto({
    required this.rowNumber,
    required this.valid,
    required this.errors,
    this.memberId,
    this.fullName,
    this.dateOfBirth,
    this.rawDateOfBirth,
    this.gender,
    this.generation,
    this.branchId,
    this.branchName,
    this.status,
    this.deathDate,
    this.rawDeathDate,
    this.deathDateLunar,
    this.burialPlace,
  });

  factory ImportMemberPreviewRowDto.fromJson(Map<String, dynamic> json) {
    return ImportMemberPreviewRowDto(
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      valid: json['valid'] == true,
      errors: (json['errors'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      memberId: json['memberId']?.toString(),
      fullName: json['fullName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      rawDateOfBirth: json['rawDateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      generation: (json['generation'] as num?)?.toInt(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      status: json['status']?.toString(),
      deathDate: json['deathDate']?.toString(),
      rawDeathDate: json['rawDeathDate']?.toString(),
      deathDateLunar: json['deathDateLunar']?.toString(),
      burialPlace: json['burialPlace']?.toString(),
    );
  }

  ImportMemberRowRequestDto toConfirmRowRequest() {
    return ImportMemberRowRequestDto(
      rowNumber: rowNumber,
      memberId: memberId,
      fullName: fullName ?? '',
      dateOfBirth: dateOfBirth,
      gender: gender ?? '',
      generation: generation ?? 1,
      branchId: branchId ?? '',
      status: status ?? 'Living',
      deathDate: deathDate,
      burialPlace: burialPlace,
    );
  }
}

class ImportMembersPreviewResponseDto {
  final String fileName;
  final int totalRows;
  final int validCount;
  final int errorCount;
  final List<ImportMemberPreviewRowDto> rows;

  const ImportMembersPreviewResponseDto({
    required this.fileName,
    required this.totalRows,
    required this.validCount,
    required this.errorCount,
    required this.rows,
  });

  factory ImportMembersPreviewResponseDto.fromJson(Map<String, dynamic> json) {
    return ImportMembersPreviewResponseDto(
      fileName: json['fileName']?.toString() ?? '',
      totalRows: (json['totalRows'] as num?)?.toInt() ?? 0,
      validCount: (json['validCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as List<dynamic>? ?? const [])
          .map((e) => ImportMemberPreviewRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ImportMemberRowRequestDto {
  final int rowNumber;
  final String? memberId;
  final String fullName;
  final String? dateOfBirth;
  final String gender;
  final int generation;
  final String branchId;
  final String status;
  final String? deathDate;
  final String? burialPlace;

  const ImportMemberRowRequestDto({
    required this.rowNumber,
    this.memberId,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    required this.generation,
    required this.branchId,
    required this.status,
    this.deathDate,
    this.burialPlace,
  });

  Map<String, dynamic> toJson() {
    return {
      'rowNumber': rowNumber,
      if (memberId != null && memberId!.isNotEmpty) 'memberId': memberId,
      'fullName': fullName,
      if (dateOfBirth != null && dateOfBirth!.isNotEmpty) 'dateOfBirth': dateOfBirth,
      'gender': gender,
      'generation': generation,
      'branchId': branchId,
      'status': status,
      if (deathDate != null && deathDate!.isNotEmpty) 'deathDate': deathDate,
      if (burialPlace != null && burialPlace!.isNotEmpty) 'burialPlace': burialPlace,
    };
  }
}

class ConfirmMemberImportRequestDto {
  final List<ImportMemberRowRequestDto> rows;

  const ConfirmMemberImportRequestDto({required this.rows});

  Map<String, dynamic> toJson() {
    return {
      'rows': rows.map((r) => r.toJson()).toList(),
    };
  }
}

class ImportSkippedRowDto {
  final int rowNumber;
  final String? fullName;
  final List<String> errors;

  const ImportSkippedRowDto({
    required this.rowNumber,
    this.fullName,
    required this.errors,
  });

  factory ImportSkippedRowDto.fromJson(Map<String, dynamic> json) {
    return ImportSkippedRowDto(
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString(),
      errors: (json['errors'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ImportMembersConfirmResponseDto {
  final int insertedCount;
  final int skippedCount;
  final List<ImportSkippedRowDto> skippedRows;

  const ImportMembersConfirmResponseDto({
    required this.insertedCount,
    required this.skippedCount,
    required this.skippedRows,
  });

  factory ImportMembersConfirmResponseDto.fromJson(Map<String, dynamic> json) {
    return ImportMembersConfirmResponseDto(
      insertedCount: (json['insertedCount'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      skippedRows: (json['skippedRows'] as List<dynamic>? ?? const [])
          .map((e) => ImportSkippedRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
