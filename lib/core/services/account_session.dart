import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AccountSession extends ChangeNotifier {
  AccountSession._();
  static final instance = AccountSession._();
  int generation = 0;
  String? userId;
  bool ready = false;
  final Map<String, Box> _boxes = {};
  static const names = ['history', 'history_deleted', 'favorites', 'favorites_deleted'];

  int invalidate() {
    generation++;
    ready = false;
    userId = null;
    _boxes.clear();
    notifyListeners();
    return generation;
  }

  Future<bool> activate(String? id, int expected) async {
    final boxes = <String, Box>{};
    final owner = id == null ? 'guest' : 'user_${Uri.encodeComponent(id)}';
    for (final name in names) {
      boxes[name] = await Hive.openBox('${name}_$owner');
      if (expected != generation) return false;
    }
    _boxes.addAll(boxes);
    userId = id;
    ready = true;
    notifyListeners();
    return true;
  }

  Box box(String name) {
    if (!ready) throw StateError('Account session changing');
    return _boxes[name]!;
  }

  bool isCurrent(int expected) => ready && generation == expected;
}
