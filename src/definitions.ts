export interface CapacitorMapboxSearchPlugin {
  echo(options: { value: string }): Promise<{
    value: string;
  }>;
  openMap(options: MapboxOpenOptions): Promise<void>;
}

export interface MapboxOpenOptions {
  location: {
    latitude: number;
    longitude: number;
  };
}
