//
//  CapacitorPlaceAutocompleteResultViewController.swift
//  CapacitorMapboxSearchPlugin
//
//  Created by 董思盼 on 2025/7/2.
//

import MapboxMaps
import MapboxSearch
import MapKit
import UIKit

final class CapacitorPlaceAutocompleteResultViewController: UIViewController {
    private var tableView: UITableView!
    private var mapView: MapView!
    private var annotationsManager: PointAnnotationManager!

    private var result: PlaceAutocomplete.Result!
    private var resultComponents: [(name: String, value: String)] = []

    static func instantiate(with result: PlaceAutocomplete.Result) -> CapacitorPlaceAutocompleteResultViewController {
        let viewController = CapacitorPlaceAutocompleteResultViewController()
        viewController.result = result
        viewController.resultComponents = result.toComponents()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 检查 Mapbox 访问令牌
        if let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            print("Mapbox access token found for result view: \(String(accessToken.prefix(10)))...")
        } else {
            print("WARNING: No Mapbox access token found in Info.plist for result view")
        }
        
        createUIElements()
        prepare()
        
        // 添加滑动手势来返回
        setupSwipeToGoBack()
        
        // 立即设置白色导航栏
        setupWhiteNavigationBar()
    }
    // 关闭窗口的回调
    var onDismiss: (() -> Void)?
    
    
    @objc private func closeWindow() {
        // 调用回调
        onDismiss?()
        
        // 返回到上一个页面
        navigationController?.popViewController(animated: true)
    }
    
    func showAnnotations(results: [PlaceAutocomplete.Result], cameraShouldFollow: Bool = true) {
        annotationsManager.annotations = results.compactMap {
            PointAnnotation.pointAnnotation($0)
        }

        if cameraShouldFollow {
            cameraToAnnotations(annotationsManager.annotations)
        }
    }

    func cameraToAnnotations(_ annotations: [PointAnnotation]) {
        if annotations.count == 1, let annotation = annotations.first {
            mapView.camera.fly(
                to: .init(center: annotation.point.coordinates, zoom: 15),
                duration: 0.25,
                completion: nil
            )
        } else {
            do {
                let cameraState = mapView.mapboxMap.cameraState
                let coordinatesCamera = try mapView.mapboxMap.camera(
                    for: annotations.map(\.point.coordinates),
                    camera: CameraOptions(cameraState: cameraState),
                    coordinatesPadding: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24),
                    maxZoom: nil,
                    offset: nil
                )

                mapView.camera.fly(to: coordinatesCamera, duration: 0.25, completion: nil)
            } catch {
                _Logger.searchSDK.error(error.localizedDescription)
            }
        }
    }
}

// MARK: - TableView data source and delegate

extension CapacitorPlaceAutocompleteResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        result == nil ? .zero : resultComponents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "result-cell"

        let tableViewCell: UITableViewCell = if let cachedTableViewCell = tableView
            .dequeueReusableCell(withIdentifier: cellIdentifier)
        {
            cachedTableViewCell
        } else {
            UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }

        let component = resultComponents[indexPath.row]

        tableViewCell.textLabel?.text = component.name
        tableViewCell.detailTextLabel?.text = component.value
        tableViewCell.detailTextLabel?.textColor = UIColor.darkGray

        return tableViewCell
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let result = result, result.coordinate != nil else { return }
        showSuggestionRegion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 确保导航栏是白色
        setupWhiteNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 确保导航栏是白色
        setupWhiteNavigationBar()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

// MARK: - Private

extension CapacitorPlaceAutocompleteResultViewController {
    private func createUIElements() {
        // 创建地图视图 - 尝试不同的初始化方法
        print("Creating MapView...")
        
        // 方法1: 使用 frame 初始化
        mapView = MapView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        print("MapView created successfully with frame")
        
        // 初始化注释管理器
        annotationsManager = mapView.makeClusterPointAnnotationManager()
        print("Annotations manager created successfully")
        
        // 创建表格视图
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        
        // 设置约束 - 地图在上半部分，表格在下半部分
        NSLayoutConstraint.activate([
            // 地图视图约束
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    /// Initial set-up
    private func prepare() {
        // 根据本地化设置标题
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                title = "地点详情"
            } else {
                title = "Place Details"
            }
        } else {
                title = "Place Details"
        }
        
        // 添加返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(closeWindow)
        )
        
        // 设置白色导航栏
        setupWhiteNavigationBar()

        updateScreenData()
    }

    private func updateScreenData() {
        guard let result = result, let _ = result.coordinate else { return }
        showAnnotations(results: [result])
        showSuggestionRegion()

        tableView.reloadData()
    }

    private func showSuggestionRegion() {
        guard let coordinate = result.coordinate else { return }

        let cameraOptions = CameraOptions(
            center: coordinate,
            zoom: 10.5
        )

        mapView.camera.ease(to: cameraOptions, duration: 0.4)
    }
    
    private func setupSwipeToGoBack() {
        // 添加从右向左滑动手势来返回
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeWindow))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func setupWhiteNavigationBar() {
        guard let navigationController = navigationController else { return }
        
        // 设置白色导航栏
        navigationController.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController.navigationBar.shadowImage = nil
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .white
        navigationController.navigationBar.tintColor = .systemBlue
        navigationController.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]
        
        // iOS 13+ 兼容性设置
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.black
            ]
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
        }
    }
}

extension PlaceAutocomplete.Result {
    static let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = [.naturalScale]
        formatter.numberFormatter.roundingMode = .halfUp
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()

    func toComponents() -> [(name: String, value: String)] {
        // 根据本地化设置标签文本
        let nameLabel: String
        let typeLabel: String
        let addressLabel: String
        let distanceLabel: String
        let timeLabel: String
        let phoneLabel: String
        let reviewsLabel: String
        let ratingLabel: String
        let categoriesLabel: String
        let idLabel: String
        
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                nameLabel = "名称"
                typeLabel = "类型"
                addressLabel = "地址"
                distanceLabel = "距离"
                timeLabel = "预计时间"
                phoneLabel = "电话"
                reviewsLabel = "评论数"
                ratingLabel = "评分"
                categoriesLabel = "分类"
                idLabel = "Mapbox ID"
            } else {
                nameLabel = "Name"
                typeLabel = "Type"
                addressLabel = "Address"
                distanceLabel = "Distance"
                timeLabel = "Estimated time"
                phoneLabel = "Phone"
                reviewsLabel = "Reviews Count"
                ratingLabel = "Rating"
                categoriesLabel = "Categories"
                idLabel = "Mapbox ID"
            }
        } else {
            nameLabel = "Name"
            typeLabel = "Type"
            addressLabel = "Address"
            distanceLabel = "Distance"
            timeLabel = "Estimated time"
            phoneLabel = "Phone"
            reviewsLabel = "Reviews Count"
            ratingLabel = "Rating"
            categoriesLabel = "Categories"
            idLabel = "Mapbox ID"
        }
        
        var components = [
            (name: nameLabel, value: name),
            (name: typeLabel, value: "\(type == .POI ? "POI" : "Address")"),
        ]

        if let address, let formattedAddress = address.formattedAddress(style: .short) {
            components.append(
                (name: addressLabel, value: formattedAddress)
            )
        }

        if let distance {
            components.append(
                (name: distanceLabel, value: PlaceAutocomplete.Result.distanceFormatter.string(fromDistance: distance))
            )
        }

        if let estimatedTime {
            components.append(
                (
                    name: timeLabel,
                    value: PlaceAutocomplete.Result.measurementFormatter.string(from: estimatedTime)
                )
            )
        }

        if let phone {
            components.append(
                (name: phoneLabel, value: phone)
            )
        }

        if let reviewsCount = reviewCount {
            components.append(
                (name: reviewsLabel, value: "\(reviewsCount)")
            )
        }

        if let avgRating = averageRating {
            components.append(
                (name: ratingLabel, value: "\(avgRating)")
            )
        }

        if !categories.isEmpty {
            let categories = categories.count > 2 ? Array(categories.dropFirst(2)) : categories

            components.append(
                (name: categoriesLabel, value: categories.joined(separator: ","))
            )
        }

        if let mapboxId {
            components.append(
                (name: idLabel, value: mapboxId)
            )
        }

        return components
    }
}
