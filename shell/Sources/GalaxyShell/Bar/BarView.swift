import SwiftUI

/// 🌌 Galaxy menu · app name ········· status · time · ⇄
///
/// Still to come in Phase 1: the app's own menus (File, Edit…), the
/// control panel behind the Wi-Fi icon, and AI status (Phase 3).
struct BarView: View {
    @ObservedObject var model: BarModel

    var body: some View {
        HStack(spacing: 14) {
            galaxyMenu
            Text(model.frontAppName)
                .fontWeight(.semibold)
                .lineLimit(1)

            Spacer(minLength: 0)

            Image(systemName: model.wifiOn ? "wifi" : "wifi.slash")
            if let volume = model.volume {
                Image(systemName: volumeSymbol(volume))
            }
            if let battery = model.battery {
                HStack(spacing: 4) {
                    Image(systemName: batterySymbol(battery))
                    Text("\(battery.percent)%")
                        .monospacedDigit()
                }
            }
            Text(model.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
                .monospacedDigit()
            Button {
                Actions.run("switchWorld")
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.plain)
            .help("Switch to Mac")
        }
        .font(.system(size: Theme.barFontSize))
        .foregroundStyle(Theme.barText)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.barBackground)
    }

    private var galaxyMenu: some View {
        Menu {
            ForEach(Array(model.galaxyMenu.enumerated()), id: \.offset) { _, entry in
                if entry.action == "separator" {
                    Divider()
                } else {
                    Button(entry.title.isEmpty ? (Actions.title(for: entry.action) ?? entry.action) : entry.title) {
                        Actions.run(entry.action)
                    }
                }
            }
        } label: {
            Text("🌌")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func volumeSymbol(_ v: Float) -> String {
        switch v {
        case ..<0.01: return "speaker.slash"
        case ..<0.34: return "speaker.wave.1"
        case ..<0.67: return "speaker.wave.2"
        default: return "speaker.wave.3"
        }
    }

    private func batterySymbol(_ b: SystemStatus.Battery) -> String {
        if b.charging { return "battery.100.bolt" }
        switch b.percent {
        case ..<13: return "battery.0"
        case ..<38: return "battery.25"
        case ..<63: return "battery.50"
        case ..<88: return "battery.75"
        default: return "battery.100"
        }
    }
}
