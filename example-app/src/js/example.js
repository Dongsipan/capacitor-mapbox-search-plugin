import { CapacitorMapboxSearch } from 'capacitor-mapbox-search-plugin';
import { Geolocation } from '@capacitor/geolocation';

window.testEcho = () => {
  const inputValue = document.getElementById('echoInput').value;
  CapacitorMapboxSearch.echo({ value: inputValue });
};

window.testMapboxShow = async () => {
  const coordinates = await Geolocation.getCurrentPosition({
    enableHighAccuracy: true,
    timeout: 10000,
  });
  const { coords } = coordinates;
  const { latitude, longitude } = coords;
  // {"timestamp":1751014970354.772,"coords":{"accuracy":14.066166429249179,"longitude":120.5435584258191,"altitude":20.621702101011575,"speed":-1,"latitude":31.297955857634189,"heading":-1,"altitudeAccuracy":8.6456638810968105}}
  CapacitorMapboxSearch.openMap({
    location: {
      latitude,
      longitude,
    },
  });
};
