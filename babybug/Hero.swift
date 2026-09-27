import Foundation

/// The child who looks after the bunny. Chosen on first launch and saved on the device.
enum Hero: String, CaseIterable, Identifiable {
    case princess
    case prince

    var id: String { rawValue }

    /// Name of the picture in the asset catalog.
    var imageName: String {
        switch self {
        case .princess: "Princess"
        case .prince: "Prince"
        }
    }

    var title: String {
        switch self {
        case .princess: "Princess"
        case .prince: "Prince"
        }
    }
}
