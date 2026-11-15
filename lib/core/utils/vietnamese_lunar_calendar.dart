import 'dart:math' as math;

/// Model biểu diễn ngày tháng Âm lịch Việt Nam (US-27).
class VietnameseLunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeap;
  final String canChiYear;
  final String formattedAnniversary;

  const VietnameseLunarDate({
    required this.day,
    required this.month,
    required this.year,
    this.isLeap = false,
    required this.canChiYear,
    required this.formattedAnniversary,
  });

  /// Chuỗi hiển thị ngắn gọn: "15/02 Giáp Thìn" hoặc "15/02 Nhuận Giáp Thìn"
  String toShortAnniversaryString() {
    final dayStr = day.toString().padLeft(2, '0');
    final monthStr = month.toString().padLeft(2, '0');
    final leapStr = isLeap ? ' Nhuận ' : ' ';
    return '$dayStr/$monthStr$leapStr$canChiYear';
  }

  /// Chuỗi hiển thị đầy đủ trang trọng: "Ngày 15 tháng 02 năm Giáp Thìn (Âm lịch)"
  String toFullAnniversaryString() {
    final dayStr = day.toString().padLeft(2, '0');
    final monthStr = month.toString().padLeft(2, '0');
    final leapStr = isLeap ? ' (nhuận)' : '';
    return 'Ngày $dayStr tháng $monthStr$leapStr năm $canChiYear (Âm lịch)';
  }
}

/// Thuật toán chuyển đổi Dương lịch sang Âm lịch Việt Nam chuẩn múi giờ GMT+7 (US-27).
/// Dựa trên thuật toán thiên văn toán học của Hồ Ngọc Đức (Viện Công nghệ Thông tin).
class VietnameseLunarCalendar {
  static const double timeZone = 7.0;

  static const List<String> can = [
    'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'
  ];

  static const List<String> chi = [
    'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'
  ];

  /// Chuyển đổi đối tượng DateTime Dương lịch sang Âm lịch.
  static VietnameseLunarDate convertSolarToLunar(DateTime solarDate) {
    return convertSolar(solarDate.day, solarDate.month, solarDate.year);
  }

  /// Chuyển đổi ngày, tháng, năm Dương lịch sang Âm lịch.
  static VietnameseLunarDate convertSolar(int sDay, int sMonth, int sYear) {
    final dayNumber = _jdFromDate(sDay, sMonth, sYear);
    int k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    int monthStart = _getNewMoonDay(k + 1, timeZone);
    if (monthStart > dayNumber) {
      monthStart = _getNewMoonDay(k, timeZone);
    } else {
      k++;
    }

    int a11 = _getLunarMonth11(sYear, timeZone);
    int b11 = a11;
    int lYear;
    if (a11 >= monthStart) {
      lYear = sYear;
      a11 = _getLunarMonth11(sYear - 1, timeZone);
    } else {
      lYear = sYear + 1;
      b11 = _getLunarMonth11(sYear + 1, timeZone);
    }

    final lDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29.0).floor();
    int lMonth = diff + 11;
    bool isLeap = false;

    if (b11 - a11 > 365) {
      final leapMonthDiff = _getLeapMonthOffset(a11, timeZone);
      if (diff >= leapMonthDiff) {
        lMonth = diff + 10;
        if (diff == leapMonthDiff) {
          isLeap = true;
        }
      }
    }

    if (lMonth > 12) {
      lMonth -= 12;
    }
    if (lMonth >= 11 && diff < 4) {
      lYear--;
    }

    final canChi = getCanChiYear(lYear);
    final dayStr = lDay.toString().padLeft(2, '0');
    final monthStr = lMonth.toString().padLeft(2, '0');
    final leapStr = isLeap ? ' Nhuận ' : ' ';
    final formatted = '$dayStr/$monthStr$leapStr$canChi';

    return VietnameseLunarDate(
      day: lDay,
      month: lMonth,
      year: lYear,
      isLeap: isLeap,
      canChiYear: canChi,
      formattedAnniversary: formatted,
    );
  }

  /// Tính Can Chi của năm âm lịch (ví dụ: 2024 -> Giáp Thìn).
  static String getCanChiYear(int lunarYear) {
    int canIndex = (lunarYear + 6) % 10;
    if (canIndex < 0) canIndex += 10;

    int chiIndex = (lunarYear + 8) % 12;
    if (chiIndex < 0) chiIndex += 12;

    return '${can[canIndex]} ${chi[chiIndex]}';
  }

  /// Tính tuổi hưởng thọ từ ngày sinh đến ngày mất.
  static int? calculateAge(DateTime? dob, DateTime? deathDate) {
    if (dob == null || deathDate == null) return null;
    int age = deathDate.year - dob.year;
    if (deathDate.month < dob.month ||
        (deathDate.month == dob.month && deathDate.day < dob.day)) {
      age--;
    }
    return age > 0 ? age : 1;
  }

  // ==================== CÁC HÀM THIÊN VĂN NỘI BỘ ====================

  static int _jdFromDate(int dd, int mm, int yy) {
    final a = ((14 - mm) / 12).floor();
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    int jd = dd + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;
    if (jd < 2299161) {
      jd = dd + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - 32083;
    }
    return jd;
  }

  static int _getNewMoonDay(int k, double timeZone) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    const dr = math.pi / 180;

    double jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);

    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;

    double c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) + 0.0021 * math.sin(2 * m * dr);
    c1 -= 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(2 * mpr * dr);
    c1 -= 0.0004 * math.sin(3 * mpr * dr);
    c1 += 0.0104 * math.sin(2 * f * dr) - 0.0051 * math.sin((m + mpr) * dr);
    c1 -= 0.0074 * math.sin((m - mpr) * dr) + 0.0004 * math.sin((2 * f + m) * dr);
    c1 -= 0.0004 * math.sin((2 * f - m) * dr) - 0.0006 * math.sin((2 * f + mpr) * dr);
    c1 += 0.0010 * math.sin((2 * f - mpr) * dr) + 0.0005 * math.sin((m + 2 * mpr) * dr);

    final jd = jd1 + c1;
    return (jd + 0.5 + timeZone / 24.0).floor();
  }

  static double _getSunLongitude(int dayNumber, double timeZone) {
    final t = (dayNumber - 0.5 - timeZone / 24.0 - 2451545.0) / 36525.0;
    final t2 = t * t;
    const dr = math.pi / 180;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    double c = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(m * dr);
    c += (0.019993 - 0.000101 * t) * math.sin(2 * m * dr);
    c += 0.000290 * math.sin(3 * m * dr);
    final theta = l0 + c;
    double lambda = theta - 0.00569 - 0.00478 * math.sin((125.04 - 1934.136 * t) * dr);
    lambda = lambda * dr;
    lambda = lambda - math.pi * 2 * (lambda / (math.pi * 2)).floor();
    return (lambda / math.pi * 6).floorToDouble();
  }

  static int _getLunarMonth11(int yy, double timeZone) {
    final off = _jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    int nm = _getNewMoonDay(k, timeZone);
    final sunLong = _getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = _getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  static int _getLeapMonthOffset(int a11, double timeZone) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    int last = 0;
    int i = 1;
    double arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc.toInt();
      i++;
      arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc.toInt() != last && i < 14);
    return i - 1;
  }
}
