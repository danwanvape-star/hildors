import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HildorsAppInfo") {
      FlutterMethodChannel(name: "hildors/app_info", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "version" else { result(FlutterMethodNotImplemented); return }
          let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
          let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
          result("\(version) (\(build))")
        }
    }
  }
}
