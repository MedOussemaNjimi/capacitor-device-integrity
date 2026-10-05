import Foundation
import UIKit
import MachO

@objc public class DeviceIntegrity: NSObject {

  /// Files that only exist on a jailbroken device, for rootful and rootless jailbreaks.
  private let jailbreakPaths = [
    "/Applications/Cydia.app",
    "/Applications/Sileo.app",
    "/Applications/Zebra.app",
    "/Applications/Filza.app",
    "/Applications/FakeCarrier.app",
    "/Applications/SBSettings.app",
    "/Applications/WinterBoard.app",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/Library/MobileSubstrate/DynamicLibraries",
    "/usr/lib/libsubstitute.dylib",
    "/usr/lib/libhooker.dylib",
    "/usr/lib/TweakInject",
    "/usr/sbin/sshd",
    "/usr/bin/sshd",
    "/usr/libexec/sftp-server",
    "/bin/bash",
    "/etc/apt",
    "/private/var/lib/apt",
    "/private/var/lib/cydia",
    "/private/var/stash",
    "/private/var/tmp/cydia.log",
    "/var/lib/dpkg/info",
    "/var/jb",
    "/var/binpack",
    "/cores/binpack"
  ]

  /// Store apps of the jailbreak ecosystem. Each scheme must be declared in LSApplicationQueriesSchemes.
  private let jailbreakUrlSchemes = ["sileo://", "zbra://", "filza://", "undecimus://"]

  /// Name fragments of the instrumentation and tweak injection libraries, in lower case.
  private let hookLibraries = [
    "frida",
    "cynject",
    "cycript",
    "substrate",
    "substitute",
    "libhooker",
    "ellekit",
    "tweakinject",
    "systemhook",
    "sslkillswitch"
  ]

  /**
   * Run all the checks. Must be called on the main thread: the URL scheme check uses UIApplication.
   */
  public func check() -> [String: Any] {
    var reasons: [String] = []
    var failedChecks: [String] = []
    var rooted = false
    var hooked = false
    var debugged = false

    #if !targetEnvironment(simulator)
    // The simulator exposes the file system of the Mac: these checks would always be positive
    if hasJailbreakFiles() {
      rooted = true
      reasons.append("jailbreak-files")
    }
    if canOpenJailbreakApps() {
      rooted = true
      reasons.append("jailbreak-url-schemes")
    }
    if canWriteOutsideSandbox() {
      rooted = true
      reasons.append("jailbreak-sandbox-write")
    }
    #endif

    if hasHookLibraryLoaded() {
      hooked = true
      reasons.append("hook-loaded-library")
    }
    if getenv("DYLD_INSERT_LIBRARIES") != nil {
      hooked = true
      reasons.append("hook-dyld-insert")
    }

    if let traced = isDebuggerAttached() {
      debugged = traced
      if traced {
        reasons.append("debugger")
      }
    } else {
      failedChecks.append("debugger")
    }

    return [
      "rooted": rooted,
      "hooked": hooked,
      "debugged": debugged,
      "reasons": reasons,
      "failedChecks": failedChecks
    ]
  }

  private func hasJailbreakFiles() -> Bool {
    // access() is used on top of FileManager because the latter is the usual target of the hiding tweaks
    return jailbreakPaths.contains { path in
      FileManager.default.fileExists(atPath: path) || access(path, F_OK) == 0
    }
  }

  private func canOpenJailbreakApps() -> Bool {
    return jailbreakUrlSchemes.contains { scheme in
      guard let url = URL(string: scheme) else { return false }
      return UIApplication.shared.canOpenURL(url)
    }
  }

  private func canWriteOutsideSandbox() -> Bool {
    let path = "/private/integrity-\(UUID().uuidString).txt"
    do {
      try "integrity".write(toFile: path, atomically: true, encoding: .utf8)
      try? FileManager.default.removeItem(atPath: path)
      return true
    } catch {
      return false
    }
  }

  private func hasHookLibraryLoaded() -> Bool {
    for index in 0..<_dyld_image_count() {
      guard let rawName = _dyld_get_image_name(index) else { continue }
      let name = String(cString: rawName).lowercased()
      if hookLibraries.contains(where: { name.contains($0) }) {
        return true
      }
    }
    return false
  }

  /// Returns nil when the kernel could not be queried.
  private func isDebuggerAttached() -> Bool? {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else {
      return nil
    }
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
