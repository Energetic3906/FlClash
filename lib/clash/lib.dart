import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';

import 'generated/clash_ffi.dart';
import 'interface.dart';

class ClashLib extends ClashHandlerInterface with AndroidClashInterface {
  static ClashLib? _instance;
  SendPort? sendPort;
  final receiverPort = ReceivePort();

  ClashLib._internal() {
    _initService();
  }

  _initService() async {
    await service?.destroy();
    IsolateNameServer.removePortNameMapping(mainIsolate);
    IsolateNameServer.registerPortWithName(receiverPort.sendPort, mainIsolate);
    receiverPort.listen((message) {
      if (message is SendPort) {
        sendPort = message;
      } else {
        handleResult(
          ActionResult.fromJson(json.decode(
            message,
          )),
        );
      }
    });
    await service?.init();
  }

  factory ClashLib() {
    _instance ??= ClashLib._internal();
    return _instance!;
  }

  @override
  Future<bool> nextHandleResult(result, completer) async {
    switch (result.method) {
      case ActionMethod.setFdMap:
      case ActionMethod.setProcessMap:
      case ActionMethod.setState:
      case ActionMethod.stopTun:
      case ActionMethod.updateDns:
        completer?.complete(result.data as bool);
        return true;
      case ActionMethod.getRunTime:
      case ActionMethod.startTun:
      case ActionMethod.getAndroidVpnOptions:
      case ActionMethod.getCurrentProfileName:
        completer?.complete(result.data as String);
        return true;
      default:
        return false;
    }
  }

  @override
  destroy() async {
    await service?.destroy();
    return true;
  }

  @override
  reStart() {
    _initService();
  }

  @override
  Future<bool> shutdown() async {
    await super.shutdown();
    destroy();
    return true;
  }

  @override
  sendMessage(String message) async {
    sendPort?.send(message);
  }

  @override
  Future<bool> setFdMap(int fd) {
    return invoke<bool>(
      method: ActionMethod.setFdMap,
      data: fd,
    );
  }

  @override
  Future<bool> setProcessMap(item) {
    return invoke<bool>(
      method: ActionMethod.setProcessMap,
      data: item,
    );
  }

  @override
  Future<bool> setState(CoreState state) {
    return invoke<bool>(
      method: ActionMethod.setState,
      data: json.encode(state),
    );
  }

  @override
  Future<DateTime?> startTun(int fd) async {
    final res = await invoke<String>(
      method: ActionMethod.startTun,
      data: fd,
    );

    if (res.isEmpty) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(res));
  }

  @override
  Future<bool> stopTun() {
    return invoke<bool>(
      method: ActionMethod.stopTun,
    );
  }

  @override
  Future<AndroidVpnOptions?> getAndroidVpnOptions() async {
    final res = await invoke<String>(
      method: ActionMethod.getAndroidVpnOptions,
    );
    if (res.isEmpty) {
      return null;
    }
    return AndroidVpnOptions.fromJson(json.decode(res));
  }

  @override
  Future<bool> updateDns(String dns) {
    return invoke<bool>(
      method: ActionMethod.updateDns,
      data: dns,
    );
  }

  @override
  Future<DateTime?> getRunTime() async {
    final runTimeString = await invoke<String>(
      method: ActionMethod.getRunTime,
    );
    if (runTimeString.isEmpty) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(runTimeString));
  }

  @override
  Future<String> getCurrentProfileName() {
    return invoke<String>(
      method: ActionMethod.getCurrentProfileName,
    );
  }
}

class ClashLibHandler {
  static ClashLibHandler? _instance;

  late final ClashFFI clashFFI;

  late final DynamicLibrary lib;

  ClashLibHandler._internal() {
    lib = DynamicLibrary.open("libclash.so");
    clashFFI = ClashFFI(lib);
    clashFFI.initNativeApiBridge(
      NativeApi.initializeApiDLData,
    );
  }

  factory ClashLibHandler() {
    _instance ??= ClashLibHandler._internal();
    return _instance!;
  }

  Future<String> invokeAction(String actionParams) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });

    final actionParamsChar = actionParams.toNativeUtf8().cast<Char>();
    clashFFI.invokeAction(
      actionParamsChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(actionParamsChar);
    return completer.future;
  }

  initMessage(ReceivePort receivePort) {
    clashFFI.initMessage(
      receivePort.sendPort.nativePort,
    );
  }
}

final clashLib = Platform.isAndroid ? ClashLib() : null;
