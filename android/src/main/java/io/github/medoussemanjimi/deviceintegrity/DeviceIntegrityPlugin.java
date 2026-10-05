package io.github.medoussemanjimi.deviceintegrity;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "DeviceIntegrity")
public class DeviceIntegrityPlugin extends Plugin {

    private final DeviceIntegrity implementation = new DeviceIntegrity();

    @PluginMethod
    public void check(PluginCall call) {
        DeviceIntegrity.Report report = implementation.check(getContext());

        JSObject result = new JSObject();
        result.put("rooted", report.rooted);
        result.put("hooked", report.hooked);
        result.put("debugged", report.debugged);
        result.put("reasons", new JSArray(report.reasons));
        result.put("failedChecks", new JSArray(report.failedChecks));
        call.resolve(result);
    }
}
