import Foundation

// MARK: - Choices a client can make without knowing anything technical

enum Budget: String, CaseIterable, Codable, Identifiable {
    case undecided, small, medium, large, enterprise

    var id: String { rawValue }

    var label: String {
        switch self {
        case .undecided: "Not sure yet"
        case .small: "Under $1,000"
        case .medium: "$1,000 – $5,000"
        case .large: "$5,000 – $15,000"
        case .enterprise: "$15,000 or more"
        }
    }
}

enum Timeline: String, CaseIterable, Codable, Identifiable {
    case asap, month, quarter, flexible

    var id: String { rawValue }

    var label: String {
        switch self {
        case .asap: "As soon as possible"
        case .month: "Within a month"
        case .quarter: "In the next few months"
        case .flexible: "No fixed deadline"
        }
    }
}

enum ContactMethod: String, CaseIterable, Codable, Identifiable {
    case email, phone, videoCall

    var id: String { rawValue }

    var label: String {
        switch self {
        case .email: "Email"
        case .phone: "Phone call"
        case .videoCall: "Video call"
        }
    }

    var symbol: String {
        switch self {
        case .email: "envelope"
        case .phone: "phone"
        case .videoCall: "video"
        }
    }
}

// MARK: - The brief

/// Everything a client tells us before sending a request.
///
/// The brief is a plain value: the view owns one, edits it through bindings,
/// and derives the outgoing email from it. Persisting a draft is then just
/// serialising this value — outcomes are stored by identifier so the saved
/// form survives copy changes to the catalog.
struct RequestBrief: Equatable {
    var outcomes: [Outcome] = []
    var goal = ""
    var audience = ""
    var existing = ""
    var budget: Budget = .undecided
    var timeline: Timeline = .flexible
    var name = ""
    var contact: ContactMethod = .email
    var phone = ""

    static let recipient = "mjchaker19@gmail.com"

    /// True when the client hasn't entered anything worth keeping.
    var isBlank: Bool {
        outcomes.isEmpty
            && goal.isEmpty && audience.isEmpty && existing.isEmpty && name.isEmpty && phone.isEmpty
            && budget == .undecided && timeline == .flexible && contact == .email
    }

    var canSend: Bool { !outcomes.isEmpty }

    /// Whether the client asked to be called but gave no number to call.
    var needsPhoneNumber: Bool {
        (contact == .phone || contact == .videoCall) && phone.trimmed.isEmpty
    }

    // MARK: Outgoing message

    var subject: String {
        guard let first = outcomes.first else { return "Project request" }
        let rest = outcomes.count - 1
        let suffix = rest > 0 ? " (+\(rest) more)" : ""
        return "Project request: \(first.name)\(suffix)"
    }

    var body: String {
        var lines: [String] = []
        lines.append("Hi MJ,")
        lines.append("")
        lines.append("I'd like to talk about a project. Here's what I'm after, most important first:")
        lines.append("")
        for (index, outcome) in outcomes.enumerated() {
            lines.append("\(index + 1). \(outcome.name)")
        }

        appendSection("What I want to accomplish", goal, to: &lines)
        appendSection("Who it's for", audience, to: &lines)
        appendSection("What already exists", existing, to: &lines)

        lines.append("")
        lines.append("Budget: \(budget.label)")
        lines.append("Timeline: \(timeline.label)")

        lines.append("")
        var reach = "Best way to reach me: \(contact.label)"
        if !phone.trimmed.isEmpty {
            reach += " (\(phone.trimmed))"
        }
        lines.append(reach)

        lines.append("")
        lines.append("Thanks,")
        lines.append(name.trimmed.isEmpty ? "" : name.trimmed)

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    /// A `mailto:` URL that opens the client's mail app with the message filled in.
    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    private func appendSection(_ title: String, _ text: String, to lines: inout [String]) {
        let trimmed = text.trimmed
        guard !trimmed.isEmpty else { return }
        lines.append("")
        lines.append("\(title):")
        lines.append(trimmed)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Draft persistence

extension RequestBrief: Codable {
    private enum CodingKeys: String, CodingKey {
        case outcomeIDs, goal, audience, existing, budget, timeline, name, contact, phone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ids = try container.decodeIfPresent([String].self, forKey: .outcomeIDs) ?? []
        outcomes = ids.compactMap(Outcome.find)
        goal = try container.decodeIfPresent(String.self, forKey: .goal) ?? ""
        audience = try container.decodeIfPresent(String.self, forKey: .audience) ?? ""
        existing = try container.decodeIfPresent(String.self, forKey: .existing) ?? ""
        budget = try container.decodeIfPresent(Budget.self, forKey: .budget) ?? .undecided
        timeline = try container.decodeIfPresent(Timeline.self, forKey: .timeline) ?? .flexible
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        contact = try container.decodeIfPresent(ContactMethod.self, forKey: .contact) ?? .email
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(outcomes.map(\.id), forKey: .outcomeIDs)
        try container.encode(goal, forKey: .goal)
        try container.encode(audience, forKey: .audience)
        try container.encode(existing, forKey: .existing)
        try container.encode(budget, forKey: .budget)
        try container.encode(timeline, forKey: .timeline)
        try container.encode(name, forKey: .name)
        try container.encode(contact, forKey: .contact)
        try container.encode(phone, forKey: .phone)
    }

    private static let draftKey = "requestBriefDraft"

    /// The draft the client was working on last time, or a fresh brief.
    static func loadDraft(from defaults: UserDefaults = .standard) -> RequestBrief {
        guard let data = defaults.data(forKey: draftKey),
              let brief = try? JSONDecoder().decode(RequestBrief.self, from: data)
        else { return RequestBrief() }
        return brief
    }

    /// Saves the brief so it survives the app being closed; a blank brief clears the draft.
    func saveDraft(to defaults: UserDefaults = .standard) {
        if isBlank {
            defaults.removeObject(forKey: Self.draftKey)
        } else if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.draftKey)
        }
    }
}
