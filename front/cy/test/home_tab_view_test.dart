import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cy/features/home/domain/weather_data.dart';
import 'package:cy/features/home/domain/weather_state.dart';
import 'package:cy/features/home/presentation/providers/weather_provider.dart';
import 'package:cy/features/home/presentation/widgets/home_tab_view.dart';

class _FakeWeatherNotifier extends StateNotifier<WeatherState>
    implements WeatherNotifier {
  _FakeWeatherNotifier(super.state);

  @override
  Future<void> fetchForCurrentLocation() async {}

  @override
  Future<void> refresh() async {}
}

Widget _wrapHome({
  required void Function(int minutes, String type, String tripMode, int stayMinutes)
      onFindDestination,
}) {
  return ProviderScope(
    overrides: [
      weatherProvider.overrideWith(
        (ref) => _FakeWeatherNotifier(
          const WeatherLoaded(
            WeatherData(
              temperatureC: 22.5,
              windSpeedKmh: 12.0,
              humidityPercent: 55,
              weatherCode: 0,
            ),
          ),
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: HomeTabView(onFindDestination: onFindDestination),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeTabView renders hero, trip mode, duration card, and genres',
      (WidgetTester tester) async {
    int? calledMinutes;
    String? calledType;
    String? calledMode;
    int? calledStay;

    await tester.pumpWidget(
      _wrapHome(
        onFindDestination: (minutes, type, tripMode, stayMinutes) {
          calledMinutes = minutes;
          calledType = type;
          calledMode = tripMode;
          calledStay = stayMinutes;
        },
      ),
    );
    await tester.pumpAndSettle();

    // タイトルと各セクション
    expect(find.text('CyChronos'), findsOneWidget);
    expect(find.text('移動方法'), findsOneWidget);
    expect(find.text('片道'), findsOneWidget);
    expect(find.text('往復'), findsOneWidget);
    expect(find.text('所要時間'), findsOneWidget);
    expect(find.text('希望の所要時間'), findsOneWidget);
    expect(find.text('ジャンル'), findsOneWidget);
    expect(find.text('行きたいスポット'), findsOneWidget);
    expect(find.text('ルートを検索'), findsOneWidget);

    // デフォルト所要時間は45分
    expect(find.text('45'), findsAtLeastNWidgets(1));
    expect(find.text('カフェ'), findsOneWidget);

    // ルートを検索をタップ
    await tester.tap(find.text('ルートを検索'));
    await tester.pumpAndSettle();

    expect(calledMinutes, 45);
    expect(calledType, 'cafe');
    expect(calledMode, 'one_way');
    expect(calledStay, 0);
  });

  testWidgets('HomeTabView adjusts duration with stepper buttons and toggles round trip',
      (WidgetTester tester) async {
    int? calledMinutes;
    String? calledType;
    String? calledMode;
    int? calledStay;

    await tester.pumpWidget(
      _wrapHome(
        onFindDestination: (minutes, type, tripMode, stayMinutes) {
          calledMinutes = minutes;
          calledType = type;
          calledMode = tripMode;
          calledStay = stayMinutes;
        },
      ),
    );
    await tester.pumpAndSettle();

    // 画面を少し下にスクロールして+15分をタップ (60分 = 1時間0分にする)
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+15分'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsAtLeastNWidgets(1));
    expect(find.text('時間'), findsAtLeastNWidgets(1));

    // 往復モードに切り替える
    await tester.tap(find.text('往復'));
    await tester.pumpAndSettle();

    // 滞在・休憩時間セクションが現れること
    expect(find.text('滞在・休憩時間'), findsOneWidget);

    // 30分の滞在プリセットをタップ
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30分').first);
    await tester.pumpAndSettle();

    // グルメジャンルを画面中央にスクロールしてタップ
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('グルメ'));
    await tester.pumpAndSettle();

    // ルートを検索をタップ
    await tester.tap(find.text('ルートを検索'));
    await tester.pumpAndSettle();

    expect(calledMinutes, 60);
    expect(calledType, 'restaurant');
    expect(calledMode, 'round_trip');
    expect(calledStay, 30);
  });
}
