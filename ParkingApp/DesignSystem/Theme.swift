import SwiftUI

/// Design tokens shared by every screen.
enum Theme {
    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 22
    }

    enum Layout {
        /// Height of primary buttons and text fields.
        static let controlHeight: CGFloat = 52
        /// Keeps forms readable when the app runs on larger screens.
        static let maxContentWidth: CGFloat = 420
    }
}
