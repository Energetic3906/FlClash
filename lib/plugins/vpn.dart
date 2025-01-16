import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:fl_clash/clash/clash.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/services.dart';

class Vpn {
  static Vpn? _instance;
  late MethodChannel methodChannel;

  Vpn._internal() {
    methodChannel = const MethodChannel("vpn");
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "started":
          final fd = call.arguments as int;
          onStarted(fd);
          break;
        case "gc":
          clashCore.requestGc();
        case "dnsChanged":
          final dns = call.arguments as String;
          clashLib?.updateDns(dns);
        default:
          throw MissingPluginException();
      }
    });
  }

  factory Vpn() {
    _instance ??= Vpn._internal();
    return _instance!;
  }

  Future<bool?> startVpn() async {
    final options = clashLib?.getAndroidVpnOptions();
    return await methodChannel.invokeMethod<bool>("start", {
      'data': json.encode(options),
    });
  }

  Future<bool?> stopVpn() async {
    return await methodChannel.invokeMethod<bool>("stop");
  }

  Future<bool?> setProtect(int fd) async {
    return await methodChannel.invokeMethod<bool?>("setProtect", {'fd': fd});
  }

  Future<String?> resolverProcess(ProcessData process) async {
    return await methodChannel.invokeMethod<String>("resolverProcess", {
      "data": json.encode(process),
    });
  }

  Future<bool?> startForeground({
    required String title,
    required String content,
  }) async {
    return await methodChannel.invokeMethod<bool?>("startForeground", {
      'title': title,
      'content': content,
    });
  }

  onStarted(int fd) async {
    await clashLib?.startTun(
      fd,
    );
  }
}

final vpn = Platform.isAndroid ? Vpn() : null;
