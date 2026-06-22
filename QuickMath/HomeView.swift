import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showAddPerson = false
    @State private var selectedPerson: KindredPerson?

    private var isPro: Bool { store.isPro }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        todayCardSection
                        statsRow
                        proTile
                        peopleSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Kindred")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddPerson = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddPerson) {
                AddPersonSheet()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(item: $selectedPerson) { person in
                PersonCardView(person: person)
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .onAppear {
                if forceScreen == "paywall" { showPaywall = true }
                if forceScreen == "insights" { showInsights = true }
            }
        }
    }

    // MARK: - Today Card

    @ViewBuilder
    private var todayCardSection: some View {
        if let card = appModel.todayCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.qmAccent)
                    Text("Remember This")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.person.name)
                        .font(.headline.weight(.bold))
                    Text(card.detail.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(card.detail.kindEnum.label.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.qmAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.qmAccent.opacity(0.1), in: Capsule())
                }
            }
            .qmCard()
            .onTapGesture {
                selectedPerson = card.person
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.rectangle.stack")
                    .font(.largeTitle)
                    .foregroundStyle(Color.qmAccent)
                Text("Add your first person")
                    .font(.headline)
                Text("Tap + to add someone and start building their memory card.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .qmCard()
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            MetricTile(value: "\(appModel.people.count)", label: "People")
            MetricTile(value: "\(totalDetails)", label: "Details")
            MetricTile(value: "\(pendingFollowUps)", label: "Follow-ups")
        }
    }

    private var totalDetails: Int {
        appModel.people.reduce(0) { $0 + $1.details.count }
    }

    private var pendingFollowUps: Int {
        appModel.people.reduce(0) { $0 + $1.followUps.filter { !$0.done }.count }
    }

    // MARK: - Pro Tile

    private var proTile: some View {
        Button {
            if isPro { showInsights = true }
            else { showPaywall = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isPro ? "crown.fill" : "crown")
                    .font(.title3)
                    .foregroundStyle(Color.qmAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPro ? "Kindred Pro" : "Upgrade to Pro")
                        .font(.subheadline.weight(.semibold))
                    Text(isPro ? "Weekly digests, insights & export" : "Unlimited people, follow-ups & digests")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - People List

    @ViewBuilder
    private var peopleSection: some View {
        if appModel.people.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your People")
                    .font(.headline)
                    .padding(.horizontal, 4)
                ForEach(appModel.people) { person in
                    PersonRowView(person: person)
                        .onTapGesture { selectedPerson = person }
                }
            }
        }
    }
}

// MARK: - Person Row

struct PersonRowView: View {
    let person: KindredPerson

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.qmAccent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(person.name.prefix(1).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.qmAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.subheadline.weight(.semibold))
                Text(person.relation.isEmpty ? "Friend" : person.relation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(person.details.count) details")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                let pending = person.followUps.filter { !$0.done }.count
                if pending > 0 {
                    Text("\(pending) follow-up\(pending == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(Color.qmAccent)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .qmCard()
    }
}

// MARK: - Add Person Sheet

struct AddPersonSheet: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var relation = ""

    private var atLimit: Bool { !store.isPro && appModel.people.count >= 10 }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 20) {
                    if atLimit {
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(Color.qmAccent)
                            Text("Free limit reached")
                                .font(.headline)
                            Text("Upgrade to Kindred Pro for unlimited people.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    } else {
                        VStack(spacing: 14) {
                            TextField("Name", text: $name)
                                .padding(14)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12))
                            TextField("Relation (e.g. sister, colleague)", text: $relation)
                                .padding(14)
                                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)

                        Button("Add Person") {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            appModel.addPerson(name: trimmed, relation: relation.trimmingCharacters(in: .whitespaces))
                            dismiss()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .prominentButton()
                    }
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
