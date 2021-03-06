// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:flutter_widgets/src/scrollable_positioned_list/scrollable_positioned_list.dart';

const screenHeight = 400.0;
const screenWidth = 400.0;
const itemWidth = screenWidth / 10.0;
const itemCount = 500;
const scrollDuration = Duration(seconds: 1);

void main() {
  Future<void> setUp(WidgetTester tester,
      {ItemScrollController itemScrollController,
      ItemPositionsListener itemPositionsListener,
      bool reverse = false}) async {
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    tester.binding.window.physicalSizeTestValue =
        const Size(screenWidth, screenHeight);

    await tester.pumpWidget(
      MaterialApp(
        home: ScrollablePositionedList.builder(
          itemCount: itemCount,
          itemScrollController: itemScrollController,
          itemBuilder: (context, index) => SizedBox(
            width: itemWidth,
            child: Text('Item $index'),
          ),
          itemPositionsListener: itemPositionsListener,
          scrollDirection: Axis.horizontal,
          reverse: reverse,
        ),
      ),
    );
  }

  testWidgets('List positioned with 0 at left', (WidgetTester tester) async {
    final itemPositionsListener = ItemPositionsListener.create();
    await setUp(tester, itemPositionsListener: itemPositionsListener);

    expect(tester.getTopLeft(find.text('Item 0')).dx, 0);
    expect(tester.getBottomRight(find.text('Item 9')).dx, screenWidth);
    expect(find.text('Item 10'), findsNothing);

    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 0)
            .itemLeadingEdge,
        0);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 0)
            .itemTrailingEdge,
        1 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 9)
            .itemTrailingEdge,
        1);
  });

  testWidgets('List positioned with 0 at right', (WidgetTester tester) async {
    final itemPositionsListener = ItemPositionsListener.create();
    await setUp(tester,
        itemPositionsListener: itemPositionsListener, reverse: true);

    expect(tester.getBottomRight(find.text('Item 0')).dx, screenWidth);
    expect(tester.getTopLeft(find.text('Item 9')).dx, 0);
    expect(find.text('Item 10'), findsNothing);

    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 0)
            .itemLeadingEdge,
        0);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 0)
            .itemTrailingEdge,
        1 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 9)
            .itemTrailingEdge,
        1);
  });

  testWidgets('Scroll to 2 (already on screen)', (WidgetTester tester) async {
    final itemScrollController = ItemScrollController();
    final itemPositionsListener = ItemPositionsListener.create();
    await setUp(tester,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener);

    unawaited(
        itemScrollController.scrollTo(index: 2, duration: scrollDuration));
    await tester.pump();
    await tester.pump(scrollDuration);

    expect(find.text('Item 1'), findsNothing);
    expect(tester.getTopLeft(find.text('Item 2')).dx, 0);

    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 2)
            .itemLeadingEdge,
        0);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 2)
            .itemTrailingEdge,
        1 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 11)
            .itemTrailingEdge,
        1);
  });

  testWidgets('Scroll to 100 (not already on screen)',
      (WidgetTester tester) async {
    final itemScrollController = ItemScrollController();
    final itemPositionsListener = ItemPositionsListener.create();
    await setUp(tester,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener);

    unawaited(
        itemScrollController.scrollTo(index: 100, duration: scrollDuration));
    await tester.pumpAndSettle();

    expect(find.text('Item 99'), findsNothing);
    expect(find.text('Item 100'), findsOneWidget);

    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 100)
            .itemLeadingEdge,
        0);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 100)
            .itemTrailingEdge,
        1 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 109)
            .itemTrailingEdge,
        1);
  });

  testWidgets('Jump to 100', (WidgetTester tester) async {
    final itemScrollController = ItemScrollController();
    final itemPositionsListener = ItemPositionsListener.create();
    await setUp(tester,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener);

    itemScrollController.jumpTo(index: 100);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Item 100')).dx, 0);
    expect(tester.getBottomRight(find.text('Item 109')).dy, screenWidth);

    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 100)
            .itemLeadingEdge,
        0);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 100)
            .itemTrailingEdge,
        1 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 109)
            .itemLeadingEdge,
        9 / 10);
    expect(
        itemPositionsListener.itemPositions.value
            .firstWhere((position) => position.index == 109)
            .itemTrailingEdge,
        1);
  });
}
