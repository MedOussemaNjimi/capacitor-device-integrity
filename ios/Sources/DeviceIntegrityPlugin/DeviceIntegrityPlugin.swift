import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(DeviceIntegrityPlugin)
public class DeviceIntegrityPlugin: CAPPlugin, CAPBridgedPlugin {
  public let identifier = "DeviceIntegrityPlugin"
  public let jsName = "DeviceIntegrity"
  public let pluginMethods: [CAPPluginMethod] = [
    CAPPluginMethod(name: "check", returnType: CAPPluginReturnPromise)
  ]

  private let implementation = DeviceIntegrity()

  @objc func check(_ call: CAPPluginCall) {
    DispatchQueue.main.async {
      call.resolve(self.implementation.check())
    }
  }
}
