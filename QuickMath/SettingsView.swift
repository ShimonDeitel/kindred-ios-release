import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var confirmDeleteAll = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    proSection
                    appearanceSection
                    linksSection
                    dangerSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog("Delete all data?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all people, details and follow-ups. This cannot be undone.")
            }
        }
    }

    // MARK: - Pro Section

    @ViewBuilder
    private var proSection: some View {
        Section("Kindred Pro") {
            if store.isPro {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.qmAccent)
                    Text("Pro is active")
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(Color.qmCorrect)
                }
                Button {
                    openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
                } label: {
                    Label("Manage Subscription", systemImage: "arrow.up.right")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown")
                            .foregroundStyle(Color.qmAccent)
                        Text("Upgrade to Pro")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("$0.99/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    Task { await store.restore() }
                } label: {
                    Label("Restore Purchase", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { t in
                    Text(t.label).tag(t.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Links

    private var linksSection: some View {
        Section("About") {
            Button {
                openURL(URL(string: "https://shimondeitel.github.io/kindred-site/privacy.html")!)
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Button {
                openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            } label: {
                Label("Terms of Use", systemImage: "doc.text")
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                confirmDeleteAll = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundStyle(Color.qmWrong)
            }
        } footer: {
            Text("Permanently removes all people, details and follow-ups from this device.")
        }
    }
}
