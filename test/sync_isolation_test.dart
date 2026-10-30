import 'dart:async';
import 'dart:io';

import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';
import 'package:calium_stream/core/services/sync_service.dart';
import 'package:calium_stream/features/auth/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SyncRemote extends Fake implements SyncRemoteDataSource {
  final uploaded = Completer<void>();
  final release = Completer<void>();
  final syncStarted = Completer<void>();
  bool fail = false;
  @override
  Future<UserModel?> refreshCurrentUser() async {
    if (!syncStarted.isCompleted) syncStarted.complete();
    return null;
  }
  @override
  Future<void> uploadHistory(List<Map<String, dynamic>> items) async {
    uploaded.complete();
    await release.future;
    if (fail) throw StateError('offline');
  }
  @override
  Future<List<Map<String, dynamic>>> getRemoteHistory() async => [];
  @override
  Future<void> uploadFavorites(List<Map<String, dynamic>> items) async {}
  @override
  Future<List<Map<String, dynamic>>> getRemoteFavorites() async => [];
  @override
  Future<List<Map<String, dynamic>>> getNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SyncRemote remote;
  late SyncService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('calium-sync-test');
    Hive.init(directory.path);
    await AccountSession.instance.activate(
      'tester',
      AccountSession.instance.generation,
    );
    FlutterSecureStorage.setMockInitialValues({StorageKeys.authToken: 'test-token'});
    remote = SyncRemote();
    service = SyncService(remoteDataSource: remote, secureStorage: const FlutterSecureStorage());
    await AccountSession.instance.box('history').put('anime', {
      'animeId': 'anime', 'episodeId': 'old', 'episodeNumber': 1,
      'updatedAt': 1, 'revision': 1, 'dirty': true,
    });
  });
  tearDown(() async {
    service.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('upload acknowledgement preserves newer episode and dirty revision', () async {
    final syncing = service.syncNow();
    await remote.uploaded.future;
    await AccountSession.instance.box('history').put('anime', {
      'animeId': 'anime', 'episodeId': 'new', 'episodeNumber': 2,
      'updatedAt': 2, 'revision': 2, 'dirty': true,
    });
    remote.release.complete();
    await syncing;
    expect(AccountSession.instance.box('history').get('anime')['episodeId'], 'new');
    expect(AccountSession.instance.box('history').get('anime')['dirty'], true);
  });
  test('failed upload leaves dirty history retryable', () async {
    remote.fail = true;
    remote.release.complete();
    await service.syncNow();
    expect(AccountSession.instance.box('history').get('anime')['dirty'], true);
  });
  test('restoring the stored session starts a sync without waiting for the periodic tick', () async {
    // Cold start: the app boots on the guest session.
    AccountSession.instance.invalidate();
    await AccountSession.instance.activate(
      null,
      AccountSession.instance.generation,
    );
    final restoredRemote = SyncRemote();
    final restoredService = SyncService(
      remoteDataSource: restoredRemote,
      secureStorage: const FlutterSecureStorage(),
    );
    addTearDown(restoredService.dispose);
    restoredService.start();

    // The stored session finishes restoring a moment later.
    await AccountSession.instance.activate(
      'restored',
      AccountSession.instance.generation,
    );

    await restoredRemote.syncStarted.future.timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () => fail(
        'session restore did not trigger a sync; the app waits for the '
        'periodic tick instead',
      ),
    );
  });
}
