import CoreGraphics

/// Every shape a window can snap into (D6a).
enum SnapLayout: String, CaseIterable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case leftThird, centreThird, rightThird
    case leftTwoThirds, rightTwoThirds
    case full, centre

    var title: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .topLeft: return "Top Left Quarter"
        case .topRight: return "Top Right Quarter"
        case .bottomLeft: return "Bottom Left Quarter"
        case .bottomRight: return "Bottom Right Quarter"
        case .leftThird: return "Left Third"
        case .centreThird: return "Centre Third"
        case .rightThird: return "Right Third"
        case .leftTwoThirds: return "Left Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .full: return "Full Screen"
        case .centre: return "Centre"
        }
    }

    /// The layout as fractions of the usable area: x, y-from-top, width, height.
    private var unit: (x: CGFloat, top: CGFloat, w: CGFloat, h: CGFloat) {
        let third: CGFloat = 1.0 / 3.0
        switch self {
        case .leftHalf: return (0, 0, 0.5, 1)
        case .rightHalf: return (0.5, 0, 0.5, 1)
        case .topHalf: return (0, 0, 1, 0.5)
        case .bottomHalf: return (0, 0.5, 1, 0.5)
        case .topLeft: return (0, 0, 0.5, 0.5)
        case .topRight: return (0.5, 0, 0.5, 0.5)
        case .bottomLeft: return (0, 0.5, 0.5, 0.5)
        case .bottomRight: return (0.5, 0.5, 0.5, 0.5)
        case .leftThird: return (0, 0, third, 1)
        case .centreThird: return (third, 0, third, 1)
        case .rightThird: return (2 * third, 0, third, 1)
        case .leftTwoThirds: return (0, 0, 2 * third, 1)
        case .rightTwoThirds: return (third, 0, 2 * third, 1)
        case .full: return (0, 0, 1, 1)
        case .centre: return (0.2, 0.125, 0.6, 0.75)
        }
    }

    /// Target frame in Cocoa coordinates (origin bottom-left), given the
    /// usable area of the screen (also Cocoa coordinates).
    ///
    /// `gap` is the space between windows and around the screen edge: the
    /// area is inset by gap/2 and every slot by another gap/2, so outer and
    /// inner gaps are both `gap`.
    func frame(in area: CGRect, gap: CGFloat) -> CGRect {
        let inner = area.insetBy(dx: gap / 2, dy: gap / 2)
        let u = unit
        let slot = CGRect(
            x: inner.minX + u.x * inner.width,
            y: inner.maxY - (u.top + u.h) * inner.height,
            width: u.w * inner.width,
            height: u.h * inner.height)
        return slot.insetBy(dx: gap / 2, dy: gap / 2).integral
    }
}
