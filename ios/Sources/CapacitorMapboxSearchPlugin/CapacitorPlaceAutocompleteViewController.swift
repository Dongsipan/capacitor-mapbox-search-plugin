
import MapboxSearch
import UIKit
import CoreLocation

final class CapacitorPlaceAutocompleteViewController: UIViewController {
    @IBOutlet private var tableView: UITableView?
    @IBOutlet private var messageLabel: UILabel?

    private var searchController: UISearchController?

    private var locationManager: CLLocationManager?
    private lazy var placeAutocomplete = PlaceAutocomplete()

    private var cachedSuggestions: [PlaceAutocomplete.Suggestion] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        configureUI()
    }
    
    // 关闭窗口的回调
    var onDismiss: (() -> Void)?
    
    
    @objc private func closeWindow() {
        onDismiss?()
    }
}

// MARK: - UISearchResultsUpdating

extension CapacitorPlaceAutocompleteViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
              !text.isEmpty
        else {
            cachedSuggestions = []

            reloadData()
            return
        }

        placeAutocomplete.suggestions(
            for: text,
            proximity: locationManager?.location?.coordinate,
            filterBy: .init(types: [.POI], navigationProfile: .cycling)
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let suggestions):
                cachedSuggestions = suggestions
                reloadData()

            case .failure(let error):
                print(error)
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
        messageLabel?.isHidden = !cachedSuggestions.isEmpty
        tableView?.isHidden = cachedSuggestions.isEmpty

        tableView?.reloadData()
    }

    private func configureUI() {
        configureSearchController()
        configureTableView()
        configureMessageLabel()
    }

    private func configureSearchController() {

        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchResultsUpdater = self
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.searchController?.searchBar.placeholder = "Search for a place"
        self.searchController?.searchBar.returnKeyType = .done

        navigationItem.searchController = self.searchController
    }

    private func configureMessageLabel() {
        messageLabel?.text = "Start typing to get autocomplete suggestions"
    }

    private func configureTableView() {
        tableView?.tableFooterView = UIView(frame: .zero)

        tableView?.delegate = self
        tableView?.dataSource = self

        tableView?.isHidden = true
    }
}
