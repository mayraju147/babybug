import SwiftUI

/// Yuji Mai, the curly storybook font (free under the SIL Open Font License).
/// iOS loads it before the app starts, from the `UIAppFonts` entry in babybug-Info.plist.
enum AppFont {
    static let name = "YujiMai-Regular"
}

extension Font {
    static func whimsy(_ size: CGFloat) -> Font {
        .custom(AppFont.name, size: size)
    }
}
