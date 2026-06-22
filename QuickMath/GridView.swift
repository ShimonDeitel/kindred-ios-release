import SwiftUI
import SwiftData

// MARK: - Person Card View (main entry/action screen)

struct PersonCardView: View {
    let person: KindredPerson
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var showAddDetail = false
    @State private var showAddFollowUp = false
    @State private var showPaywall = false
    @State private var confirmDelete = false
    @State private var selectedKind: DetailKind = .loves

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        personHeader
                        detailsSection
                        followUpsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(person.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Remove Person", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddDetail) {
                AddDetailSheet(person: person, initialKind: selectedKind)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showAddFollowUp) {
                AddFollowUpSheet(person: person)
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Remove \(person.name)?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    appModel.deletePerson(person)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Header

    private var personHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.qmAccent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Text(person.name.prefix(1).uppercased())
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.qmAccent)
            }
            Text(person.name)
                .font(.title2.weight(.bold))
            if !person.relation.isEmpty {
                Text(person.relation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Details Section

    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What you know")
                    .font(.headline)
                Spacer()
                Button {
                    selectedKind = .loves
                    showAddDetail = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .padding(.horizontal, 4)

            if person.details.isEmpty {
                Text("Nothing added yet. Tap + to capture what they've shared.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                // Group by kind
                ForEach(DetailKind.allCases, id: \.self) { kind in
                    let items = person.details.filter { $0.kind == kind.rawValue }
                    if !items.isEmpty {
                        kindSection(kind: kind, items: items)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func kindSection(kind: DetailKind, items: [KindredDetail]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: kind.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.qmAccent)
                Text(kind.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            ForEach(items) { detail in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color.qmAccent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(detail.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        appModel.deleteDetail(detail, from: person)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.quaternary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Follow-ups Section

    @ViewBuilder
    private var followUpsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Follow-ups")
                    .font(.headline)
                Spacer()
                Button {
                    if store.isPro { showAddFollowUp = true }
                    else { showPaywall = true }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(store.isPro ? Color.qmAccent : Color.secondary)
                }
            }
            .padding(.horizontal, 4)

            if !store.isPro {
                HStack(spacing: 10) {
                    Image(systemName: "crown")
                        .foregroundStyle(Color.qmAccent)
                    Text("Upgrade to Pro for auto follow-up prompts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(14)
                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onTapGesture { showPaywall = true }
            } else {
                let pending = person.followUps.filter { !$0.done }
                let done = person.followUps.filter { $0.done }

                if person.followUps.isEmpty {
                    Text("No follow-ups yet. Tap + to add one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    if !pending.isEmpty {
                        ForEach(pending) { followUp in
                            FollowUpRow(followUp: followUp, person: person)
                                .environmentObject(appModel)
                        }
                    }
                    if !done.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("COMPLETED")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            ForEach(done) { followUp in
                                FollowUpRow(followUp: followUp, person: person)
                                    .environmentObject(appModel)
                                    .opacity(0.5)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Follow-up Row

struct FollowUpRow: View {
    let followUp: KindredFollowUp
    let person: KindredPerson
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                if !followUp.done { appModel.markFollowUpDone(followUp) }
            } label: {
                Image(systemName: followUp.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(followUp.done ? Color.qmCorrect : Color.qmAccent)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(followUp.prompt)
                    .font(.subheadline)
                    .strikethrough(followUp.done)
                Text(followUp.dueDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                appModel.deleteFollowUp(followUp, from: person)
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(14)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Add Detail Sheet

struct AddDetailSheet: View {
    let person: KindredPerson
    let initialKind: DetailKind
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: DetailKind = .loves
    @State private var text = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 20) {
                    // Kind picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(DetailKind.allCases, id: \.self) { kind in
                                Button {
                                    selectedKind = kind
                                    Haptics.tap()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: kind.icon)
                                            .font(.caption.weight(.semibold))
                                        Text(kind.label)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundStyle(selectedKind == kind ? .white : Color.qmAccent)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        selectedKind == kind ? Color.qmAccent : Color.qmCard,
                                        in: Capsule()
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    TextField("What did \(person.name) share?", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)

                    Button("Save Detail") {
                        let trimmed = text.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appModel.addDetail(to: person, kind: selectedKind, text: trimmed)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .prominentButton()

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { selectedKind = initialKind }
        }
    }
}

// MARK: - Add Follow-up Sheet

struct AddFollowUpSheet: View {
    let person: KindredPerson
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var prompt = ""
    @State private var dueDate = Date().addingTimeInterval(60 * 60 * 24 * 7) // 1 week

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 20) {
                    TextField("What should you follow up on?", text: $prompt, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)

                    DatePicker("Remind me by", selection: $dueDate, in: Date()..., displayedComponents: .date)
                        .padding(.horizontal, 20)

                    Button("Save Follow-up") {
                        let trimmed = prompt.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appModel.addFollowUp(to: person, prompt: trimmed, dueDate: dueDate)
                        dismiss()
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
                    .prominentButton()

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("New Follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
