import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CjcSystemMonitorApp());
    await tester.pump();

    // Na inicialização sem stats, exibe o estado de desconectado / descoberta
    expect(find.textContaining('IPv4'), findsWidgets);
  });
}
