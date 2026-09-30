// Entry point compiled with `dart compile js`: publishes [EngineRegistry] as
// `self.dhametEngine`, which tool/build.dart turns into the CommonJS export
// of the generated bundle.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dhamet_engine_bridge/engine_registry.dart';

void main() {
  final registry = EngineRegistry();
  final api = JSObject()
    ..['create'] = registry.create.toJS
    ..['load'] = registry.load.toJS
    ..['play'] = registry.play.toJS
    ..['resign'] = registry.resign.toJS
    ..['loseOnTime'] = registry.loseOnTime.toJS
    ..['snapshot'] = registry.snapshot.toJS
    ..['legalMoves'] = registry.legalMoves.toJS
    ..['close'] = registry.close.toJS
    ..['size'] = (() => registry.size).toJS;
  globalContext['dhametEngine'] = api;
}
