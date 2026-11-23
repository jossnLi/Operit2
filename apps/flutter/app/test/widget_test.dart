import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operit2/ui/main/OperitApp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'unconfigured first launch shows onboarding without connecting Core',
    (tester) async {
      const channel = MethodChannel('operit/runtime');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'localRuntimeStorageDefaults') {
          return {'runtimeRoot': '/runtime', 'workspaceRoot': '/workspaces'};
        }
        throw StateError(
          'Unexpected runtime call before storage setup: ${call.method}',
        );
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(const OperitApp());
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('智能驱动的个人工作台 · 随行更高效'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(calls, ['localRuntimeStorageDefaults']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
