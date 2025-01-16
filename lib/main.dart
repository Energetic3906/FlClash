import 'dart:async';
import 'dart:io';

import 'package:fl_clash/clash/clash.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/plugins/tile.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'application.dart';
import 'common/common.dart';
import 'l10n/l10n.dart';
import 'models/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  globalState.packageInfo = await PackageInfo.fromPlatform();
  final version = await system.version;
  final config = await preferences.getConfig() ?? Config();
  await AppLocalizations.load(
    other.getLocaleForString(config.appSetting.locale) ??
        WidgetsBinding.instance.platformDispatcher.locale,
  );
  final clashConfig = await preferences.getClashConfig() ?? ClashConfig();
  await android?.init();
  await window?.init(config.windowProps, version);
  final appState = AppState(
    mode: clashConfig.mode,
    version: version,
    selectedMap: config.currentSelectedMap,
  );
  final appFlowingState = AppFlowingState();
  appState.navigationItems = navigation.getItems(
    openLogs: config.appSetting.openLogs,
    hasProxies: false,
  );
  tray.update(
    appState: appState,
    appFlowingState: appFlowingState,
    config: config,
    clashConfig: clashConfig,
  );
  HttpOverrides.global = FlClashHttpOverrides();
  runAppWithPreferences(
    const Application(),
    appState: appState,
    appFlowingState: appFlowingState,
    config: config,
    clashConfig: clashConfig,
  );
}

@pragma('vm:entry-point')
Future<void> vpnService() async {
  WidgetsFlutterBinding.ensureInitialized();
  globalState.isVpnService = true;
  globalState.packageInfo = await PackageInfo.fromPlatform();
  final version = await system.version;
  final config = await preferences.getConfig() ?? Config();
  final clashConfig = await preferences.getClashConfig() ?? ClashConfig();
  await AppLocalizations.load(
    other.getLocaleForString(config.appSetting.locale) ??
        WidgetsBinding.instance.platformDispatcher.locale,
  );

  final appState = AppState(
    mode: clashConfig.mode,
    selectedMap: config.currentSelectedMap,
    version: version,
  );

  await globalState.init(
    appState: appState,
    config: config,
    clashConfig: clashConfig,
  );

  await app?.tip(appLocalizations.startVpn);

  globalState
      .updateClashConfig(
    appState: appState,
    clashConfig: clashConfig,
    config: config,
    isPatch: false,
  )
      .then(
    (_) async {
      await globalState.handleStart();
      tile?.addListener(
        TileListenerWithVpn(
          onStop: () async {
            await app?.tip(appLocalizations.stopVpn);
            await globalState.handleStop();
            clashCore.shutdown();
            exit(0);
          },
        ),
      );
      globalState.updateTraffic(config: config);
      globalState.updateFunctionLists = [
        () {
          globalState.updateTraffic(config: config);
        }
      ];
    },
  );
}

@immutable
class TileListenerWithVpn with TileListener {
  final Function() _onStop;

  const TileListenerWithVpn({
    required Function() onStop,
  }) : _onStop = onStop;

  @override
  void onStop() {
    _onStop();
  }
}
