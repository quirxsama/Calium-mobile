import 'package:calium_stream/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('update is offered only for a newer positive version code', () {
    expect(
      AppUpdateService.isUpdateAvailable(remoteCode: 114, currentCode: 4),
      isTrue,
    );
    expect(
      AppUpdateService.isUpdateAvailable(remoteCode: 4, currentCode: 4),
      isFalse,
    );
    expect(
      AppUpdateService.isUpdateAvailable(remoteCode: 3, currentCode: 4),
      isFalse,
    );
    expect(
      AppUpdateService.isUpdateAvailable(remoteCode: 0, currentCode: 4),
      isFalse,
    );
  });
}
