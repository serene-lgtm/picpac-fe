import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/me/presentation/widgets/me_common_widgets.dart';

void main() {
  testWidgets(
    'logout button renders without shadow in idle, pressed and loading states',
    (tester) async {
      Future<void> render({bool loading = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MeConfirmDialog(
                assetPath: 'assets/common/leave.png',
                message: '确认要退出登录吗？',
                confirmLabel: '退出登录',
                danger: true,
                loading: loading,
                onConfirm: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      void check() {
        final button = find.byType(FilledButton);
        expect(tester.getSize(button), const Size(158, 50));
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        );
        expect(material.elevation, 0);
        expect(material.shadowColor, Colors.transparent);
        final style = tester.widget<FilledButton>(button).style!;
        for (final states in [
          <WidgetState>{},
          {WidgetState.pressed},
          {WidgetState.hovered},
          {WidgetState.focused},
          {WidgetState.disabled},
        ]) {
          expect(style.elevation!.resolve(states), 0);
          expect(style.shadowColor!.resolve(states), Colors.transparent);
        }
      }

      await render();
      check();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FilledButton)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      check();
      await gesture.up();
      // Loading has a looping progress indicator, so use a bounded pump.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeConfirmDialog(
              assetPath: 'assets/common/leave.png',
              message: '确认要退出登录吗？',
              confirmLabel: '退出登录',
              danger: true,
              loading: true,
              onConfirm: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      check();
    },
  );
}
