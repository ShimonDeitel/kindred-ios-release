import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let benefits: [String] = [
        "Unlimited people and auto follow-up prompts",
        "Detail timeline and weekly digest of who to check on",
        "Reminders for follow-ups you promised, plus export"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            iconSection
                            titleSection
                            benefitsSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    bottomSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qmAccent.opacity(0.1))
                .frame(width: 90, height: 90)
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.qmAccent)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Kindred Pro")
                .font(.title.weight(.bold))
            Text("\(store.displayPrice) / month. Auto-renews until you cancel.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qmCorrect)
                        .font(.title3)
                    Text(benefit)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(14)
                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                Task { await store.purchase() }
            } label: {
                HStack {
                    if store.purchaseInFlight {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock Kindred Pro")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .disabled(store.purchaseInFlight)
            .padding(.horizontal, 24)

            Button("Restore Purchase") {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .foregroundStyle(Color.qmAccent)

            Text("Subscription auto-renews at \(store.displayPrice)/month. Cancel any time in Settings > Subscriptions. Payment charged to Apple ID account at confirmation of purchase.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 20) {
                Button("Terms") {
                    openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                Button("Privacy") {
                    openURL(URL(string: "https://shimondeitel.github.io/kindred-site/privacy.html")!)
                }
            }
            .font(.caption)
            .foregroundStyle(Color.qmAccent)
        }
        .padding(.vertical, 20)
        .background(Color(uiColor: .systemBackground))
    }
}
