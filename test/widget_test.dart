// Smoke tests covering navigation between all six screens and a
// few of the key placeholder elements on each one.

import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/main.dart';

void main() {
  testWidgets('Main menu shows title and all navigation buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    expect(find.text('ANIMAL TCG'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Deck Builder'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Collection screen shows the card grid and filter chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();

    expect(find.text('Card Collection'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);
  });

  testWidgets('Deck Builder screen shows both panels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Deck Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Available Cards'), findsOneWidget);
    expect(find.text('Current Deck'), findsOneWidget);
    expect(find.text('5/30'), findsOneWidget);
  });

  testWidgets('Settings screen shows the toggle switches', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
  });

  testWidgets('Play leads to the lobby, then the board, then results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Game Lobby'), findsOneWidget);
    expect(find.text('Create Game'), findsOneWidget);
    expect(find.text('Join Game'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Game Board'), findsOneWidget);
    expect(find.text('End Turn'), findsOneWidget);
    expect(find.text('Game Log'), findsOneWidget);

    await tester.tap(find.byTooltip('Preview results screen (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Game Results'), findsOneWidget);
    expect(find.text('Victory!'), findsOneWidget);
  });

  testWidgets('End Turn flips the turn indicator and adds a log entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text("Turn 1 • Your Turn"), findsOneWidget);

    await tester.tap(find.text('End Turn'));
    await tester.pump();

    expect(find.text("Turn 1 • Opponent's Turn"), findsOneWidget);
  });
}
