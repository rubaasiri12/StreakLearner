import SwiftUI

// MARK: - Colors (change a color here and it changes everywhere in the app)

extension Color {
    // Main colors
    static let appOrange          = Color(hex: "FF9230")                 // orange
    static let freezeBlue         = Color(hex: "3CD3FE")                 // blue

    // Backgrounds
    static let appBackground      = Color(hex: "000000")                 // black page background
    static let loggedCircle       = Color(hex: "1A1A1A")                 // "Logged as Learned" circle
    static let learnedTint        = Color.appOrange.opacity(0.20)        // past learned days
    static let freezedTint        = Color.freezeBlue.opacity(0.20)       // past freezed days
    static let badgeTint          = Color.appOrange.opacity(0.12)        // onboarding flame circle
    static let disabledOrange     = Color.appOrange.opacity(0.40)        // orange button when disabled

    // Text
    static let primaryText        = Color(hex: "FFFFFF")                 // white
    static let cardText           = Color(hex: "FFFFFF").opacity(0.85)   // "Learned" / "Freezed" label
    static let secondaryText      = Color(hex: "8C8C8C")                 // date, captions
    static let disabledText       = Color(hex: "616161")                 // greyed-out buttons

    // Lines and effects
    static let divider            = Color(hex: "FFFFFF").opacity(0.15)   // calendar month lines
    static let inputLine          = Color(hex: "FFFFFF").opacity(0.20)   // line under the text field
    static let loggedCircleBorder = Color(hex: "FFFFFF").opacity(0.15)
    static let orangeGlow         = Color.appOrange.opacity(0.35)        // shadow under the big circle

    // Glass (used before iOS 26)
    static let glassFill          = Color(hex: "FFFFFF").opacity(0.06)
    static let glassEdgeLight     = Color(hex: "FFFFFF").opacity(0.35)
    static let glassEdgeDim       = Color(hex: "FFFFFF").opacity(0.05)
    static let glassEdgeMid       = Color(hex: "FFFFFF").opacity(0.25)
}

extension Color {
    /// Lets you write colors as hex codes: Color(hex: "FF9230")
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0
        let red   = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue  = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

extension View {
    /// Liquid Glass on iOS 26 (Xcode 26+); a dark glassy card with a light edge otherwise.
    @ViewBuilder
    func glassBackground<S: Shape>(_ shape: S, tint: Color? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(tint.map { Glass.regular.tint($0) } ?? .regular, in: shape)
        } else {
            self.fallbackGlass(shape, tint: tint)
        }
        #else
        self.fallbackGlass(shape, tint: tint)
        #endif
    }

    private func fallbackGlass<S: Shape>(_ shape: S, tint: Color?) -> some View {
        self
            .background(shape.fill(tint ?? Color.glassFill))
            .overlay(
                shape.stroke(
                    LinearGradient(colors: [Color.glassEdgeLight, Color.glassEdgeDim, Color.glassEdgeMid],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8)
            )
    }
}

/// Orange capsule ("Start Learning", "Set a goal").
struct OrangeCapsuleStyle: ButtonStyle {
    var width: CGFloat? = nil
    var height: CGFloat = 48
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, 24)
            .frame(width: width, height: height)
            .background(Capsule().fill(Color.appOrange))   // always the full orange
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}

/// Round glass icon used in the Activity header.
struct CircleIcon: View {
    let systemName: String
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.primaryText)
            .frame(width: 44, height: 44)
            .glassBackground(Circle())
    }
}
