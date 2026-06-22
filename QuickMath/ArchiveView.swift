import SwiftUI
import SwiftData

// MARK: - Insights View (Pro)

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var showExport = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        weeklyDigestSection
                        followUpDigestSection
                        detailTimelineSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportText = buildExport()
                        showExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ShareSheet(text: exportText)
            }
        }
    }

    // MARK: - Weekly Digest

    @ViewBuilder
    private var weeklyDigestSection: some View {
        let shouldCheck = peopleToCheckOn
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.qmAccent)
                Text("Weekly Digest")
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            if shouldCheck.isEmpty {
                Text("Everyone is up to date. No follow-ups due this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(shouldCheck, id: \.id) { person in
                    let pending = person.followUps.filter { !$0.done && isDueSoon($0) }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(person.name)
                            .font(.subheadline.weight(.semibold))
                        ForEach(pending) { fu in
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                                Text(fu.prompt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .qmCard()
                }
            }
        }
    }

    private var peopleToCheckOn: [KindredPerson] {
        appModel.people.filter { person in
            person.followUps.contains { !$0.done && isDueSoon($0) }
        }
    }

    private func isDueSoon(_ followUp: KindredFollowUp) -> Bool {
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        return followUp.dueDate.timeIntervalSinceNow <= sevenDays
    }

    // MARK: - Follow-up Digest

    @ViewBuilder
    private var followUpDigestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(Color.qmAccent)
                Text("Promised Follow-ups")
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            let allPending = appModel.people.flatMap { person in
                person.followUps.filter { !$0.done }.map { (person, $0) }
            }.sorted { $0.1.dueDate < $1.1.dueDate }

            if allPending.isEmpty {
                Text("No pending follow-ups. Great work!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(allPending, id: \.1.id) { (person, followUp) in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.qmAccent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text(person.name.prefix(1).uppercased())
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.qmAccent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(followUp.prompt)
                                .font(.subheadline)
                            Text(followUp.dueDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(isOverdue(followUp) ? Color.qmWrong : .secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func isOverdue(_ followUp: KindredFollowUp) -> Bool {
        followUp.dueDate < Date()
    }

    // MARK: - Detail Timeline

    @ViewBuilder
    private var detailTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.qmAccent)
                Text("Detail Timeline")
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            let allDetails = appModel.people.flatMap { person in
                person.details.map { (person, $0) }
            }.sorted { $0.1.addedAt > $1.1.addedAt }

            if allDetails.isEmpty {
                Text("No details yet. Open a person card and start capturing what they share.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(allDetails.prefix(20), id: \.1.id) { (person, detail) in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(Color.qmAccent)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)
                            Rectangle()
                                .fill(Color.qmHair)
                                .frame(width: 1)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(person.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.qmAccent)
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(detail.kindEnum.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(detail.addedAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(detail.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Export

    private func buildExport() -> String {
        var lines: [String] = ["Kindred — Your Memory Export", "Exported \(Date().formatted(date: .long, time: .shortened))", ""]
        for person in appModel.people {
            lines.append("## \(person.name) (\(person.relation))")
            for detail in person.details.sorted(by: { $0.addedAt < $1.addedAt }) {
                lines.append("[\(detail.kindEnum.label)] \(detail.text)")
            }
            let pending = person.followUps.filter { !$0.done }
            if !pending.isEmpty {
                lines.append("Follow-ups:")
                for fu in pending {
                    lines.append("  - \(fu.prompt) (due \(fu.dueDate.formatted(date: .abbreviated, time: .omitted)))")
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
