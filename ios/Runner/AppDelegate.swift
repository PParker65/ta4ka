import Flutter
import UIKit
import connectivity_plus
import sqlite3_flutter_libs
import url_launcher_ios
import video_player_avfoundation
import webview_flutter_wkwebview

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    if let registrar = registry.registrar(forPlugin: "ConnectivityPlusPlugin") {
      ConnectivityPlusPlugin.register(with: registrar)
    }
    registerObjCPlugin("FilePickerPlugin", registry: registry)
    registerObjCPlugin("GeolocatorPlugin", registry: registry)
    registerObjCPlugin("FLTImagePickerPlugin", registry: registry)
    if let registrar = registry.registrar(forPlugin: "Sqlite3FlutterLibsPlugin") {
      Sqlite3FlutterLibsPlugin.register(with: registrar)
    }
    if let registrar = registry.registrar(forPlugin: "URLLauncherPlugin") {
      URLLauncherPlugin.register(with: registrar)
    }
    if let registrar = registry.registrar(forPlugin: "VideoPlayerPlugin") {
      VideoPlayerPlugin.register(with: registrar)
    }
    if let registrar = registry.registrar(forPlugin: "WebViewFlutterPlugin") {
      WebViewFlutterPlugin.register(with: registrar)
    }
  }

  private func registerObjCPlugin(_ name: String, registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: name) else { return }
    guard let cls = NSClassFromString(name) as? FlutterPlugin.Type else { return }
    cls.register(with: registrar)
  }
}
