import 'package:familyfund_app/core/utils/vietnamese_money_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VietnameseMoneyConverter', () {
    test('converts 80000009 accurately', () {
      final words = VietnameseMoneyConverter.toWords(80000009);
      expect(words, 'Tám mươi triệu không trăm linh chín đồng chẵn');
    });

    test('converts round millions', () {
      expect(VietnameseMoneyConverter.toWords(80000000),
          'Tám mươi triệu đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(5000000),
          'Năm triệu đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(1000000),
          'Một triệu đồng chẵn');
    });

    test('converts compound numbers', () {
      expect(VietnameseMoneyConverter.toWords(1250000),
          'Một triệu hai trăm năm mươi nghìn đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(3500000),
          'Ba triệu năm trăm nghìn đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(1000001),
          'Một triệu không trăm linh một đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(25000000),
          'Hai mươi lăm triệu đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(21000000),
          'Hai mươi mốt triệu đồng chẵn');
      expect(VietnameseMoneyConverter.toWords(15000000),
          'Mười lăm triệu đồng chẵn');
    });

    test('converts zero', () {
      expect(VietnameseMoneyConverter.toWords(0), 'Không đồng chẵn');
    });
  });
}
