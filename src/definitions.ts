export interface CapacitorMapboxSearchPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
