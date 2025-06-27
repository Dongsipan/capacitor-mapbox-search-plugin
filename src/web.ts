import { WebPlugin } from '@capacitor/core';

import type { CapacitorMapboxSearchPlugin } from './definitions';

export class CapacitorMapboxSearchWeb extends WebPlugin implements CapacitorMapboxSearchPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
