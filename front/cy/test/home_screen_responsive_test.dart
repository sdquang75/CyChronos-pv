// Verifies the redesigned Home tab and bottom nav don't overflow across a
// spread of real phone/tablet viewport sizes (independent of the desktop
// "device frame" preview in HomeScreen, which only kicks in above 390x1115).
import 'package:cy/features/home/presentation/widgets/floating_cta_button.dart';
import 'package:cy/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:cy/features/home/presentation/widgets/home_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = <String, Size>{
    'iPhone SE (320x568)': Size(320, 568),
    'Small Android (360x740)': Size(360, 740),
    'iPhone 13 (390x844)': Size(390, 844),
    'iPhone 11 Pro Max (414x896)': Size(414, 896),
    'Tablet portrait (768x1024)': Size(768, 1024),
  };

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final entry in sizes.entries) {
    testWidgets('HomeTabView has no overflow on ${entry.key}', (tester) async {
      await setViewport(tester, entry.value);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeTabView(
                scrollController: ScrollController(),
                stayDurationMinutes: '30',
                onStayDurationChanged: (_) {},
                spareTimeMinutes: '30',
                onSpareTimeChanged: (_) {},
                selectedGenreId: null,
                onGenreChanged: (_) {},
                onFindDestination: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeBottomNavBar has no overflow on ${entry.key}', (
      tester,
    ) async {
      await setViewport(tester, entry.value);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: entry.value.width,
                child: HomeBottomNavBar(currentIndex: 0, onTap: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('FloatingCtaButton has no overflow on ${entry.key}', (
      tester,
    ) async {
      await setViewport(tester, entry.value);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FloatingCtaButton(onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('HomeBottomNavBar tapping a tab calls onTap with its index', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 390,
              child: HomeBottomNavBar(
                currentIndex: 0,
                onTap: (index) => tapped = index,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(tapped, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeBottomNavBar dragging across the pill switches tabs', (
    tester,
  ) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 390,
                  child: HomeBottomNavBar(
                    currentIndex: currentIndex,
                    onTap: (index) => setState(() => currentIndex = index),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Drag from the first tab's label to the last tab's label, using their
    // actual rendered centers rather than assumed pixel offsets (which
    // shift whenever internal padding changes).
    final start = tester.getCenter(find.text('Explore'));
    final end = tester.getCenter(find.text('Settings'));

    await tester.dragFrom(start, end - start);
    await tester.pumpAndSettle();

    expect(currentIndex, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
