import SwiftUI

enum FolioMotion {
    static let panel = Animation.spring(response: 0.34, dampingFraction: 1.0)
    static let snap = Animation.spring(response: 0.32, dampingFraction: 1.0)
    static let card = Animation.spring(response: 0.40, dampingFraction: 0.85)
    static let fade = Animation.easeInOut(duration: 0.18)
    static let press = Animation.easeOut(duration: 0.10)

    static func panel(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : panel
    }

    static func snap(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : snap
    }

    static func card(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : card
    }
}
