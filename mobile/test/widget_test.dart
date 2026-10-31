import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CjcSystemMonitorApp());
    await tester.pump();

    // Na inicialização, exibe o HUD global com as 2 máquinas
    expect(find.textContaining('CJC MONITOR'), findsWidgets);
    expect(find.textContaining('Meu-PC'), findsWidgets);
    expect(find.textContaining('Ubuntu'), findsWidgets);
  });
}
