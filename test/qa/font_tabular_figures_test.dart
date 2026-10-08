import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/theme/app_text_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Font Tabular Figures Verification (Point 7)', () {
    test('FontFeature.tabularFigures resolves to OpenType tnum feature tag', () {
      const tabular = FontFeature.tabularFigures();
      expect(tabular.feature, 'tnum');
    });

    test('AppTextStyles number styles include FontFeature.tabularFigures()', () {
      expect(
        AppTextStyles.numberHero.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        AppTextStyles.numberLarge.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        AppTextStyles.numberMedium.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        AppTextStyles.numberSmall.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('Font family is consistently Plus Jakarta Sans across typography', () {
      expect(AppTextStyles.titleLarge.fontFamily, contains('PlusJakartaSans'));
      expect(AppTextStyles.bodyMedium.fontFamily, contains('PlusJakartaSans'));
      expect(AppTextStyles.numberMedium.fontFamily, contains('PlusJakartaSans'));
    });
  });
}
