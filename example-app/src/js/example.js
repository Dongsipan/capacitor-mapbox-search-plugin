import { CapacitorMapboxSearch } from 'capacitor-mapbox-search-plugin';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    CapacitorMapboxSearch.echo({ value: inputValue })
}
