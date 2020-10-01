import Mapbox
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var shapeName: String
  
    func makeUIView(context: Context) -> MGLMapView {
        guard let mapTilerKey = UIApplication.mapTilerKey else {
            preconditionFailure("Failed to read MapTiler key from info.plist")
        }
        
        let styleURL = URL(string: "https://api.maptiler.com/maps/outdoor/style.json?key=\(mapTilerKey)")
        let mapView = MGLMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MGLMapView, context: Context) {}
    
    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, MGLMapViewDelegate {
        var control: MapView
        
        init(_ control: MapView) {
            self.control = control
        }

        func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
            // load polygon from geojson and pan the map
            loadGeoJson(fileName: control.shapeName, mapView: mapView)
        }
        
        func loadGeoJson(fileName: String, mapView: MGLMapView!) {
            DispatchQueue.global().async {
                // Get the path for example.geojson in the app’s bundle.
                guard let jsonUrl = Bundle.main.url(forResource: fileName, withExtension: "geojson") else {
                    preconditionFailure("Failed to load local GeoJSON file")
                }
         
                guard let jsonData = try? Data(contentsOf: jsonUrl) else {
                    preconditionFailure("Failed to parse GeoJSON file")
                }
         
                DispatchQueue.main.sync {
                    self.showLandmarkOnMap(geoJson: jsonData, mapView: mapView)
                }
            }
        }
        
        func showLandmarkOnMap(geoJson: Data, mapView: MGLMapView!) {
            // Add our GeoJSON data to the map as an MGLGeoJSONSource.
            // We can then reference this data from an MGLStyleLayer.
         
            // MGLMapView.style is optional, so you must guard against it not being set.
            guard let style = mapView.style else { return }
            guard let parkFeature = try? MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue) else {
                fatalError("Could not generate MGLShape")
            }
         
            addParkEnvelope(parkFeature, style)
            addMarker(style)
            
            // pan to the polygon
            let camera = mapView.cameraThatFitsShape(parkFeature, direction: 0.0, edgePadding: .init(top: 10, left: 10, bottom: 10, right: 10))
            mapView.fly(to: camera, withDuration: 0.25, completionHandler: nil)
        }
        
        fileprivate func addMarker(_ style: MGLStyle) {
            // create marker
            let point = MGLPointAnnotation()
            point.coordinate = control.coordinate
            
            // Create a data source to hold the point data
            let markerSource = MGLShapeSource(identifier: "marker-source", shape: point, options: nil)
            // Create a style layer for the symbol
            let markerLayer = MGLSymbolStyleLayer(identifier: "marker-style", source: markerSource)
                
            // Add the image to the style's sprite
            if let image = UIImage(named: "landmark-icon") {
                style.setImage(image, forName: "landmark-symbol")
            }
                
            // Tell the layer to use the image in the sprite
            markerLayer.iconImageName = NSExpression(forConstantValue: "landmark-symbol")
                
            // Add the source and style layer to the map
            style.addSource(markerSource)
            style.addLayer(markerLayer)
        }
        
        fileprivate func addParkEnvelope(_ parkFeature: MGLShape, _ style: MGLStyle) {
            // Create new source and layer.
            let parkSource = MGLShapeSource(identifier: "polygon", shape: parkFeature, options: nil)
            style.addSource(parkSource)
            let parkLayer = MGLFillStyleLayer(identifier: "polygon", source: parkSource)
                
            parkLayer.fillColor = NSExpression(forConstantValue: UIColor(rgb: 0x801A86, a: 0.3))
            parkLayer.fillOutlineColor = NSExpression(forConstantValue: UIColor(rgb: 0x4E0250, a: 0.8))
                
            style.addLayer(parkLayer)
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }

    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(coordinate: landmarkData[0].locationCoordinate, shapeName: landmarkData[0].shapeName)
    }
}
