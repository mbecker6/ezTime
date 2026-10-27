import SwiftUI
import ServiceManagement

@main
struct EzTimeApp: App {
    // Empty string means "follow the system time zone".
    @AppStorage("timeZoneID") private var timeZoneID = ""
    @StateObject private var clock = Clock()

    var body: some Scene {
        MenuBarExtra {
            ZonePicker(timeZoneID: $timeZoneID)
        } label: {
            Text(clock.label(zoneID: timeZoneID))
        }
        .menuBarExtraStyle(.window)
    }
}

/// Publishes the current date whenever the minute changes.
final class Clock: ObservableObject {
    @Published private(set) var now = Date()
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let date = Date()
            if Int(date.timeIntervalSince1970 / 60) != Int(self.now.timeIntervalSince1970 / 60) {
                self.now = date
            }
        }
    }

    func label(zoneID: String) -> String {
        let zone = TimeZone(identifier: zoneID) ?? .autoupdatingCurrent
        let formatter = DateFormatter()
        formatter.timeZone = zone
        // Same shape as the macOS clock, e.g. "Tue 27 Oct 14:05" (12/24h follows system locale).
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMMjmm")
        let time = formatter.string(from: now)
        guard !zoneID.isEmpty else { return time }
        return "\(time) \(zone.abbreviation(for: now) ?? zoneID)"
    }
}

struct Zone: Identifiable {
    let id: String          // "" = local time
    let name: String        // "Buenos Aires"
    let detail: String      // "Argentina Time" or the region
    let searchText: String

    init(id: String, name: String, detail: String) {
        self.id = id
        self.name = name
        self.detail = detail
        searchText = "\(id) \(name) \(detail)".lowercased()
    }

    var zone: TimeZone { TimeZone(identifier: id) ?? .autoupdatingCurrent }

    static let all: [Zone] = {
        let local = Zone(id: "", name: "Local Time", detail: TimeZone.current.identifier)
        let ids = ["UTC"] + TimeZone.knownTimeZoneIdentifiers.filter { $0.contains("/") }
        let zones = ids.map { id in
            let city = id.split(separator: "/").last.map(String.init) ?? id
            let generic = TimeZone(identifier: id)?.localizedName(for: .generic, locale: .current)
            return Zone(id: id, name: city.replacingOccurrences(of: "_", with: " "),
                        detail: generic ?? id)
        }
        // West to east, then alphabetically within the same offset.
        return [local] + zones.sorted { ($0.offset, $0.name) < ($1.offset, $1.name) }
    }()

    var offset: Int { zone.secondsFromGMT() }

    /// "GMT", "GMT+1", "GMT−3:30"
    var gmtLabel: String {
        guard offset != 0 else { return "GMT" }
        let hours = abs(offset) / 3600, minutes = abs(offset) % 3600 / 60
        let sign = offset < 0 ? "−" : "+"
        return minutes == 0 ? "GMT\(sign)\(hours)" : String(format: "GMT%@%d:%02d", sign, hours, minutes)
    }
}

struct ZonePicker: View {
    @Binding var timeZoneID: String
    @State private var query = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @FocusState private var searchFocused: Bool

    private var results: [Zone] {
        let words = query.lowercased().split(separator: " ")
        guard !words.isEmpty else { return Zone.all }
        return Zone.all.filter { zone in words.allSatisfy { zone.searchText.contains($0) } }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search time zones", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .onSubmit { if let first = results.first { select(first) } }
                .padding(10)

            Divider()

            List(results) { zone in
                Button { select(zone) } label: { row(zone) }
                    .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(height: 320)

            Divider()

            HStack {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))
                .toggleStyle(.checkbox)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(10)
        }
        .frame(width: 300)
        .onAppear { searchFocused = true }
    }

    private func row(_ zone: Zone) -> some View {
        HStack {
            Image(systemName: "checkmark")
                .opacity(zone.id == timeZoneID ? 1 : 0)
            VStack(alignment: .leading) {
                Text(zone.name)
                Text(zone.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(zone.gmtLabel)
                .font(.caption).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    private func select(_ zone: Zone) {
        timeZoneID = zone.id
        query = ""
        NSApp.keyWindow?.close()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("ezTime: launch at login change failed: \(error)")
        }
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
