import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/clash/message.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/future.dart';
import 'package:fl_clash/common/other.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart' hide Action;

mixin ClashInterface {
  FutureOr<bool> init(String homeDir);

  FutureOr<void> shutdown();

  FutureOr<bool> get isInit;

  forceGc();

  FutureOr<String> validateConfig(String data);

  Future<String> asyncTestDelay(String proxyName);

  FutureOr<String> updateConfig(UpdateConfigParams updateConfigParams);

  FutureOr<String> getProxies();

  FutureOr<String> changeProxy(ChangeProxyParams changeProxyParams);

  Future<bool> startListener();

  Future<bool> stopListener();

  FutureOr<String> getExternalProviders();

  FutureOr<String>? getExternalProvider(String externalProviderName);

  Future<String> updateGeoData(UpdateGeoDataParams params);

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  });

  Future<String> updateExternalProvider(String providerName);

  FutureOr<String> getTraffic(bool value);

  FutureOr<String> getTotalTraffic(bool value);

  FutureOr<String> getCountryCode(String ip);

  FutureOr<String> getMemory();

  resetTraffic();

  startLog();

  stopLog();

  FutureOr<String> getConnections();

  FutureOr<bool> closeConnection(String id);

  FutureOr<bool> closeConnections();
}

abstract class ClashHandlerInterface with ClashInterface {
  Map<String, Completer> callbackCompleterMap = {};

  handleAction(Action action) {
    final completer = callbackCompleterMap[action.id];
    try {
      switch (action.method) {
        case ActionMethod.initClash:
        case ActionMethod.shutdown:
        case ActionMethod.getIsInit:
        case ActionMethod.startListener:
        case ActionMethod.resetTraffic:
        case ActionMethod.closeConnections:
        case ActionMethod.closeConnection:
        case ActionMethod.stopListener:
          completer?.complete(action.data as bool);
          return;
        case ActionMethod.changeProxy:
        case ActionMethod.getProxies:
        case ActionMethod.getTraffic:
        case ActionMethod.getTotalTraffic:
        case ActionMethod.asyncTestDelay:
        case ActionMethod.getConnections:
        case ActionMethod.getExternalProviders:
        case ActionMethod.getExternalProvider:
        case ActionMethod.validateConfig:
        case ActionMethod.updateConfig:
        case ActionMethod.updateGeoData:
        case ActionMethod.updateExternalProvider:
        case ActionMethod.sideLoadExternalProvider:
        case ActionMethod.getCountryCode:
        case ActionMethod.getMemory:
          completer?.complete(action.data as String);
          return;
        case ActionMethod.message:
          clashMessage.controller.add(action.data as String);
          completer?.complete(true);
          return;
        case ActionMethod.forceGc:
        case ActionMethod.startLog:
        case ActionMethod.stopLog:
        default:
          completer?.complete(true);
          return;
      }
    } catch (_) {
      debugPrint(action.id);
    }
  }

  sendMessage(String message);

  reStart();

  destroy();

  Future<T> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
    FutureOr<T> Function()? onTimeout,
  }) async {
    final id = "${method.name}#${other.id}";

    callbackCompleterMap[id] = Completer<T>();

    sendMessage(
      json.encode(
        Action(
          id: id,
          method: method,
          data: data,
        ),
      ),
    );

    return (callbackCompleterMap[id] as Completer<T>).safeFuture(
      timeout: timeout,
      onLast: () {
        callbackCompleterMap.remove(id);
      },
      onTimeout: onTimeout ??
          () {
            if (T == String) {
              return "" as T;
            }
            if (T == bool) {
              return false as T;
            }
            return null as T;
          },
      functionName: id,
    );
  }

  @override
  Future<bool> init(String homeDir) {
    return invoke<bool>(
      method: ActionMethod.initClash,
      data: homeDir,
    );
  }

  @override
  shutdown() async {
    await invoke<bool>(
      method: ActionMethod.shutdown,
    );
  }

  @override
  Future<bool> get isInit {
    return invoke<bool>(
      method: ActionMethod.getIsInit,
    );
  }

  @override
  forceGc() {
    invoke(
      method: ActionMethod.forceGc,
    );
  }

  @override
  FutureOr<String> validateConfig(String data) {
    return invoke<String>(
      method: ActionMethod.validateConfig,
      data: data,
    );
  }

  @override
  Future<String> updateConfig(UpdateConfigParams updateConfigParams) async {
    return await invoke<String>(
      method: ActionMethod.updateConfig,
      data: json.encode(updateConfigParams),
    );
  }

  @override
  Future<String> getProxies() {
    return invoke<String>(
      method: ActionMethod.getProxies,
    );
  }

  @override
  FutureOr<String> changeProxy(ChangeProxyParams changeProxyParams) {
    return invoke<String>(
      method: ActionMethod.changeProxy,
      data: json.encode(changeProxyParams),
    );
  }

  @override
  FutureOr<String> getExternalProviders() {
    return invoke<String>(
      method: ActionMethod.getExternalProviders,
    );
  }

  @override
  FutureOr<String> getExternalProvider(String externalProviderName) {
    return invoke<String>(
      method: ActionMethod.getExternalProvider,
      data: externalProviderName,
    );
  }

  @override
  Future<String> updateGeoData(UpdateGeoDataParams params) {
    return invoke<String>(
      method: ActionMethod.updateGeoData,
      data: json.encode(params),
    );
  }

  @override
  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) {
    return invoke<String>(
      method: ActionMethod.sideLoadExternalProvider,
      data: json.encode({
        "providerName": providerName,
        "data": data,
      }),
    );
  }

  @override
  Future<String> updateExternalProvider(String providerName) {
    return invoke<String>(
      method: ActionMethod.updateExternalProvider,
      data: providerName,
    );
  }

  @override
  FutureOr<String> getConnections() {
    return invoke<String>(
      method: ActionMethod.getConnections,
    );
  }

  @override
  Future<bool> closeConnections() {
    return invoke<bool>(
      method: ActionMethod.closeConnections,
    );
  }

  @override
  Future<bool> closeConnection(String id) {
    return invoke<bool>(
      method: ActionMethod.closeConnection,
      data: id,
    );
  }

  @override
  FutureOr<String> getTotalTraffic(bool value) {
    return invoke<String>(
      method: ActionMethod.getTotalTraffic,
      data: value,
    );
  }

  @override
  FutureOr<String> getTraffic(bool value) {
    return invoke<String>(
      method: ActionMethod.getTraffic,
      data: value,
    );
  }

  @override
  resetTraffic() {
    invoke(method: ActionMethod.resetTraffic);
  }

  @override
  startLog() {
    invoke(method: ActionMethod.startLog);
  }

  @override
  stopLog() {
    invoke<bool>(
      method: ActionMethod.stopLog,
    );
  }

  @override
  Future<bool> startListener() {
    return invoke<bool>(
      method: ActionMethod.startListener,
    );
  }

  @override
  stopListener() {
    return invoke<bool>(
      method: ActionMethod.stopListener,
    );
  }

  @override
  Future<String> asyncTestDelay(String proxyName) {
    final delayParams = {
      "proxy-name": proxyName,
      "timeout": httpTimeoutDuration.inMilliseconds,
    };
    return invoke<String>(
      method: ActionMethod.asyncTestDelay,
      data: json.encode(delayParams),
      timeout: Duration(
        milliseconds: 6000,
      ),
      onTimeout: () {
        return json.encode(
          Delay(
            name: proxyName,
            value: -1,
          ),
        );
      },
    );
  }

  @override
  FutureOr<String> getCountryCode(String ip) {
    return invoke<String>(
      method: ActionMethod.getCountryCode,
      data: ip,
    );
  }

  @override
  FutureOr<String> getMemory() {
    return invoke<String>(
      method: ActionMethod.getMemory,
    );
  }
}
