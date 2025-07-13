
import MapboxSearch
import UIKit
import CoreLocation

final class CapacitorPlaceAutocompleteViewController: UIViewController {
    private var tableView: UITableView!
    private var messageLabel: UILabel!

    private var searchController: UISearchController?

    private var locationManager: CLLocationManager?
    private lazy var placeAutocomplete = PlaceAutocomplete()

    private var cachedSuggestions: [PlaceAutocomplete.Suggestion] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 创建 UI 元素
        createUIElements()
        
        // 初始化 Mapbox
        initializeMapbox()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        configureUI()
        
        // 添加滑动手势来关闭页面
        setupSwipeToDismiss()
        
        // 立即设置白色导航栏
        setupWhiteNavigationBar()
        
        // 测试网络连接
        testNetworkConnection()
        
        // 添加测试搜索
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.testSearch()
        }
        
        // 调试搜索控制器状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.debugSearchController()
        }
        
        // 测试 UI 元素
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.testUIElements()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 确保导航栏是白色
        setupWhiteNavigationBar()
    }
    
    // 关闭窗口的回调
    var onDismiss: (() -> Void)?
    
    
    @objc private func closeWindow() {
        // 调用回调
        onDismiss?()
        
        // 直接关闭当前视图控制器
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UISearchResultsUpdating

extension CapacitorPlaceAutocompleteViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // 这个方法现在由 UISearchBarDelegate 处理
        // 保留这个方法以确保兼容性，但不执行搜索逻辑
        print("updateSearchResults called - handled by UISearchBarDelegate")
    }
}

// MARK: - UISearchBarDelegate

extension CapacitorPlaceAutocompleteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("Search bar text changed: '\(searchText)'")
        
        guard !searchText.isEmpty else {
            cachedSuggestions = []
            reloadData()
            return
        }
        
        // 添加防抖，避免频繁请求
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: searchText, afterDelay: 0.5)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search button clicked")
        searchBar.resignFirstResponder()
        
        if let searchText = searchBar.text, !searchText.isEmpty {
            performSearch(searchText)
        }
    }
    
    @objc private func performSearch(_ searchText: String) {
        print("Performing search for: '\(searchText)'")
        placeAutocomplete.suggestions(
            for: searchText,
            proximity: locationManager?.location?.coordinate
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let suggestions):
                print("Found \(suggestions.count) suggestions for '\(searchText)'")
                DispatchQueue.main.async {
                    self.cachedSuggestions = suggestions
                    self.reloadData()
                }

            case .failure(let error):
                print("Search error for '\(searchText)': \(error)")
                print("Error details: \(error.localizedDescription)")
                
                // 检查是否是网络相关错误
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain)")
                    print("Error code: \(nsError.code)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("Underlying error: \(underlyingError)")
                    }
                }
                
//                DispatchQueue.main.async {
//                    self.cachedSuggestions = []
//                    self.reloadData()
//                    
//                    // 显示错误消息给用户
//                    self.showErrorMessage("搜索失败，请检查网络连接")
//                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension CapacitorPlaceAutocompleteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cachedSuggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "suggestion-tableview-cell"

        let tableViewCell: UITableViewCell = if let cachedTableViewCell = tableView
            .dequeueReusableCell(withIdentifier: cellIdentifier)
        {
            cachedTableViewCell
        } else {
            UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        let suggestion = cachedSuggestions[indexPath.row]

        tableViewCell.textLabel?.text = suggestion.name
        tableViewCell.accessoryType = .disclosureIndicator

        var description = suggestion.description ?? ""
        if let distance = suggestion.distance {
            description += "\n\(PlaceAutocomplete.Result.distanceFormatter.string(fromDistance: distance))"
        }
        if let estimatedTime = suggestion.estimatedTime {
            description += "\n\(PlaceAutocomplete.Result.measurementFormatter.string(from: estimatedTime))"
        }

        tableViewCell.detailTextLabel?.text = description
        tableViewCell.detailTextLabel?.textColor = UIColor.darkGray
        tableViewCell.detailTextLabel?.numberOfLines = 3

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        placeAutocomplete.select(suggestion: cachedSuggestions[indexPath.row]) { [weak self] result in
            switch result {
            case .success(let suggestionResult):
                let resultVC = CapacitorPlaceAutocompleteResultViewController.instantiate(with: suggestionResult)
                self?.navigationController?.pushViewController(resultVC, animated: true)

            case .failure(let error):
                print("Suggestion selection error \(error)")
            }
        }
    }
}

// MARK: - Private

extension CapacitorPlaceAutocompleteViewController {
    private func reloadData() {
        print("Reloading data - suggestions count: \(cachedSuggestions.count)")
        
        messageLabel.isHidden = !cachedSuggestions.isEmpty
        tableView.isHidden = cachedSuggestions.isEmpty

        tableView.reloadData()
        
        // 确保表格视图可见
        if !cachedSuggestions.isEmpty {
            tableView.isHidden = false
            messageLabel.isHidden = true
            print("Table view should be visible now")
        } else {
            tableView.isHidden = true
            messageLabel.isHidden = false
            print("Table view hidden, message label visible")
        }
    }

    private func createUIElements() {
        // 创建消息标签
        messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        view.addSubview(messageLabel)
        
        // 创建表格视图
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 消息标签约束
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureUI() {
        configureNavigationBar()
        configureSearchController()
        configureTableView()
        configureMessageLabel()
    }
    
    private func configureNavigationBar() {
        // 根据本地化设置导航栏标题
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                title = "地点搜索"
            } else {
                title = "Place Search"
            }
        } else {
            title = "Place Search"
        }
        
        // 设置白色导航栏
        setupWhiteNavigationBar()
    }

    private func configureSearchController() {

        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchResultsUpdater = self
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.searchController?.searchBar.delegate = self
        
        // 根据本地化设置搜索栏占位符
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                self.searchController?.searchBar.placeholder = "搜索地点"
            } else {
                self.searchController?.searchBar.placeholder = "Search for a place"
            }
        } else {
            self.searchController?.searchBar.placeholder = "Search for a place"
        }
        
        self.searchController?.searchBar.returnKeyType = .search

        navigationItem.searchController = self.searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureMessageLabel() {
        // 根据本地化设置消息文本
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                messageLabel.text = "开始输入以获得自动完成建议"
            } else {
                messageLabel.text = "Start typing to get autocomplete suggestions"
            }
        } else {
            messageLabel.text = "Start typing to get autocomplete suggestions"
        }
        
        messageLabel.backgroundColor = .white
        messageLabel.textColor = .black
    }

    private func configureTableView() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.backgroundColor = .white

        tableView.delegate = self
        tableView.dataSource = self

        tableView.isHidden = true
    }
    
    private func setupSwipeToDismiss() {
        // 添加从右向左滑动手势来关闭页面
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    private func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func initializeMapbox() {
        // 确保 Mapbox 已初始化
        print("Initializing Mapbox Search...")
        
        // 验证访问令牌
        if let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            print("Mapbox access token found: \(String(accessToken.prefix(10)))...")
        } else {
            print("WARNING: No Mapbox access token found in Info.plist")
        }
        
        // 记录本地化设置
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            let regionCode = locale.regionCode ?? "US"
            
            print("Device locale - Language: \(languageCode), Region: \(regionCode)")
            print("Note: PlaceAutocomplete uses default search options based on device locale")
        } else {
            print("Using default locale settings")
        }
    }
    
    private func testNetworkConnection() {
        print("Testing network connection...")
        
        // 测试基本网络连接
        let url = URL(string: "https://www.apple.com")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network test failed: \(error)")
            } else {
                print("Network test successful")
            }
        }
        task.resume()
        
        // 测试 Mapbox API 连接
        if let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            let mapboxURL = URL(string: "https://api.mapbox.com/geocoding/v5/mapbox.places/test.json?access_token=\(accessToken)")!
            let mapboxTask = URLSession.shared.dataTask(with: mapboxURL) { data, response, error in
                if let error = error {
                    print("Mapbox API test failed: \(error)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Mapbox API test response: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Mapbox API response: \(String(responseString.prefix(200)))")
                    }
                }
            }
            mapboxTask.resume()
        }
    }
    
    private func testSearch() {
        print("Testing search functionality...")
        
        // 根据本地化设置测试搜索词
        let testQuery: String
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.languageCode ?? "en"
            
            if languageCode.hasPrefix("zh") {
                testQuery = "北京"
            } else {
                testQuery = "New York"
            }
        } else {
            testQuery = "New York"
        }
        
        placeAutocomplete.suggestions(
            for: testQuery,
            proximity: nil
        ) { [weak self] result in
            switch result {
            case .success(let suggestions):
                print("Test search found \(suggestions.count) suggestions")
                for suggestion in suggestions.prefix(3) {
                    print("- \(suggestion.name): \(suggestion.description ?? "No description")")
                }
            case .failure(let error):
                print("Test search failed: \(error)")
            }
        }
    }
    
    private func debugSearchController() {
        print("=== Search Controller Debug ===")
        print("Search controller: \(String(describing: searchController))")
        print("Search controller delegate: \(String(describing: searchController?.searchResultsUpdater))")
        print("Search bar delegate: \(String(describing: searchController?.searchBar.delegate))")
        print("Search bar text: '\(searchController?.searchBar.text ?? "nil")'")
        print("Table view delegate: \(String(describing: tableView.delegate))")
        print("Table view data source: \(String(describing: tableView.dataSource))")
        print("Table view hidden: \(tableView.isHidden)")
        print("Message label hidden: \(messageLabel.isHidden)")
        print("Cached suggestions count: \(cachedSuggestions.count)")
        print("Table view frame: \(tableView.frame)")
        print("Message label frame: \(messageLabel.frame)")
        print("================================")
    }
    
    private func testUIElements() {
        print("=== UI Elements Test ===")
        
        // 测试表格视图是否正常工作
        print("Testing table view functionality...")
        
        // 检查表格视图的代理和数据源
        if tableView.delegate != nil && tableView.dataSource != nil {
            print("Table view delegate and data source are set correctly")
        } else {
            print("ERROR: Table view delegate or data source is nil")
        }
        
        // 检查表格视图是否可见
        if !tableView.isHidden {
            print("Table view is visible")
        } else {
            print("Table view is hidden")
        }
        
        // 检查消息标签
        if !messageLabel.isHidden {
            print("Message label is visible with text: '\(messageLabel.text ?? "nil")'")
        } else {
            print("Message label is hidden")
        }
        
        print("================================")
    }
}

// MARK: - CLLocationManagerDelegate

extension CapacitorPlaceAutocompleteViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Location updated: \(location.coordinate)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status: \(status.rawValue)")
    }
}
