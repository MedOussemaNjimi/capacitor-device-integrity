import { registerPlugin } from '@capacitor/core';

import type { DeviceIntegrityPlugin } from './definitions';

const DeviceIntegrity = registerPlugin<DeviceIntegrityPlugin>('DeviceIntegrity');

export * from './definitions';
export { DeviceIntegrity };
