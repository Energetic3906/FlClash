import 'package:fl_clash/common/proxy.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ProxyManager extends StatelessWidget {
  final Widget child;

  const ProxyManager({super.key, required this.child});

  _updateProxy(ProxyState proxyState) async {
    // 在 Android 上，如果不是 VPN 模式，强制关闭系统代理
    if (Platform.isAndroid) {
      final isStart = proxyState.isStart;
      final systemProxy = proxyState.systemProxy;
      if (!isStart || !systemProxy) {
        proxy?.stopProxy();
        return;
      }
    }
    
    final isStart = proxyState.isStart;
    final systemProxy = proxyState.systemProxy;
    final port = proxyState.port;
    if (isStart && systemProxy) {
      proxy?.startProxy(port, proxyState.bassDomain);
    } else {
      proxy?.stopProxy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector3<AppFlowingState, Config, ClashConfig, ProxyState>(
      selector: (_, appFlowingState, config, clashConfig) => ProxyState(
        isStart: appFlowingState.isStart,
        systemProxy: config.networkProps.systemProxy,
        port: clashConfig.mixedPort,
        bassDomain: config.networkProps.bypassDomain,
      ),
      builder: (_, state, child) {
        _updateProxy(state);
        return child!;
      },
      child: child,
    );
  }
}
