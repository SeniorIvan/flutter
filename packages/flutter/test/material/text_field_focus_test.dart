// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Dialog interaction', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    final FocusNode focusNode = FocusNode(debugLabel: 'Editable Text Node');

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              focusNode: focusNode,
              autofocus: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isTrue);

    final BuildContext context = tester.element(find.byType(TextField));

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => const SimpleDialog(title: Text('Dialog')),
    );

    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    Navigator.of(tester.element(find.text('Dialog'))).pop();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Request focus shows keyboard', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Autofocus shows keyboard', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              autofocus: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Tap shows keyboard', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: TextField(),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.idle();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Focus triggers keep-alive', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              TextField(
                focusNode: focusNode,
              ),
              Container(
                height: 1000.0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);

    focusNode.unfocus();
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Focus keep-alive works with GlobalKey reparenting', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    Widget makeTest(String prefix) {
      return MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              TextField(
                focusNode: focusNode,
                decoration: InputDecoration(
                  prefixText: prefix,
                ),
              ),
              Container(
                height: 1000.0,
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(makeTest(null));
    FocusScope.of(tester.element(find.byType(TextField))).requestFocus(focusNode);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0));
    await tester.pump();
    expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(makeTest('test'));
    await tester.pump(); // in case the AutomaticKeepAlive widget thinks it needs a cleanup frame
    expect(find.byType(TextField, skipOffstage: false), findsOneWidget);
  });

  testWidgets('TextField with decoration:null', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/16880

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              decoration: null
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.byType(TextField));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('Sibling FocusScopes', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    final FocusScopeNode focusScopeNode0 = FocusScopeNode();
    final FocusScopeNode focusScopeNode1 = FocusScopeNode();
    final Key textField0 = UniqueKey();
    final Key textField1 = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FocusScope(
                  node: focusScopeNode0,
                  child: Builder(
                    builder: (BuildContext context) => TextField(key: textField0)
                  ),
                ),
                FocusScope(
                  node: focusScopeNode1,
                  child: Builder(
                    builder: (BuildContext context) => TextField(key: textField1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField1));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(textField1));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Sibling Navigators', (WidgetTester tester) async {
    expect(tester.testTextInput.isVisible, isFalse);

    final Key textField0 = UniqueKey();
    final Key textField1 = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Navigator(
                    onGenerateRoute: (RouteSettings settings) {
                      return MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return TextField(key: textField0);
                        },
                        settings: settings,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Navigator(
                    onGenerateRoute: (RouteSettings settings) {
                      return MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return TextField(key: textField1);
                        },
                        settings: settings,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField1));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(textField1));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byKey(textField0));
    await tester.idle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.pumpWidget(Container());
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
