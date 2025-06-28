import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CapacitorMapboxSearchPlugin)
public class CapacitorMapboxSearchPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorMapboxSearchPlugin"
    public let jsName = "CapacitorMapboxSearch"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openMap", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = CapacitorMapboxSearch()

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }
    
    @objc func openMap(_ call: CAPPluginCall) {
        guard let location = call.getObject("location"), 
              let lat = location["latitude"] as? Double, 
              let lon = location["longitude"] as? Double else {
            call.reject("Invalid or missing location parameters")
            return
        }


            
            
        DispatchQueue.main.async {
            let mapboxVC = CapacitorMapboxSearchViewController()
            mapboxVC.latitude = lat
            mapboxVC.longitude = lon
            let navigationController = UINavigationController(rootViewController: mapboxVC)
            
            if let viewController = self.bridge?.viewController {
                viewController.present(navigationController, animated: true, completion: nil)
                call.resolve()
            }
        }
    }
}

