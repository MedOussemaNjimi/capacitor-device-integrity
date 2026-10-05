package io.github.medoussemanjimi.deviceintegrity;

import android.content.Context;
import android.os.Debug;

import com.scottyab.rootbeer.RootBeer;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.Callable;

public class DeviceIntegrity {

    /** Library names of the instrumentation frameworks looked up in the process memory map. */
    private static final String[] HOOK_LIBRARIES = { "frida", "xposed", "substrate" };

    private static final String XPOSED_BRIDGE_CLASS = "de.robv.android.xposed.XposedBridge";

    public static class Report {

        public boolean rooted = false;
        public boolean hooked = false;
        public boolean debugged = false;
        public final List<String> reasons = new ArrayList<>();
        public final List<String> failedChecks = new ArrayList<>();
    }

    public Report check(Context context) {
        Report report = new Report();

        RootBeer rootBeer = new RootBeer(context);
        rootBeer.setLogging(false);

        report.rooted |= run(report, "root-management-apps", rootBeer::detectRootManagementApps);
        report.rooted |= run(report, "root-dangerous-apps", rootBeer::detectPotentiallyDangerousApps);
        report.rooted |= run(report, "root-cloaking-apps", rootBeer::detectRootCloakingApps);
        report.rooted |= run(report, "root-test-keys", rootBeer::detectTestKeys);
        report.rooted |= run(report, "root-su-binary", rootBeer::checkForSuBinary);
        report.rooted |= run(report, "root-su-exists", rootBeer::checkSuExists);
        report.rooted |= run(report, "root-magisk-binary", rootBeer::checkForMagiskBinary);
        report.rooted |= run(report, "root-dangerous-props", rootBeer::checkForDangerousProps);
        report.rooted |= run(report, "root-rw-paths", rootBeer::checkForRWPaths);
        report.rooted |= run(report, "root-native", rootBeer::checkForRootNative);

        report.hooked |= run(report, "hook-loaded-library", this::isHookLibraryLoaded);
        report.hooked |= run(report, "hook-xposed-bridge", this::isXposedBridgePresent);

        report.debugged = run(report, "debugger", () -> Debug.isDebuggerConnected() || Debug.waitingForDebugger());

        return report;
    }

    /**
     * Run one check. A check that throws is reported in failedChecks instead of aborting the whole report.
     */
    private boolean run(Report report, String id, Callable<Boolean> check) {
        try {
            boolean detected = check.call();
            if (detected) {
                report.reasons.add(id);
            }
            return detected;
        } catch (Throwable t) {
            report.failedChecks.add(id);
            return false;
        }
    }

    private boolean isHookLibraryLoaded() throws Exception {
        try (BufferedReader reader = new BufferedReader(new FileReader("/proc/self/maps"))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String lowerCaseLine = line.toLowerCase(Locale.ROOT);
                for (String library : HOOK_LIBRARIES) {
                    if (lowerCaseLine.contains(library)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean isXposedBridgePresent() {
        try {
            ClassLoader.getSystemClassLoader().loadClass(XPOSED_BRIDGE_CLASS);
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }
}
