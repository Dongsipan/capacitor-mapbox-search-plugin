import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CapacitorMapboxSearchPlugin)
public class CapacitorMapboxSearchPlugin: CAPPlugin, CAPBridgedPlugin {
    // 用于存储搜索窗口的引用
    private var searchWindow: UIWindow?


    public let identifier = "CapacitorMapboxSearchPlugin"
    public let jsName = "CapacitorMapboxSearch"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openMap", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openSearchBox", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openAutocomplete", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = CapacitorMapboxSearch()
    
    override public func load() {
        super.load()
        
        // 初始化 Mapbox
        initializeMapbox()
    }
    
    private func initializeMapbox() {
        print("Initializing Mapbox in plugin...")
        
        // 检查访问令牌
        if let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            print("Mapbox access token found in plugin: \(String(accessToken.prefix(10)))...")
        } else {
            print("WARNING: No Mapbox access token found in Info.plist")
        }
    }

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
            let mapboxVC = CapacitorPlaceAutocompleteViewController() // CapacitorMapboxSearchViewController()
//            mapboxVC.latitude = lat
//            mapboxVC.longitude = lon
            // 设置关闭回调
            mapboxVC.onDismiss = { [weak self] in
                // 清理资源
                self?.searchWindow = nil
            }
            let navigationController = UINavigationController(rootViewController: mapboxVC)
            navigationController.modalPresentationStyle = .fullScreen
            
            // 获取当前窗口的根视图控制器并展示新页面
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(navigationController, animated: true, completion: nil)
            }
            call.resolve()
        }
    }

    @objc func openSearchBox(_ call: CAPPluginCall) {
        print("openSearchBox")
        DispatchQueue.main.async {
            let mapboxVC = CapacitorMapboxSearchViewController()
            // 设置关闭回调
            mapboxVC.onDismiss = { [weak self] in
                // 清理资源
                self?.searchWindow = nil
            }
            let navigationController = UINavigationController(rootViewController: mapboxVC)
            navigationController.modalPresentationStyle = .fullScreen
            
            // 获取当前窗口的根视图控制器并展示新页面
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(navigationController, animated: true, completion: nil)
            }
            call.resolve()
        }
    }

    @objc func openAutocomplete(_ call: CAPPluginCall) {
        print("openAutocomplete")
        DispatchQueue.main.async {
            let mapboxVC = CapacitorPlaceAutocompleteViewController()
            // 设置关闭回调
            mapboxVC.onDismiss = { [weak self] in
                // 清理资源
                self?.searchWindow = nil
            }
            let navigationController = UINavigationController(rootViewController: mapboxVC)
            navigationController.modalPresentationStyle = .fullScreen
            
            // 获取当前窗口的根视图控制器并展示新页面
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(navigationController, animated: true, completion: nil)
            }
            call.resolve()
        }
    }
}

