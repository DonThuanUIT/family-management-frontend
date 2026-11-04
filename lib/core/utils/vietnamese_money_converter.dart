/// Tiện ích chuyển đổi số tiền thành chữ tiếng Việt chuẩn xác theo ngữ pháp kế toán & ngân hàng.
/// Ví dụ: 80000009 -> "Tám mươi triệu không trăm linh chín đồng chẵn"
class VietnameseMoneyConverter {
  VietnameseMoneyConverter._();

  static const List<String> _digits = [
    'không',
    'một',
    'hai',
    'ba',
    'bốn',
    'năm',
    'sáu',
    'bảy',
    'tám',
    'chín',
  ];

  static const List<String> _units = [
    '',
    'nghìn',
    'triệu',
    'tỷ',
    'nghìn tỷ',
    'triệu tỷ',
  ];

  /// Chuyển đổi số tiền VNĐ sang văn bản chữ tiếng Việt
  static String toWords(num? amount) {
    if (amount == null || amount == 0) {
      return 'Không đồng chẵn';
    }

    var value = amount.abs().toInt();
    if (value == 0) return 'Không đồng chẵn';

    // Chia thành các nhóm 3 chữ số từ phải sang trái
    final groups = <int>[];
    var temp = value;
    while (temp > 0) {
      groups.add(temp % 1000);
      temp ~/= 1000;
    }

    final parts = <String>[];

    for (var i = groups.length - 1; i >= 0; i--) {
      final group = groups[i];
      if (group == 0) {
        continue;
      }

      // Có nhóm cao hơn phía trước hay không
      final hasHigherGroup = i < groups.length - 1;
      final groupStr = _readThreeDigits(group, hasHigherGroup);
      final unitStr = _units[i];

      if (unitStr.isNotEmpty) {
        parts.add('$groupStr $unitStr');
      } else {
        parts.add(groupStr);
      }
    }

    if (parts.isEmpty) {
      return 'Không đồng chẵn';
    }

    var result = parts.join(' ').trim();
    // Viết hoa chữ cái đầu tiên và thêm hậu tố "đồng chẵn"
    result = '${result[0].toUpperCase()}${result.substring(1)} đồng chẵn';
    if (amount < 0) {
      result = 'Âm $result';
    }
    return result;
  }

  static String _readThreeDigits(int number, bool hasHigherGroup) {
    final hundreds = number ~/ 100;
    final remainder = number % 100;
    final tens = remainder ~/ 10;
    final ones = remainder % 10;

    final sb = <String>[];

    // Đọc hàng trăm
    if (hundreds > 0 || hasHigherGroup) {
      sb.add('${_digits[hundreds]} trăm');
    }

    // Đọc hàng chục và đơn vị
    if (tens > 1) {
      sb.add('${_digits[tens]} mươi');
      if (ones == 1) {
        sb.add('mốt');
      } else if (ones == 5) {
        sb.add('lăm');
      } else if (ones > 0) {
        sb.add(_digits[ones]);
      }
    } else if (tens == 1) {
      sb.add('mười');
      if (ones == 5) {
        sb.add('lăm');
      } else if (ones > 0) {
        sb.add(_digits[ones]);
      }
    } else {
      // tens == 0
      if (ones > 0) {
        if (hundreds > 0 || hasHigherGroup) {
          sb.add('linh ${_digits[ones]}');
        } else {
          sb.add(_digits[ones]);
        }
      }
    }

    return sb.join(' ').trim();
  }
}
