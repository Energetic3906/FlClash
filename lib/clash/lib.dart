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
import 'package:fl_clash/state.dart';

import 'generated/clash_ffi.dart';
import 'interface.dart';

class ClashLib extends ClashHandlerInterface {
  static ClashLib? _instance;
  Isolate? _isolate;
  SendPort? sendPort;
  final receiverPort = ReceivePort();

  ClashLib._internal() {
    _initClashLibHandler();
  }

  factory ClashLib() {
    _instance ??= ClashLib._internal();
    return _instance!;
  }

  _isolateEnter(SendPort sendPort) {
    final clashLibHandler = ClashLibHandler();
    final innerReceiverPort = ReceivePort();
    innerReceiverPort.listen((message) async {
      final res = await clashLibHandler.invokeAction(message);
      final action = Action.fromJson(json.decode(res));
      sendPort.send(json.encode(action));
    });
    if (!globalState.isVpnService) {
      final messageReceiverPort = ReceivePort();
      clashLibHandler.initMessage(messageReceiverPort);
      messageReceiverPort.listen((message) {
        sendPort.send(
          json.encode(
            ActionResult(
              method: ActionMethod.message,
              data: message,
              id: '',
            ),
          ),
        );
      });
    }
    sendPort.send(innerReceiverPort.sendPort);
  }

  _initClashLibHandler() async {
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

    IsolateNameServer.registerPortWithName(
      receiverPort.sendPort,
      mainIsolate,
    );
    _isolate = await Isolate.spawn(_isolateEnter, receiverPort.sendPort);
  }

  @override
  destroy() {
    _isolate?.kill();
  }

  @override
  reStart() {
    _isolate?.kill();
    _initClashLibHandler();
  }

  @override
  FutureOr<void> shutdown() {
    super.shutdown();
    destroy();
  }

  @override
  sendMessage(String message) async {
    sendPort?.send(message);
  }

  Future<bool> setFdMap(int fd) {
    return invoke<bool>(
      method: ActionMethod.setFdMap,
      data: fd,
    );
  }

  Future<bool> setProcessMap(ProcessMapItem item) {
    return invoke<bool>(
      method: ActionMethod.setProcessMap,
      data: item,
    );
  }

  Future<bool> setState(CoreState state) {
    return invoke<bool>(
      method: ActionMethod.setState,
      data: state,
    );
  }

  Future<String> getCurrentProfileName() {
    return invoke<String>(
      method: ActionMethod.getCurrentProfileName,
    );
  }

  Future<bool> startTun(StartTunParams params) {
    return invoke<bool>(
      method: ActionMethod.startTun,
      data: params,
    );
  }

  Future<bool> stopTun() {
    return invoke<bool>(
      method: ActionMethod.stopTun,
    );
  }

  Future<AndroidVpnOptions> getAndroidVpnOptions() {
    return invoke<AndroidVpnOptions>(
      method: ActionMethod.getAndroidVpnOptions,
    );
  }

  Future<bool> updateDns(String dns) {
    return invoke<bool>(
      method: ActionMethod.updateDns,
      data: dns,
    );
  }

  Future<DateTime?> getRunTime() async {
    final runTimeString = await invoke<String>(
      method: ActionMethod.getRunTime,
    );
    if (runTimeString.isEmpty) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(runTimeString));
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

  bool init(String homeDir) {
    final homeDirChar = homeDir.toNativeUtf8().cast<Char>();
    final isInit = clashFFI.initClash(homeDirChar) == 1;
    malloc.free(homeDirChar);
    return isInit;
  }

  shutdown() async {
    clashFFI.shutdownClash();
    lib.close();
  }

  bool get isInit => clashFFI.getIsInit() == 1;

  Future<String> validateConfig(String data) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final dataChar = data.toNativeUtf8().cast<Char>();
    clashFFI.validateConfig(
      dataChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(dataChar);
    return completer.future;
  }

  Future<String> updateConfig(String params) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final paramsChar = params.toNativeUtf8().cast<Char>();
    clashFFI.updateConfig(
      paramsChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(paramsChar);
    return completer.future;
  }

  String getProxies() {
    final proxiesRaw = clashFFI.getProxies();
    final proxiesRawString = proxiesRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(proxiesRaw);
    return proxiesRawString;
  }

  String getExternalProviders() {
    final externalProvidersRaw = clashFFI.getExternalProviders();
    final externalProvidersRawString =
        externalProvidersRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(externalProvidersRaw);
    return externalProvidersRawString;
  }

  String getExternalProvider(String externalProviderName) {
    final externalProviderNameChar =
        externalProviderName.toNativeUtf8().cast<Char>();
    final externalProviderRaw =
        clashFFI.getExternalProvider(externalProviderNameChar);
    malloc.free(externalProviderNameChar);
    final externalProviderRawString =
        externalProviderRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(externalProviderRaw);
    return externalProviderRawString;
  }

  Future<String> updateGeoData(UpdateGeoDataParams params) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final geoTypeChar = params.geoType.toNativeUtf8().cast<Char>();
    final geoNameChar = params.geoName.toNativeUtf8().cast<Char>();
    clashFFI.updateGeoData(
      geoTypeChar,
      geoNameChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(geoTypeChar);
    malloc.free(geoNameChar);
    return completer.future;
  }

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final providerNameChar = providerName.toNativeUtf8().cast<Char>();
    final dataChar = data.toNativeUtf8().cast<Char>();
    clashFFI.sideLoadExternalProvider(
      providerNameChar,
      dataChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(providerNameChar);
    malloc.free(dataChar);
    return completer.future;
  }

  Future<String> updateExternalProvider(String providerName) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final providerNameChar = providerName.toNativeUtf8().cast<Char>();
    clashFFI.updateExternalProvider(
      providerNameChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(providerNameChar);
    return completer.future;
  }

  Future<String> changeProxy(ChangeProxyParams changeProxyParams) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final params = json.encode(changeProxyParams);
    final paramsChar = params.toNativeUtf8().cast<Char>();
    clashFFI.changeProxy(
      paramsChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(paramsChar);
    return completer.future;
  }

  String getConnections() {
    final connectionsDataRaw = clashFFI.getConnections();
    final connectionsString = connectionsDataRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(connectionsDataRaw);
    return connectionsString;
  }

  closeConnection(String id) {
    final idChar = id.toNativeUtf8().cast<Char>();
    clashFFI.closeConnection(idChar);
    malloc.free(idChar);
    return true;
  }

  closeConnections() {
    clashFFI.closeConnections();
    return true;
  }

  startListener() async {
    clashFFI.startListener();
    return true;
  }

  stopListener() async {
    clashFFI.stopListener();
    return true;
  }

  Future<String> asyncTestDelay(String proxyName) {
    final delayParams = {
      "proxy-name": proxyName,
      "timeout": httpTimeoutDuration.inMilliseconds,
    };
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final delayParamsChar =
        json.encode(delayParams).toNativeUtf8().cast<Char>();
    clashFFI.asyncTestDelay(
      delayParamsChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(delayParamsChar);
    return completer.future;
  }

  String getTraffic(bool value) {
    final trafficRaw = clashFFI.getTraffic(value ? 1 : 0);
    final trafficString = trafficRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(trafficRaw);
    return trafficString;
  }

  String getTotalTraffic(bool value) {
    final trafficRaw = clashFFI.getTotalTraffic(value ? 1 : 0);
    clashFFI.freeCString(trafficRaw);
    return trafficRaw.cast<Utf8>().toDartString();
  }

  void resetTraffic() {
    clashFFI.resetTraffic();
  }

  void startLog() {
    clashFFI.startLog();
  }

  stopLog() {
    clashFFI.stopLog();
  }

  forceGc() {
    clashFFI.forceGc();
  }

  FutureOr<String> getCountryCode(String ip) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final ipChar = ip.toNativeUtf8().cast<Char>();
    clashFFI.getCountryCode(
      ipChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(ipChar);
    return completer.future;
  }

  FutureOr<String> getMemory() {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    clashFFI.getMemory(receiver.sendPort.nativePort);
    return completer.future;
  }

  /// Android
  startTun(StartTunParams params) {
    if (!Platform.isAndroid) return;
    clashFFI.startTUN(params.fd, params.port);
  }

  stopTun() {
    clashFFI.stopTun();
  }

  updateDns(String dns) {
    final dnsChar = dns.toNativeUtf8().cast<Char>();
    clashFFI.updateDns(dnsChar);
    malloc.free(dnsChar);
  }

  setProcessMap(ProcessMapItem processMapItem) {
    final processMapItemChar =
        json.encode(processMapItem).toNativeUtf8().cast<Char>();
    clashFFI.setProcessMap(processMapItemChar);
    malloc.free(processMapItemChar);
  }

  setState(CoreState state) {
    final stateChar = json.encode(state).toNativeUtf8().cast<Char>();
    clashFFI.setState(stateChar);
    malloc.free(stateChar);
  }

  AndroidVpnOptions getAndroidVpnOptions() {
    final vpnOptionsRaw = clashFFI.getAndroidVpnOptions();
    final vpnOptions = json.decode(vpnOptionsRaw.cast<Utf8>().toDartString());
    clashFFI.freeCString(vpnOptionsRaw);
    return AndroidVpnOptions.fromJson(vpnOptions);
  }

  setFdMap(int fd) {
    clashFFI.setFdMap(fd);
  }

  String? getRunTime() {
    final runTimeRaw = clashFFI.getRunTime();
    final runTimeString = runTimeRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(runTimeRaw);
    return runTimeString;
  }
}

final clashLib = Platform.isAndroid ? ClashLib() : null;
