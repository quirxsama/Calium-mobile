import 'package:flutter_test/flutter_test.dart';
import 'package:calium_stream/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NotificationService handlePayload rejects empty or invalid gracefully', () {
    expect(() => NotificationService.handlePayload(null), returnsNormally);
    expect(() => NotificationService.handlePayload(''), returnsNormally);
  });
}
