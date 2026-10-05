# capacitor-device-integrity

Root, jailbreak and runtime instrumentation detection.

On Android the root checks are delegated to [RootBeer](https://github.com/scottyab/rootbeer), completed by a scan
of the libraries loaded in the app process. On iOS the checks are implemented in the plugin, without any third-party
library.

These checks run on the device: they raise the cost of an attack but can be bypassed by an attacker
who controls the device. They do not replace a server-side attestation.

## Install

```bash
npm install github:MedOussemaNjimi/capacitor-device-integrity
npx cap sync
```

## iOS setup

The URL scheme check only works if the schemes are declared in every `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>sileo</string>
  <string>zbra</string>
  <string>filza</string>
  <string>undecimus</string>
</array>
```

## Usage

Run the check when the app starts, and again before sensitive operations:

```ts
import { Capacitor } from '@capacitor/core';
import { DeviceIntegrity } from 'capacitor-device-integrity';

export async function isDeviceCompromised(): Promise<boolean> {
  // The plugin has no web implementation
  if (!Capacitor.isNativePlatform()) {
    return false;
  }

  try {
    const report = await DeviceIntegrity.check();

    if (report.failedChecks.length > 0) {
      console.warn('Integrity checks that could not run:', report.failedChecks);
    }
    if (report.rooted || report.hooked) {
      console.warn('Device is compromised:', report.reasons);
      return true;
    }
    return false;
  } catch (error) {
    // Decide explicitly what a failure of the plugin means for your app: here the user is let through
    console.error('Integrity check failed', error);
    return false;
  }
}
```

A report looks like this on a rooted Android device:

```json
{
  "rooted": true,
  "hooked": false,
  "debugged": false,
  "reasons": ["root-su-binary", "root-magisk-binary"],
  "failedChecks": []
}
```

- `rooted` and `hooked` are the two signals to act on.
- `debugged` is true on any development build run from Android Studio or Xcode: do not block on it alone.
- On the iOS simulator the jailbreak checks are skipped, because the simulator exposes the file system of the Mac.
- On an Android emulator the root checks are usually positive: skip the check on virtual devices
  (`Device.getInfo()` from `@capacitor/device` returns `isVirtual`).

## API

<docgen-index>

* [`check()`](#check)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### check()

```typescript
check() => Promise<IntegrityReport>
```

Run all the integrity checks and return the detailed report.

**Returns:** <code>Promise&lt;<a href="#integrityreport">IntegrityReport</a>&gt;</code>

--------------------


### Interfaces


#### IntegrityReport

| Prop               | Type                  | Description                                                                                         |
| ------------------ | --------------------- | --------------------------------------------------------------------------------------------------- |
| **`rooted`**       | <code>boolean</code>  | The device is rooted (Android) or jailbroken (iOS).                                                 |
| **`hooked`**       | <code>boolean</code>  | An instrumentation or hooking framework (Frida, Xposed, Substrate...) is loaded in the app process. |
| **`debugged`**     | <code>boolean</code>  | A debugger is attached to the app process. Expected to be true on development builds.               |
| **`reasons`**      | <code>string[]</code> | Identifiers of the checks that detected something, for logging purposes.                            |
| **`failedChecks`** | <code>string[]</code> | Identifiers of the checks that could not run. A non-empty list means the report is incomplete.      |

</docgen-api>

## License

MIT. RootBeer, used on Android, is distributed under its own license.
