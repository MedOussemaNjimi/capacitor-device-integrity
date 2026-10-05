export interface IntegrityReport {
  /**
   * The device is rooted (Android) or jailbroken (iOS).
   */
  rooted: boolean;
  /**
   * An instrumentation or hooking framework (Frida, Xposed, Substrate...) is loaded in the app process.
   */
  hooked: boolean;
  /**
   * A debugger is attached to the app process. Expected to be true on development builds.
   */
  debugged: boolean;
  /**
   * Identifiers of the checks that detected something, for logging purposes.
   */
  reasons: string[];
  /**
   * Identifiers of the checks that could not run. A non-empty list means the report is incomplete.
   */
  failedChecks: string[];
}

export interface DeviceIntegrityPlugin {
  /**
   * Run all the integrity checks and return the detailed report.
   */
  check(): Promise<IntegrityReport>;
}
