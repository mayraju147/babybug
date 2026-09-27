import SwiftUI
import CoreText

/// Yuji Mai, the curly storybook font (free under the SIL Open Font License).
enum AppFont {
    static let name = "YujiMai-Regular"

    /// Loads the bundled font file the first time it's needed, not at app launch.
    static let isLoaded: Bool = {
        guard let url = Bundle.main.url(forResource: "YujiMai-Regular", withExtension: "ttf"),
              let provider = CGDataProvider(url: url as CFURL),
              let font = CGFont(provider) else { return false }
        return CTFontManagerRegisterGraphicsFont(font, nil)
    }()
}

extension Font {
    static func whimsy(_ size: CGFloat) -> Font {
        _ = AppFont.isLoaded
        return .custom(AppFont.name, size: size)
    }
}
