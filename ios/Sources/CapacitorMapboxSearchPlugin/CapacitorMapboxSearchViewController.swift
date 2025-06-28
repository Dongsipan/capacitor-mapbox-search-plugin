//
//  CapacitorMapboxSearchViewController.swift
//  CapacitorMapboxSearchPlugin
//
//  Created by 董思盼 on 2025/6/27.
//

import UIKit
import CoreLocation
import MapboxMaps
import MapboxSearch
import MapboxSearchUI

final class CapacitorMapboxSearchViewController: UIViewController {
    private lazy var searchController = MapboxSearchController(apiType: .searchBox)

    private var mapView = MapView(frame: .zero)
    lazy var annotationsManager = mapView.annotations.makePointAnnotationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Show user location
        mapView.location.options.puckType = .puck2D()
        mapView.viewport.transition(to: mapView.viewport.makeFollowPuckViewportState())

        searchController.delegate = self
        /// Add MapboxSearchUI above the map
        let panelController = MapboxPanelController(rootViewController: searchController)
        addChild(panelController)

        // Enabling jp/ja search options for testing Japanese Address Search.
        // Setting Japanese into the list of preferred languages is a way to activate it.
        if Locale.preferredLanguages.contains(where: { $0.contains("zh") }) {
            searchController.searchOptions = SearchOptions(countries: ["zh"], languages: ["cn"])
        }
    }

    let locationManager = CLLocationManager()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        locationManager.requestWhenInUseAuthorization()
    }

    func showAnnotations(results: [SearchResult], cameraShouldFollow: Bool = true) {
        annotationsManager.annotations = results.map { result in
            let coordinate = CLLocationCoordinate2D(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude)
            var point = PointAnnotation(point: Point(coordinate))

            // Present a detail view upon annotation tap
            point.tapHandler = { [weak self] _ in
                return self?.present(result: result) ?? false
            }
            return point
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

    @discardableResult
    private func present(result: SearchResult) -> Bool {
        let alert = UIAlertController(title: "搜索结果", message: result.name, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        return true
    }
}

extension CapacitorMapboxSearchViewController: SearchControllerDelegate {
    func categorySearchResultsReceived(category: SearchCategory, results: [SearchResult]) {
        showAnnotations(results: results)
    }

    /// Show annotation on the map when selecting a result.
    /// Separately, selecting an annotation will present a detail view.
    func searchResultSelected(_ searchResult: SearchResult) {
        showAnnotations(results: [searchResult])
    }

    func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
        showAnnotations(results: [userFavorite])
    }
}
