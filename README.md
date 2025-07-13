# capacitor-mapbox-search-plugin

This is a plugin for mapbox search.

## Install

```bash
npm install capacitor-mapbox-search-plugin
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`openMap(...)`](#openmap)
* [`openSearchBox()`](#opensearchbox)
* [`openAutocomplete()`](#openautocomplete)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => Promise<{ value: string; }>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

--------------------


### openMap(...)

```typescript
openMap(options: MapboxOpenOptions) => Promise<void>
```

| Param         | Type                                                            |
| ------------- | --------------------------------------------------------------- |
| **`options`** | <code><a href="#mapboxopenoptions">MapboxOpenOptions</a></code> |

--------------------


### openSearchBox()

```typescript
openSearchBox() => Promise<void>
```

--------------------


### openAutocomplete()

```typescript
openAutocomplete() => Promise<void>
```

--------------------


### Interfaces


#### MapboxOpenOptions

| Prop           | Type                                                  |
| -------------- | ----------------------------------------------------- |
| **`location`** | <code>{ latitude: number; longitude: number; }</code> |

</docgen-api>
