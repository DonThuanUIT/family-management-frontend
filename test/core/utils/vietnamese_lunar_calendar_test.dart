import 'package:familyfund_app/core/utils/vietnamese_lunar_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US-27: VietnameseLunarCalendar Unit Tests', () {
    test('Calculates Can Chi of year accurately', () {
      expect(VietnameseLunarCalendar.getCanChiYear(2024), 'Giáp Thìn');
      expect(VietnameseLunarCalendar.getCanChiYear(2025), 'Ất Tỵ');
      expect(VietnameseLunarCalendar.getCanChiYear(2026), 'Bính Ngọ');
      expect(VietnameseLunarCalendar.getCanChiYear(2027), 'Đinh Mùi');
      expect(VietnameseLunarCalendar.getCanChiYear(1990), 'Canh Ngọ');
      expect(VietnameseLunarCalendar.getCanChiYear(1984), 'Giáp Tý');
    });

    test('Converts solar date 2024-03-24 to lunar 15/02 Giáp Thìn (Rằm tháng 2)', () {
      final solar = DateTime(2024, 3, 24);
      final lunar = VietnameseLunarCalendar.convertSolarToLunar(solar);

      expect(lunar.day, 15);
      expect(lunar.month, 2);
      expect(lunar.year, 2024);
      expect(lunar.isLeap, isFalse);
      expect(lunar.canChiYear, 'Giáp Thìn');
      expect(lunar.formattedAnniversary, '15/02 Giáp Thìn');
      expect(lunar.toFullAnniversaryString(), 'Ngày 15 tháng 02 năm Giáp Thìn (Âm lịch)');
    });

    test('Converts solar date 2024-02-10 to Tet Giap Thin (01/01 Giáp Thìn)', () {
      final solar = DateTime(2024, 2, 10);
      final lunar = VietnameseLunarCalendar.convertSolarToLunar(solar);

      expect(lunar.day, 1);
      expect(lunar.month, 1);
      expect(lunar.year, 2024);
      expect(lunar.canChiYear, 'Giáp Thìn');
      expect(lunar.formattedAnniversary, '01/01 Giáp Thìn');
    });

    test('Converts solar date 2025-01-29 to Tet At Ty (01/01 Ất Tỵ)', () {
      final solar = DateTime(2025, 1, 29);
      final lunar = VietnameseLunarCalendar.convertSolarToLunar(solar);

      expect(lunar.day, 1);
      expect(lunar.month, 1);
      expect(lunar.year, 2025);
      expect(lunar.canChiYear, 'Ất Tỵ');
      expect(lunar.formattedAnniversary, '01/01 Ất Tỵ');
    });

    test('Calculates age at death correctly', () {
      final dob = DateTime(1940, 5, 10);
      final deathDate = DateTime(2024, 3, 24); // Chưa qua sinh nhật tháng 5 -> 83 tuổi
      expect(VietnameseLunarCalendar.calculateAge(dob, deathDate), 83);

      final deathDateAfterBirthday = DateTime(2024, 6, 1); // Đã qua sinh nhật tháng 5 -> 84 tuổi
      expect(VietnameseLunarCalendar.calculateAge(dob, deathDateAfterBirthday), 84);

      expect(VietnameseLunarCalendar.calculateAge(null, deathDate), isNull);
    });
  });
}
