import SwiftUI

@main
struct LandmarksApp: App {
    var body: some Scene {
        WindowGroup {
            LandmarkList()
        }
    }
}

extension UIApplication {
    static var mapTilerKey: String? {
        return Bundle.main.object(forInfoDictionaryKey: "MapTilerKey") as? String
    }
}
