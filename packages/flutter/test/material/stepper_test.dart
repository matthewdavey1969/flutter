// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Material3 has sentence case labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Material(
          child: Stepper(
            onStepTapped: (int i) {},
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Continue'), findsWidgets);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('Stepper tap callback test', (WidgetTester tester) async {
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            onStepTapped: (int i) {
              index = i;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Step 2'));
    expect(index, 1);
  });

  testWidgets('Stepper expansion test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('Step 2'),
                  content: SizedBox(
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 332.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              currentStep: 1,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('Step 2'),
                  content: SizedBox(
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, greaterThan(332.0));
    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 432.0);
  });

  testWidgets('Stepper horizontal size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              type: StepperType.horizontal,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(Stepper));
    expect(box.size.height, 600.0);
  });

  testWidgets('Stepper visibility test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: Text('A'),
              ),
              Step(
                title: Text('Step 2'),
                content: Text('B'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 1,
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: Text('A'),
              ),
              Step(
                title: Text('Step 2'),
                content: Text('B'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Stepper button test', (WidgetTester tester) async {
    bool continuePressed = false;
    bool cancelPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            onStepContinue: () {
              continuePressed = true;
            },
            onStepCancel: () {
              cancelPressed = true;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('CONTINUE'));
    await tester.tap(find.text('CANCEL'));

    expect(continuePressed, isTrue);
    expect(cancelPressed, isTrue);
  });

  testWidgets('Stepper disabled step test', (WidgetTester tester) async {
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            onStepTapped: (int i) {
              index = i;
            },
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                state: StepState.disabled,
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Step 2'));
    expect(index, 0);
  });

  testWidgets('Stepper scroll test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 3'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final ScrollableState scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, 0.0);

    await tester.tap(find.text('Step 3'));
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            currentStep: 2,
            steps: const <Step>[
              Step(
                title: Text('Step 1'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 2'),
                content: SizedBox(
                  width: 100.0,
                  height: 300.0,
                ),
              ),
              Step(
                title: Text('Step 3'),
                content: SizedBox(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(scrollableState.position.pixels, greaterThan(0.0));
  });

  testWidgets('Stepper index test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.complete,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('B'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Stepper custom controls test', (WidgetTester tester) async {
    bool continuePressed = false;
    void setContinue() {
      continuePressed = true;
    }

    bool canceledPressed = false;
    void setCanceled() {
      canceledPressed = true;
    }

    Widget builder(BuildContext context, ControlsDetails details) {
      return Container(
        margin: const EdgeInsets.only(top: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(height: 48.0),
          child: Row(
            children: <Widget>[
              TextButton(
                onPressed: details.onStepContinue,
                child: const Text('Let us continue!'),
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8.0),
                child: TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Cancel This!'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              controlsBuilder: builder,
              onStepCancel: setCanceled,
              onStepContinue: setContinue,
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.complete,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                Step(
                  title: Text('B'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 2 because stepper creates a set of controls for each step
    expect(find.text('Let us continue!'), findsNWidgets(2));
    expect(find.text('Cancel This!'), findsNWidgets(2));

    await tester.tap(find.text('Cancel This!').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let us continue!').first);
    await tester.pumpAndSettle();

    expect(canceledPressed, isTrue);
    expect(continuePressed, isTrue);
  });

testWidgets('Stepper custom indexed controls test', (WidgetTester tester) async {

    int currentStep = 0;
    void setContinue() {
      currentStep += 1;
    }

    void setCanceled() {
      currentStep -= 1;
    }

    Widget builder(BuildContext context, ControlsDetails details) {
      // For the purposes of testing, only render something for the active
      // step.
      if (!details.isActive) {
        return Container();
      }

      return Container(
        margin: const EdgeInsets.only(top: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(height: 48.0),
          child: Row(
            children: <Widget>[
              TextButton(
                onPressed: details.onStepContinue,
                child: Text('Continue to ${details.stepIndex + 1}'),
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8.0),
                child: TextButton(
                  onPressed: details.onStepCancel,
                  child: Text('Return to ${details.stepIndex - 1}'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Stepper(
                  currentStep: currentStep,
                  controlsBuilder: builder,
                  onStepCancel: () => setState(setCanceled),
                  onStepContinue: () => setState(setContinue),
                  steps: const <Step>[
                    Step(
                      title: Text('A'),
                      state: StepState.complete,
                      content: SizedBox(
                        width: 100.0,
                        height: 100.0,
                      ),
                    ),
                    Step(
                      title: Text('C'),
                      content: SizedBox(
                        width: 100.0,
                        height: 100.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // Never mind that there is no Step -1 or Step 2 -- actual build method
    // implementations would make those checks.
    expect(find.text('Return to -1'), findsNWidgets(1));
    expect(find.text('Continue to 1'), findsNWidgets(1));
    expect(find.text('Return to 0'), findsNWidgets(0));
    expect(find.text('Continue to 2'), findsNWidgets(0));

    await tester.tap(find.text('Continue to 1').first);
    await tester.pumpAndSettle();

    // Never mind that there is no Step -1 or Step 2 -- actual build method
    // implementations would make those checks.
    expect(find.text('Return to -1'), findsNWidgets(0));
    expect(find.text('Continue to 1'), findsNWidgets(0));
    expect(find.text('Return to 0'), findsNWidgets(1));
    expect(find.text('Continue to 2'), findsNWidgets(1));
  });

  testWidgets('Stepper error test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Material(
            child: Stepper(
              steps: const <Step>[
                Step(
                  title: Text('A'),
                  state: StepState.error,
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('Nested stepper error test', (WidgetTester tester) async {
    late FlutterErrorDetails errorDetails;
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Stepper(
              type: StepperType.horizontal,
              steps: <Step>[
                Step(
                  title: const Text('Step 2'),
                  content:  Stepper(
                    steps: const <Step>[
                      Step(
                        title: Text('Nested step 1'),
                        content: Text('A'),
                      ),
                      Step(
                        title: Text('Nested step 2'),
                        content: Text('A'),
                      ),
                    ],
                  ),
                ),
                const Step(
                  title: Text('Step 1'),
                  content: Text('A'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      FlutterError.onError = oldHandler;
    }

    expect(errorDetails.stack, isNotNull);
    // Check the ErrorDetails without the stack trace
    final String fullErrorMessage = errorDetails.toString();
    final List<String> lines = fullErrorMessage.split('\n');
    // The lines in the middle of the error message contain the stack trace
    // which will change depending on where the test is run.
    final String errorMessage = lines.takeWhile(
      (String line) => line != '',
    ).join('\n');
    expect(errorMessage.length, lessThan(fullErrorMessage.length));
    expect(errorMessage, startsWith(
      '══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞════════════════════════\n'
      'The following assertion was thrown building Stepper(',
    ));
    // The description string of the stepper looks slightly different depending
    // on the platform and is omitted here.
    expect(errorMessage, endsWith(
      '):\n'
      'Steppers must not be nested.\n'
      'The material specification advises that one should avoid\n'
      'embedding steppers within steppers.\n'
      'https://material.io/archive/guidelines/components/steppers.html#steppers-usage',
    ));
  });

  ///https://github.com/flutter/flutter/issues/16920
  testWidgets('Stepper icons size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            steps: const <Step>[
              Step(
                title: Text('A'),
                state: StepState.editing,
                content: SizedBox(width: 100.0, height: 100.0),
              ),
              Step(
                title: Text('B'),
                state: StepState.complete,
                content: SizedBox(width: 100.0, height: 100.0),
              ),
            ],
          ),
        ),
      ),
    );

    RenderBox renderObject = tester.renderObject(find.byIcon(Icons.edit));
    expect(renderObject.size, equals(const Size.square(18.0)));

    renderObject = tester.renderObject(find.byIcon(Icons.check));
    expect(renderObject.size, equals(const Size.square(18.0)));
  });

  testWidgets('Stepper physics scroll error test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(title: Text('Step 1'), content: Text('Text 1')),
                  Step(title: Text('Step 2'), content: Text('Text 2')),
                  Step(title: Text('Step 3'), content: Text('Text 3')),
                  Step(title: Text('Step 4'), content: Text('Text 4')),
                  Step(title: Text('Step 5'), content: Text('Text 5')),
                  Step(title: Text('Step 6'), content: Text('Text 6')),
                  Step(title: Text('Step 7'), content: Text('Text 7')),
                  Step(title: Text('Step 8'), content: Text('Text 8')),
                  Step(title: Text('Step 9'), content: Text('Text 9')),
                  Step(title: Text('Step 10'), content: Text('Text 10')),
                ],
              ),
              const Text('Text After Stepper'),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.byType(Stepper), const Offset(0.0, -100.0), 1000.0);
    await tester.pumpAndSettle();

    expect(find.text('Text After Stepper'), findsNothing);
  });

  testWidgets("Vertical Stepper can't be focused when disabled.", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            steps: const <Step>[
              Step(
                title: Text('Step 0'),
                state: StepState.disabled,
                content: Text('Text 0'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final FocusNode disabledNode = Focus.of(tester.element(find.text('Step 0')), scopeOk: true);
    disabledNode.requestFocus();
    await tester.pump();
    expect(disabledNode.hasPrimaryFocus, isFalse);
  });

  testWidgets("Horizontal Stepper can't be focused when disabled.", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('Step 0'),
                state: StepState.disabled,
                content: Text('Text 0'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final FocusNode disabledNode = Focus.of(tester.element(find.text('Step 0')), scopeOk: true);
    disabledNode.requestFocus();
    await tester.pump();
    expect(disabledNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('Stepper header title should not overflow', (WidgetTester tester) async {
    const String longText =
        'A long long long long long long long long long long long long text';

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(
                    title: Text(longText),
                    content: Text('Text content'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stepper header subtitle should not overflow', (WidgetTester tester) async {
    const String longText =
        'A long long long long long long long long long long long long text';

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              Stepper(
                steps: const <Step>[
                  Step(
                    title: Text('Regular title'),
                    subtitle: Text(longText),
                    content: Text('Text content'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stepper enabled button styles', (WidgetTester tester) async {
    Widget buildFrame(ThemeData theme) {
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            onStepCancel: () { },
            onStepContinue: () { },
            steps: const <Step>[
              Step(
                title: Text('step1'),
                content: SizedBox(width: 100, height: 100),
              ),
            ],
          ),
        ),
      );
    }

    Material buttonMaterial(String label) {
      return tester.widget<Material>(
        find.descendant(of: find.widgetWithText(TextButton, label), matching: find.byType(Material)),
      );
    }

    const OutlinedBorder buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2)));
    const Rect continueButtonRect = Rect.fromLTRB(24.0, 212.0, 168.0, 260.0);
    const Rect cancelButtonRect = Rect.fromLTRB(176.0, 212.0, 292.0, 260.0);

    await tester.pumpWidget(buildFrame(ThemeData.light()));

    expect(buttonMaterial('CONTINUE').color!.value, 0xff2196f3);
    expect(buttonMaterial('CONTINUE').textStyle!.color!.value, 0xffffffff);
    expect(buttonMaterial('CONTINUE').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CONTINUE')), continueButtonRect);

    expect(buttonMaterial('CANCEL').color!.value, 0);
    expect(buttonMaterial('CANCEL').textStyle!.color!.value, 0x8a000000);
    expect(buttonMaterial('CANCEL').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CANCEL')), cancelButtonRect);

    await tester.pumpWidget(buildFrame(ThemeData.dark()));
    await tester.pumpAndSettle(); // Complete the theme animation.

    expect(buttonMaterial('CONTINUE').color!.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle!.color!.value,  0xffffffff);
    expect(buttonMaterial('CONTINUE').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CONTINUE')), continueButtonRect);

    expect(buttonMaterial('CANCEL').color!.value, 0);
    expect(buttonMaterial('CANCEL').textStyle!.color!.value, 0xb3ffffff);
    expect(buttonMaterial('CANCEL').shape, buttonShape);
    expect(tester.getRect(find.widgetWithText(TextButton, 'CANCEL')), cancelButtonRect);
  });

  testWidgets('Stepper disabled button styles', (WidgetTester tester) async {
    Widget buildFrame(ThemeData theme) {
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Stepper(
            type: StepperType.horizontal,
            steps: const <Step>[
              Step(
                title: Text('step1'),
                content: SizedBox(width: 100, height: 100),
              ),
            ],
          ),
        ),
      );
    }

    Material buttonMaterial(String label) {
      return tester.widget<Material>(
        find.descendant(of: find.widgetWithText(TextButton, label), matching: find.byType(Material)),
      );
    }

    await tester.pumpWidget(buildFrame(ThemeData.light()));

    expect(buttonMaterial('CONTINUE').color!.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle!.color!.value, 0x61000000);

    expect(buttonMaterial('CANCEL').color!.value, 0);
    expect(buttonMaterial('CANCEL').textStyle!.color!.value, 0x61000000);

    await tester.pumpWidget(buildFrame(ThemeData.dark()));
    await tester.pumpAndSettle(); // Complete the theme animation.

    expect(buttonMaterial('CONTINUE').color!.value, 0);
    expect(buttonMaterial('CONTINUE').textStyle!.color!.value, 0x61ffffff);

    expect(buttonMaterial('CANCEL').color!.value, 0);
    expect(buttonMaterial('CANCEL').textStyle!.color!.value, 0x61ffffff);
  });

  testWidgets('Vertical and Horizontal Stepper physics test', (WidgetTester tester) async {
    const ScrollPhysics physics = NeverScrollableScrollPhysics();

    for(final StepperType type in StepperType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Stepper(
              physics: physics,
              type: type,
              steps: const <Step>[
                Step(
                  title: Text('Step 1'),
                  content: SizedBox(
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final ListView listView = tester.widget<ListView>(find.descendant(of: find.byType(Stepper), matching: find.byType(ListView)));
      expect(listView.physics, physics);
    }
  });

  testWidgets('Stepper horizontal size test', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/77732
    Widget buildFrame({ bool isActive = true, Brightness? brightness }) {
      return MaterialApp(
        theme: brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: Center(
            child: Stepper(
              type: StepperType.horizontal,
              steps: <Step>[
                Step(
                  title: const Text('step'),
                  content: const Text('content'),
                  isActive: isActive,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Color? circleFillColor() {
      final Finder container = find.widgetWithText(AnimatedContainer, '1');
      return (tester.widget<AnimatedContainer>(container).decoration as BoxDecoration?)?.color;
    }

    // Light theme
    final ColorScheme light = ThemeData.light().colorScheme;
    await tester.pumpWidget(buildFrame(brightness: Brightness.light));
    expect(circleFillColor(), light.primary);
    await tester.pumpWidget(buildFrame(isActive: false, brightness: Brightness.light));
    await tester.pumpAndSettle();
    expect(circleFillColor(), light.onSurface.withOpacity(0.38));

    // Dark theme
    final ColorScheme dark = ThemeData.dark().colorScheme;
    await tester.pumpWidget(buildFrame(brightness: Brightness.dark));
    await tester.pumpAndSettle();
    expect(circleFillColor(), dark.secondary);
    await tester.pumpWidget(buildFrame(isActive: false, brightness: Brightness.dark));
    await tester.pumpAndSettle();
    expect(circleFillColor(), dark.background);
  });

  testWidgets('Stepper custom elevation', (WidgetTester tester) async {
     const double elevation = 4.0;

     await tester.pumpWidget(
       MaterialApp(
         home: Material(
           child: SizedBox(
             width: 200,
             height: 75,
             child: Stepper(
               type: StepperType.horizontal,
               elevation: elevation,
               steps: const <Step>[
                 Step(
                   title: Text('Regular title'),
                   content: Text('Text content'),
                 ),
               ],
             ),
           ),
         ),
       ),
     );

     final Material material = tester.firstWidget<Material>(
       find.descendant(
         of: find.byType(Stepper),
         matching: find.byType(Material),
       ),
     );

     expect(material.elevation, elevation);
   });

   testWidgets('Stepper with default elevation', (WidgetTester tester) async {

     await tester.pumpWidget(
       MaterialApp(
         home: Material(
           child: SizedBox(
             width: 200,
             height: 75,
             child: Stepper(
               type: StepperType.horizontal,
               steps: const <Step>[
                 Step(
                   title: Text('Regular title'),
                   content: Text('Text content')
                 ),
               ],
             ),
           ),
         ),
       ),
     );

     final Material material = tester.firstWidget<Material>(
       find.descendant(
         of: find.byType(Stepper),
         matching: find.byType(Material),
       ),
     );

     expect(material.elevation, 2.0);
   });

  testWidgets('Stepper horizontal preserves state', (WidgetTester tester) async {
    const Color untappedColor = Colors.blue;
    const Color tappedColor = Colors.red;
    int index = 0;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            // Must break this out into its own widget purely to be able to call `setState()`
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Stepper(
                  onStepTapped: (int i) => setState(() => index = i),
                  currentStep: index,
                  type: StepperType.horizontal,
                  steps: const <Step>[
                    Step(
                      title: Text('Step 1'),
                      content: _TappableColorWidget(
                        key: Key('tappable-color'),
                        tappedColor: tappedColor,
                        untappedColor: untappedColor,
                      ),
                    ),
                    Step(
                      title: Text('Step 2'),
                      content: Text('Step 2 Content'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    final Widget widget = buildFrame();
    await tester.pumpWidget(widget);

    // Set up a getter to examine the MacGuffin's color
    Color getColor() => tester.widget<ColoredBox>(
      find.descendant(of: find.byKey(const Key('tappable-color')), matching: find.byType(ColoredBox)),
    ).color;

    // We are on step 1
    expect(find.text('Step 2 Content'), findsNothing);
    expect(getColor(), untappedColor);

    await tester.tap(find.byKey(const Key('tap-me')));
    await tester.pumpAndSettle();
    expect(getColor(), tappedColor);

    // Now flip to step 2
    await tester.tap(find.text('Step 2'));
    await tester.pumpAndSettle();

    // Confirm that we did in fact flip to step 2
    expect(find.text('Step 2 Content'), findsOneWidget);

    // Now go back to step 1
    await tester.tap(find.text('Step 1'));
    await tester.pumpAndSettle();

    // Confirm that we flipped back to step 1
    expect(find.text('Step 2 Content'), findsNothing);

    // The color should still be `tappedColor`
    expect(getColor(), tappedColor);
  });
       testWidgets('Stepper custom margin', (WidgetTester tester) async {

      const EdgeInsetsGeometry margin = EdgeInsetsDirectional.only(
        bottom: 20,
        top: 20,
      );

     await tester.pumpWidget(
       MaterialApp(
         home: Material(
           child: SizedBox(
             width: 200,
             height: 75,
             child: Stepper(
               margin: margin,
               steps: const <Step>[
                 Step(
                   title: Text('Regular title'),
                   content: Text('Text content')
                 ),
               ],
             ),
           ),
         ),
       ),
     );

     final Stepper material = tester.firstWidget<Stepper>(
       find.descendant(
         of: find.byType(Material),
         matching: find.byType(Stepper),
       ),
     );

     expect(material.margin, equals(margin));
   });

  testWidgets('Stepper with Alternative Label', (WidgetTester tester) async {
    int index = 0;
    late TextStyle bodyLargeStyle;
    late TextStyle bodyMediumStyle;
    late TextStyle bodySmallStyle;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            bodyLargeStyle = Theme.of(context).textTheme.bodyText1!;
            bodyMediumStyle = Theme.of(context).textTheme.bodyText2!;
            bodySmallStyle = Theme.of(context).textTheme.caption!;
            return Stepper(
              type: StepperType.horizontal,
              currentStep: index,
              onStepTapped: (int i) {
                setState(() {
                  index = i;
                });
              },
              steps: <Step>[
                Step(
                  title: const Text('Title 1'),
                  content: const Text('Content 1'),
                  label: Text('Label 1', style: Theme.of(context).textTheme.bodySmall),
                ),
                Step(
                  title: const Text('Title 2'),
                  content: const Text('Content 2'),
                  label: Text('Label 2', style: Theme.of(context).textTheme.bodyLarge),
                ),
                Step(
                  title: const Text('Title 3'),
                  content: const Text('Content 3'),
                  label: Text('Label 3', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            );
          }),
        ),
      ),
    );

    // Check Styles of Label Text Widgets before tapping steps
    final Text label1TextWidget =
        tester.widget<Text>(find.text('Label 1'));
    final Text label3TextWidget =
        tester.widget<Text>(find.text('Label 3'));

    expect(bodySmallStyle, label1TextWidget.style);
    expect(bodyMediumStyle, label3TextWidget.style);

    late Text selectedLabelTextWidget;
    late Text nextLabelTextWidget;

    // Tap to Step1 Label then, `index` become 0
    await tester.tap(find.text('Label 1'));
    expect(index, 0);

    // Check Styles of Selected Label Text Widgets and Another Label Text Widget
    selectedLabelTextWidget =
        tester.widget<Text>(find.text('Label ${index + 1}'));
    expect(bodySmallStyle, selectedLabelTextWidget.style);
    nextLabelTextWidget =
        tester.widget<Text>(find.text('Label ${index + 2}'));
    expect(bodyLargeStyle, nextLabelTextWidget.style);


    // Tap to Step2 Label then, `index` become 1
    await tester.tap(find.text('Label 2'));
    expect(index, 1);

    // Check Styles of Selected Label Text Widgets and Another Label Text Widget
    selectedLabelTextWidget =
        tester.widget<Text>(find.text('Label ${index + 1}'));
    expect(bodyLargeStyle, selectedLabelTextWidget.style);

    nextLabelTextWidget =
        tester.widget<Text>(find.text('Label ${index + 2}'));
    expect(bodyMediumStyle, nextLabelTextWidget.style);
  });

  testWidgets('Stepper Connector Style', (WidgetTester tester) async {
    const Color selectedColor = Colors.black;
    const Color disabledColor = Colors.white;
    int index = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Stepper(
                  type: StepperType.horizontal,
                  connectorColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) =>
                  states.contains(MaterialState.selected)
                    ? selectedColor
                    : disabledColor),
                  onStepTapped: (int i) => setState(() => index = i),
                  currentStep: index,
                  steps: <Step>[
                    Step(
                      isActive: index >= 0,
                      title: const Text('step1'),
                      content: const Text('step1 content'),
                    ),
                    Step(
                      isActive: index >= 1,
                      title: const Text('step2'),
                      content: const Text('step2 content'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      )
    );

    Color? circleColor(String circleText) => (tester.widget<AnimatedContainer>(
      find.widgetWithText(AnimatedContainer, circleText),
    ).decoration as BoxDecoration?)?.color;

    Color? lineColor(String keyStep) => tester.widget<Container>(find.byKey(Key(keyStep))).color;

    // Step 1
    // check if I'm in step 1
    expect(find.text('step1 content'), findsOneWidget);
    expect(find.text('step2 content'), findsNothing);

    expect(circleColor('1'), selectedColor);
    expect(circleColor('2'), disabledColor);
    // in two steps case there will be single line
    expect(lineColor('line0'), disabledColor);

    // now hitting step two
    await tester.tap(find.text('step2'));
    await tester.pumpAndSettle();

    // check if I'm in step 1
    expect(find.text('step1 content'), findsNothing);
    expect(find.text('step2 content'), findsOneWidget);

    expect(circleColor('1'), selectedColor);
    expect(circleColor('2'), selectedColor);

    expect(lineColor('line0'), selectedColor);
  });

}

class _TappableColorWidget extends StatefulWidget {
  const _TappableColorWidget({required this.tappedColor, required this.untappedColor, super.key,});

  final Color tappedColor;
  final Color untappedColor;

  @override
  State<StatefulWidget> createState() => _TappableColorWidgetState();
}

class _TappableColorWidgetState extends State<_TappableColorWidget> {

  Color? color;

  @override
  void initState() {
    super.initState();
    color = widget.untappedColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState((){
          color = widget.tappedColor;
        });
      },
      child: Container(
        key: const Key('tap-me'),
        height: 50,
        width: 50,
        color: color,
      ),
    );
  }
}
