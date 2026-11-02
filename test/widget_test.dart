import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jerman_camera_studio/main.dart';

void main() {
  testWidgets('splash opens the branded studio home', (tester) async {
    await tester.pumpWidget(const JermanCameraStudioApp());

    expect(find.text('CAMERA STUDIO'), findsOneWidget);
    expect(find.text('Capture  •  Edit  •  Create'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Amazing Moments'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Auto Edit'), findsOneWidget);
    expect(find.text('My Gallery'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom navigation opens gallery and projects', (tester) async {
    await tester.pumpWidget(const JermanCameraStudioApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    await tester.tap(find.text('Gallery').last);
    await tester.pumpAndSettle();
    expect(find.text('Your gallery is ready'), findsOneWidget);

    await tester.tap(find.text('Projects').last);
    await tester.pumpAndSettle();
    expect(find.text('Start a new project'), findsOneWidget);
  });

  testWidgets('settings and about pages open from the studio home', (
    tester,
  ) async {
    await tester.pumpWidget(const JermanCameraStudioApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Photo quality'), findsOneWidget);
    expect(find.text('Composition grid'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About app'));
    await tester.pumpAndSettle();
    expect(find.text('Innovating Today, Creating Tomorrow'), findsOneWidget);
    expect(find.text('Jerman Camera Studio 1.0.0'), findsOneWidget);
  });
}
