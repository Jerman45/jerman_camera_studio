import 'package:flutter_test/flutter_test.dart';
import 'package:jerman_camera_studio/main.dart';

void main() {
  testWidgets('camera studio shows branded photo and video controls', (
    tester,
  ) async {
    await tester.pumpWidget(const JermanCameraStudioApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('JERMAN'), findsOneWidget);
    expect(find.text('CAMERA STUDIO'), findsOneWidget);
    expect(find.text('PHOTO'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
  });
}
