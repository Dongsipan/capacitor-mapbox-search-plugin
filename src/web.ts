import { WebPlugin } from '@capacitor/core';

import type { CapacitorMapboxSearchPlugin, MapboxOpenOptions } from './definitions';

export class CapacitorMapboxSearchWeb extends WebPlugin implements CapacitorMapboxSearchPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
  async openMap(options: MapboxOpenOptions): Promise<void> {
    console.log(options);
    console.log(`Can't open Mapbox map - Web is not supported.`);
  }
  async openSearchBox(): Promise<void> {
    console.log('openSearchBox');
    console.log(`Can't open Mapbox map - Web is not supported.`);
  }
  async openAutocomplete(): Promise<void> {
    console.log('openAutocomplete');
    console.log(`Can't open Mapbox map - Web is not supported.`);
  }
}
