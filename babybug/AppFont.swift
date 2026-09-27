import SwiftUI
import CoreText

/// Yuji Mai, the curly storybook font (free under the SIL Open Font License).
enum AppFont {
    static let name = "YujiMai-Regular"

    /// Loads the bundled font file so SwiftUI can use it, without needing an Info.plist entry.
    static func register() {
        guard let url = Bundle.main.url(forResource: "YujiMai-Regular", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

extension Font {
    static func whimsy(_ size: CGFloat) -> Font {
        .custom(AppFont.name, size: size)
    }
}
