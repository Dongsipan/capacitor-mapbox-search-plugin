import { registerPlugin } from '@capacitor/core';

import type { CapacitorMapboxSearchPlugin } from './definitions';

const CapacitorMapboxSearch = registerPlugin<CapacitorMapboxSearchPlugin>('CapacitorMapboxSearch', {
  web: () => import('./web').then((m) => new m.CapacitorMapboxSearchWeb()),
});

export * from './definitions';
export { CapacitorMapboxSearch };
