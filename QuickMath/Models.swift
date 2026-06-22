import SwiftUI
import SwiftData

// MARK: - SwiftData Models

enum DetailKind: String, Codable, CaseIterable {
    case loves, dislikes, goal, worry, date
    var label: String {
        switch self {
        case .loves: return "Loves"
        case .dislikes: return "Dislikes"
        case .goal: return "Goal"
        case .worry: return "Worry"
        case .date: return "Date"
        }
    }
    var icon: String {
        switch self {
        case .loves: return "heart"
        case .dislikes: return "hand.thumbsdown"
        case .goal: return "target"
        case .worry: return "exclamationmark.triangle"
        case .date: return "calendar"
        }
    }
}

@Model
final class KindredPerson {
    var id: UUID
    var name: String
    var relation: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var details: [KindredDetail] = []
    @Relationship(deleteRule: .cascade) var followUps: [KindredFollowUp] = []

    init(name: String, relation: String) {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.createdAt = Date()
    }
}

@Model
final class KindredDetail {
    var id: UUID
    var personID: UUID
    var kind: String
    var text: String
    var addedAt: Date

    var kindEnum: DetailKind { DetailKind(rawValue: kind) ?? .loves }

    init(personID: UUID, kind: DetailKind, text: String) {
        self.id = UUID()
        self.personID = personID
        self.kind = kind.rawValue
        self.text = text
        self.addedAt = Date()
    }
}

@Model
final class KindredFollowUp {
    var id: UUID
    var personID: UUID
    var prompt: String
    var dueDate: Date
    var done: Bool

    init(personID: UUID, prompt: String, dueDate: Date) {
        self.id = UUID()
        self.personID = personID
        self.prompt = prompt
        self.dueDate = dueDate
        self.done = false
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var people: [KindredPerson] = []
    @Published private(set) var todayCard: (person: KindredPerson, detail: KindredDetail)?

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([KindredPerson.self, KindredDetail.self, KindredFollowUp.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    func reload() {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<KindredPerson>(sortBy: [SortDescriptor(\.createdAt)])
        people = (try? ctx.fetch(descriptor)) ?? []
        pickTodayCard()
    }

    func refresh() { reload() }

    // MARK: - Today Card

    private func pickTodayCard() {
        let allDetails: [(KindredPerson, KindredDetail)] = people.flatMap { p in
            p.details.map { (p, $0) }
        }
        guard !allDetails.isEmpty else { todayCard = nil; return }
        // Deterministic daily rotation based on day-of-year
        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let pair = allDetails[dayIndex % allDetails.count]
        todayCard = pair
    }

    // MARK: - People CRUD

    func addPerson(name: String, relation: String) {
        let ctx = container.mainContext
        let isPro = store?.isPro ?? false
        guard isPro || people.count < 10 else { return }
        let p = KindredPerson(name: name, relation: relation)
        ctx.insert(p)
        try? ctx.save()
        reload()
        Haptics.success()
    }

    func deletePerson(_ person: KindredPerson) {
        let ctx = container.mainContext
        ctx.delete(person)
        try? ctx.save()
        reload()
    }

    // MARK: - Details CRUD

    func addDetail(to person: KindredPerson, kind: DetailKind, text: String) {
        let ctx = container.mainContext
        let d = KindredDetail(personID: person.id, kind: kind, text: text)
        person.details.append(d)
        try? ctx.save()
        reload()
        Haptics.tap()
    }

    func deleteDetail(_ detail: KindredDetail, from person: KindredPerson) {
        let ctx = container.mainContext
        if let idx = person.details.firstIndex(where: { $0.id == detail.id }) {
            person.details.remove(at: idx)
        }
        ctx.delete(detail)
        try? ctx.save()
        reload()
    }

    // MARK: - Follow-ups CRUD

    func addFollowUp(to person: KindredPerson, prompt: String, dueDate: Date) {
        let ctx = container.mainContext
        let f = KindredFollowUp(personID: person.id, prompt: prompt, dueDate: dueDate)
        person.followUps.append(f)
        try? ctx.save()
        reload()
        Haptics.tap()
    }

    func markFollowUpDone(_ followUp: KindredFollowUp) {
        followUp.done = true
        try? container.mainContext.save()
        reload()
    }

    func deleteFollowUp(_ followUp: KindredFollowUp, from person: KindredPerson) {
        let ctx = container.mainContext
        if let idx = person.followUps.firstIndex(where: { $0.id == followUp.id }) {
            person.followUps.remove(at: idx)
        }
        ctx.delete(followUp)
        try? ctx.save()
        reload()
    }

    // MARK: - Delete All

    func deleteAllData() {
        let ctx = container.mainContext
        people.forEach { ctx.delete($0) }
        try? ctx.save()
        reload()
    }
}
