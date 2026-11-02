import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/event/presentation/screens/event_list_screen.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'EventListScreen renders clean screen with HeritageNavBar',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/events'),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EventListScreen), findsOneWidget);
      expect(find.byType(HeritageNavBar), findsOneWidget);
      expect(find.text('Sổ Cái'), findsWidgets);
      expect(find.text('Bảo Vật'), findsWidgets);
    },
  );
}
