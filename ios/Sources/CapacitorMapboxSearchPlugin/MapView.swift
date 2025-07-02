//
//  MapView.swift
//  CapacitorMapboxSearchPlugin
//
//  Created by 董思盼 on 2025/7/2.
//
import MapboxMaps
import UIKit

extension MapView {
    func makeClusterPointAnnotationManager(
        duration: TimeInterval = 0.5
    ) -> PointAnnotationManager {
        let manager = annotations.makePointAnnotationManager(clusterOptions: .init())
        manager.onClusterTap = { [weak self] context in
            let cameraOptions = CameraOptions(center: context.coordinate, zoom: context.expansionZoom)
            self?.camera.ease(to: cameraOptions, duration: duration)
        }
        return manager
    }
}
