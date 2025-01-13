import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

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
  final receiverPort = ReceivePort();
  Completer<SendPort> sendPortCompleter = Completer();

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
    Action? handleActionOnIsolate({
      required ClashLibHandler handler,
      required Action action,
    })  {
      switch (action.method) {
        case ActionMethod.message:
          return action.copyWith(
            data: true,
          );
        default:
          return action.copyWith(
            data: true,
          );
        // case ActionMethod.initClash:
        //   return action.copyWith(
        //     data: handler.init(
        //       action.data as String,
        //     ),
        //   );
        // case ActionMethod.getIsInit:
        //   return action.copyWith(
        //     data: handler.isInit,
        //   );
        // case ActionMethod.forceGc:
        //   handler.forceGc();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.shutdown:
        //   await handler.shutdown();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.validateConfig:
        //   final message = await handler.validateConfig(action.data as String);
        //   return action.copyWith(
        //     data: message,
        //   );
        // case ActionMethod.updateConfig:
        //   return action.copyWith(
        //     data: await handler.updateConfig(action.data as UpdateConfigParams),
        //   );
        // case ActionMethod.getProxies:
        //   return action.copyWith(
        //     data: handler.getProxies(),
        //   );
        // case ActionMethod.changeProxy:
        //   return action.copyWith(
        //     data: await handler.changeProxy(action.data as ChangeProxyParams),
        //   );
        // case ActionMethod.getTraffic:
        //   return action.copyWith(
        //     data: handler.getTraffic(action.data as bool),
        //   );
        // case ActionMethod.getTotalTraffic:
        //   return action.copyWith(
        //     data: handler.getTotalTraffic(action.data as bool),
        //   );
        // case ActionMethod.resetTraffic:
        //   handler.resetTraffic();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.asyncTestDelay:
        //   return action.copyWith(
        //     data: await handler.asyncTestDelay(action.data as String),
        //   );
        // case ActionMethod.getConnections:
        //   return action.copyWith(
        //     data: handler.getConnections(),
        //   );
        // case ActionMethod.closeConnections:
        //   return action.copyWith(
        //     data: await handler.closeConnections(),
        //   );
        // case ActionMethod.closeConnection:
        //   return action.copyWith(
        //     data: await handler.closeConnection(action.data as String),
        //   );
        // case ActionMethod.getExternalProviders:
        //   return action.copyWith(
        //     data: await handler.closeConnection(action.data as String),
        //   );
        // case ActionMethod.getExternalProvider:
        //   return action.copyWith(
        //     data: handler.getExternalProvider(action.data as String),
        //   );
        // case ActionMethod.updateGeoData:
        //   return action.copyWith(
        //     data: await handler.updateGeoData(action.data as UpdateGeoDataParams),
        //   );
        // case ActionMethod.updateExternalProvider:
        //   return action.copyWith(
        //     data: await handler.updateExternalProvider(action.data as String),
        //   );
        // case ActionMethod.sideLoadExternalProvider:
        //   return action.copyWith(
        //     data: await handler.updateExternalProvider(action.data as String),
        //   );
        // case ActionMethod.startLog:
        //   handler.startLog();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.stopLog:
        //   handler.startLog();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.startListener:
        //   return action.copyWith(
        //     data: await handler.startListener(),
        //   );
        // case ActionMethod.stopListener:
        //   return action.copyWith(
        //     data: await handler.stopListener(),
        //   );
        // case ActionMethod.getCountryCode:
        //   return action.copyWith(
        //     data: await handler.getCountryCode(action.data as String),
        //   );
        // case ActionMethod.getMemory:
        //   return action.copyWith(
        //     data: await handler.getMemory(),
        //   );
        // case ActionMethod.setFdMap:
        //   await handler.setFdMap(action.data as int);
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.setProcessMap:
        //   await handler.setProcessMap(action.data as ProcessMapItem);
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.setState:
        //   await handler.setState(action.data as CoreState);
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.getCurrentProfileName:
        //   return action.copyWith(
        //     data: handler.getCurrentProfileName(),
        //   );
        // case ActionMethod.startTun:
        //   return action.copyWith(
        //     data: handler.startTun(action.data as StartTunParams),
        //   );
        // case ActionMethod.stopTun:
        //   handler.stopTun();
        //   return action.copyWith(
        //     data: true,
        //   );
        // case ActionMethod.getRunTime:
        //   return action.copyWith(
        //     data: handler.getRunTime(),
        //   );
        // case ActionMethod.updateDns:
        //   return action.copyWith(
        //     data: handler.updateDns(action.data as String),
        //   );
        // case ActionMethod.getAndroidVpnOptions:
        //   return action.copyWith(
        //     data: handler.getAndroidVpnOptions(),
        //   );
      }
    }

    innerReceiverPort.listen((message) async {
      // final action = Action.fromJson(json.decode(message));
      // final nextAction =  handleActionOnIsolate(
      //   handler: clashLibHandler,
      //   action: action,
      // );
      // if (nextAction == null) {
      //   return;
      // }
      // sendPort.send(nextAction.toJson);
    });
    if (!globalState.isVpnService) {
      final messageReceiverPort = ReceivePort();
      clashLibHandler.initMessage(messageReceiverPort);
      messageReceiverPort.listen((message) {
        sendPort.send(
          Action(
            method: ActionMethod.message,
            data: message,
            id: "",
          ),
        );
      });
    }
    sendPort.send(innerReceiverPort.sendPort);
  }

  _initSendPort(SendPort sendPort) async {
    sendPortCompleter = Completer();
    sendPortCompleter.complete(sendPort);
  }

  _initClashLibHandler() async {
    receiverPort.listen((message) {
      if (message is SendPort) {
        _initSendPort(message);
      } else {
        handleAction(
          Action.fromJson(
            json.decode(message.trim()),
          ),
        );
      }
    });
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
    final sendPort = await sendPortCompleter.future;
    sendPort.send(message);
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

  Future<DateTime?> getRunTime() {
    return invoke<DateTime?>(
      method: ActionMethod.getRunTime,
    );
  }
}

class ClashLibHandler with ClashInterface {
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

  initMessage(ReceivePort receivePort) {
    clashFFI.initMessage(
      receivePort.sendPort.nativePort,
    );
  }

  @override
  bool init(String homeDir) {
    final homeDirChar = homeDir.toNativeUtf8().cast<Char>();
    final isInit = clashFFI.initClash(homeDirChar) == 1;
    malloc.free(homeDirChar);
    return isInit;
  }

  @override
  shutdown() async {
    clashFFI.shutdownClash();
    lib.close();
  }

  @override
  bool get isInit => clashFFI.getIsInit() == 1;

  @override
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

  @override
  Future<String> updateConfig(UpdateConfigParams updateConfigParams) {
    final completer = Completer<String>();
    final receiver = ReceivePort();
    receiver.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message);
        receiver.close();
      }
    });
    final params = json.encode(updateConfigParams);
    final paramsChar = params.toNativeUtf8().cast<Char>();
    clashFFI.updateConfig(
      paramsChar,
      receiver.sendPort.nativePort,
    );
    malloc.free(paramsChar);
    return completer.future;
  }

  @override
  String getProxies() {
    final proxiesRaw = clashFFI.getProxies();
    final proxiesRawString = proxiesRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(proxiesRaw);
    return proxiesRawString;
  }

  @override
  String getExternalProviders() {
    final externalProvidersRaw = clashFFI.getExternalProviders();
    final externalProvidersRawString =
        externalProvidersRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(externalProvidersRaw);
    return externalProvidersRawString;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  String getConnections() {
    final connectionsDataRaw = clashFFI.getConnections();
    final connectionsString = connectionsDataRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(connectionsDataRaw);
    return connectionsString;
  }

  @override
  closeConnection(String id) {
    final idChar = id.toNativeUtf8().cast<Char>();
    clashFFI.closeConnection(idChar);
    malloc.free(idChar);
    return true;
  }

  @override
  closeConnections() {
    clashFFI.closeConnections();
    return true;
  }

  @override
  startListener() async {
    clashFFI.startListener();
    return true;
  }

  @override
  stopListener() async {
    clashFFI.stopListener();
    return true;
  }

  @override
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

  @override
  String getTraffic(bool value) {
    final trafficRaw = clashFFI.getTraffic(value ? 1 : 0);
    final trafficString = trafficRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(trafficRaw);
    return trafficString;
  }

  @override
  String getTotalTraffic(bool value) {
    final trafficRaw = clashFFI.getTotalTraffic(value ? 1 : 0);
    clashFFI.freeCString(trafficRaw);
    return trafficRaw.cast<Utf8>().toDartString();
  }

  @override
  void resetTraffic() {
    clashFFI.resetTraffic();
  }

  @override
  void startLog() {
    clashFFI.startLog();
  }

  @override
  stopLog() {
    clashFFI.stopLog();
  }

  @override
  forceGc() {
    clashFFI.forceGc();
  }

  @override
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

  @override
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

  String getCurrentProfileName() {
    final currentProfileRaw = clashFFI.getCurrentProfileName();
    final currentProfile = currentProfileRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(currentProfileRaw);
    return currentProfile;
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

  DateTime? getRunTime() {
    final runTimeRaw = clashFFI.getRunTime();
    final runTimeString = runTimeRaw.cast<Utf8>().toDartString();
    clashFFI.freeCString(runTimeRaw);
    if (runTimeString.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(runTimeString));
  }
}

final clashLib = Platform.isAndroid ? ClashLib() : null;
