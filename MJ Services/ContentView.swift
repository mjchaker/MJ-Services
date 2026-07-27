import SwiftUI

// MARK: - App entry

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Service catalog

struct Service: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let symbol: String
    let tint: Color
}

extension Service {
    static let catalog: [Service] = [
        Service(id: "apple", name: "Apple Platforms", tagline: "Swift, SwiftUI, HomeKit & Matter", symbol: "apple.logo", tint: .blue),
        Service(id: "web", name: "Web Development", tagline: "Rails, React, Flask, WebGL", symbol: "globe", tint: .teal),
        Service(id: "systems", name: "Systems & Low-Level", tagline: "C, C++, compilers, AArch64", symbol: "cpu", tint: .orange),
        Service(id: "ai", name: "AI Agents & MCP", tagline: "MCP servers, LLM tool-calling", symbol: "brain.head.profile", tint: .purple),
        Service(id: "python", name: "Python & Automation", tagline: "Scripting, Flask, REST APIs", symbol: "apple.terminal", tint: .green),
        Service(id: "csharp", name: "C# / .NET", tagline: "Desktop & backend services", symbol: "chevron.left.forwardslash.chevron.right", tint: .indigo),
        Service(id: "java", name: "Java & JVM", tagline: "Plugins, agents, tooling", symbol: "cup.and.saucer.fill", tint: .brown),
        Service(id: "audio", name: "Audio & DSP", tagline: "Signal processing, production", symbol: "waveform", tint: .pink),
    ]
}

/// A request the user is about to send, shown in the confirmation alert.
struct ServiceRequest {
    var services: [Service]
    var notes: String
}

// MARK: - Portfolio data fetched from mjchaker.github.io

struct PortfolioProject: Identifiable {
    let id = UUID()
    let icon: String
    let category: String
    let title: String
    let summary: String
    let tags: [String]
}

struct Portfolio {
    var headline: String
    var status: String
    var skills: [String]
    var projects: [PortfolioProject]
}

@Observable @MainActor
final class PortfolioModel {
    enum Phase {
        case loading
        case loaded(Portfolio)
        case failed(String)
    }

    private(set) var phase: Phase = .loading

    static let siteURL = URL(string: "https://mjchaker.github.io")!

    func load() async {
        phase = .loading
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.siteURL)
            let html = String(decoding: data, as: UTF8.self)
            phase = .loaded(Self.parse(html))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    // MARK: HTML parsing

    // The site is a static page; project cards are
    // <article class="card reveal"> blocks inside the #projects section.
    static func parse(_ html: String) -> Portfolio {
        let headline = plainText(firstCapture(in: html, matching: #/<h1>(.*?)</h1>/#.dotMatchesNewlines()))
        let status = plainText(firstCapture(in: html, matching: #/<p class="eyebrow">(.*?)</p>/#.dotMatchesNewlines()))
        let skills = listItems(in: firstCapture(in: html, matching: #/<ul class="chips" aria-label="Skills">(.*?)</ul>/#.dotMatchesNewlines()))

        let projectsHTML = section(of: html, from: "id=\"projects\"", to: "id=\"music\"")
        let cardRegex = #/<article class="card reveal">\s*<div class="card-top">\s*<span class="card-icon"[^>]*>(.*?)</span>\s*<span class="card-tag">(.*?)</span>.*?<h3>(.*?)</h3>\s*<p>(.*?)</p>\s*<ul class="chips chips-sm">(.*?)</ul>/#.dotMatchesNewlines()
        let projects = projectsHTML.matches(of: cardRegex).map { match in
            PortfolioProject(
                icon: plainText(String(match.1)),
                category: plainText(String(match.2)),
                title: plainText(String(match.3)),
                summary: plainText(String(match.4)),
                tags: listItems(in: String(match.5))
            )
        }

        return Portfolio(headline: headline, status: status, skills: skills, projects: projects)
    }

    private static func firstCapture(in html: String, matching regex: Regex<(Substring, Substring)>) -> String {
        guard let match = html.firstMatch(of: regex) else { return "" }
        return String(match.1)
    }

    private static func listItems(in fragment: String) -> [String] {
        fragment.matches(of: #/<li>(.*?)</li>/#.dotMatchesNewlines()).map { plainText(String($0.1)) }
    }

    private static func section(of html: String, from startMarker: String, to endMarker: String) -> String {
        guard let start = html.range(of: startMarker) else { return html }
        let tail = html[start.upperBound...]
        guard let end = tail.range(of: endMarker) else { return String(tail) }
        return String(tail[..<end.lowerBound])
    }

    private static func plainText(_ fragment: String) -> String {
        var text = fragment.replacing(#/<[^>]+>/#, with: " ")
        let entities: [String: String] = ["&amp;": "&", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "]
        for (entity, character) in entities {
            text = text.replacing(entity, with: character)
        }
        return text.replacing(#/\s+/#, with: " ").trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Applying a reorder difference (SDK 27 reorderable containers)

extension ReorderDifference where CollectionID == ReorderableSingleCollectionIdentifier {
    func apply<C>(to collection: inout C)
        where C: RangeReplaceableCollection,
              C.Element: Identifiable,
              C.Element.ID == ItemID
    {
        let moving = Set(sources)
        guard !moving.isEmpty else { return }

        var moved: [C.Element] = []
        moved.reserveCapacity(moving.count)
        collection.removeAll { element in
            guard moving.contains(element.id) else { return false }
            moved.append(element)
            return true
        }

        switch destination.position {
        case .before(let id):
            let index = collection.firstIndex { $0.id == id } ?? collection.endIndex
            collection.insert(contentsOf: moved, at: index)
        case .end:
            collection.append(contentsOf: moved)
        }
    }
}

// MARK: - Content view

struct ContentView: View {
    @State private var portfolio = PortfolioModel()
    @State private var selectedServices: [Service] = []
    @State private var notes: String = ""
    @State private var pendingRequest: ServiceRequest?
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero
                servicePicker
                if !selectedServices.isEmpty {
                    priorityList
                    notesField
                    submitButton
                }
                portfolioSection
            }
            .padding(20)
        }
        .background {
            backdrop
        }
        .task {
            await portfolio.load()
        }
        .alert("Send this request to MJ?", item: $pendingRequest) { request in
            Button("Email MJ") { openMail(for: request) }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            Text("You're requesting \(request.services.map(\.name).formatted(.list(type: .and))). This opens a pre-filled email to mjchaker19@gmail.com.")
        }
    }

    // MARK: Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Hire MJ Chaker")
                .font(.largeTitle.bold())
            Text(headlineText)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Pick the programming services you need, rank them by priority, and send your request.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 28))
    }

    private var servicePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What do you need built?")
                .font(.title2.bold())
            Text("Choose as many as you like.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            // Container spacing must stay below the grid spacing; a larger value
            // makes the chip glass shapes blend at rest and re-update every frame.
            GlassEffectContainer(spacing: 8) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                    ForEach(Service.catalog) { service in
                        ServiceChip(service: service, isSelected: selectedServices.contains(service)) {
                            toggle(service)
                        }
                    }
                }
            }
        }
    }

    private var priorityList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rank your priorities")
                .font(.title2.bold())
            Text("Drag to reorder — the top item is what MJ tackles first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(spacing: 10) {
                ForEach(selectedServices) { service in
                    PriorityRow(
                        rank: (selectedServices.firstIndex(of: service) ?? 0) + 1,
                        service: service
                    ) {
                        toggle(service)
                    }
                }
                .reorderable()
            }
            .reorderContainer(for: Service.self) { difference in
                withAnimation(.smooth) {
                    difference.apply(to: &selectedServices)
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Project details")
                .font(.title2.bold())
            TextField("Anything MJ should know about the project?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
        }
    }

    private var submitButton: some View {
        Button {
            pendingRequest = ServiceRequest(services: selectedServices, notes: notes)
        } label: {
            Label("Request these services", systemImage: "paperplane.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(.blue)
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Live from mjchaker.github.io")
                .font(.title2.bold())
            switch portfolio.phase {
            case .loading:
                HStack {
                    ProgressView()
                    Text("Fetching MJ's portfolio…")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            case .failed(let message):
                VStack(alignment: .leading, spacing: 10) {
                    Label("Couldn't reach the site", systemImage: "wifi.exclamationmark")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await portfolio.load() }
                    }
                    .buttonStyle(.glass)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: .rect(cornerRadius: 20))
            case .loaded(let loaded):
                if !loaded.skills.isEmpty {
                    Text(loaded.skills.joined(separator: "  ·  "))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ForEach(loaded.projects) { project in
                    ProjectCard(project: project)
                }
            }
            Link(destination: PortfolioModel.siteURL) {
                Label("Visit mjchaker.github.io", systemImage: "safari")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var backdrop: some View {
        Rectangle()
            .fill(MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1],
                ],
                colors: [
                    .blue.opacity(0.35), .indigo.opacity(0.25), .purple.opacity(0.3),
                    .teal.opacity(0.2), .blue.opacity(0.1), .indigo.opacity(0.25),
                    .cyan.opacity(0.25), .purple.opacity(0.15), .blue.opacity(0.3),
                ]
            ))
            .ignoresSafeArea()
    }

    // MARK: Derived text

    private var loadedPortfolio: Portfolio? {
        if case .loaded(let loaded) = portfolio.phase { return loaded }
        return nil
    }

    private var statusText: String {
        if let status = loadedPortfolio?.status, !status.isEmpty { return status }
        return "Open to new opportunities"
    }

    private var headlineText: String {
        if let headline = loadedPortfolio?.headline, !headline.isEmpty { return headline }
        return "Software engineer with an ear for detail."
    }

    // MARK: Actions

    // Deliberately not animated: animating the glass tint in the same frame as
    // the interactive-glass press reaction re-enters the glass update cycle
    // ("glassEffect() tried to update multiple times per frame").
    private func toggle(_ service: Service) {
        if let index = selectedServices.firstIndex(of: service) {
            selectedServices.remove(at: index)
        } else {
            selectedServices.append(service)
        }
    }

    private func openMail(for request: ServiceRequest) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "mjchaker19@gmail.com"
        let serviceList = request.services.enumerated()
            .map { "\($0.offset + 1). \($0.element.name)" }
            .joined(separator: "\n")
        var body = "Hi MJ,\n\nI'd like to hire you for the following services, in priority order:\n\n\(serviceList)\n"
        if !request.notes.isEmpty {
            body += "\nProject details:\n\(request.notes)\n"
        }
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Programming services request"),
            URLQueryItem(name: "body", value: body),
        ]
        if let url = components.url {
            openURL(url)
        }
    }
}

// MARK: - Components

struct ServiceChip: View {
    let service: Service
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: service.symbol)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(service.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.subheadline.weight(.semibold))
                    Text(service.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? service.tint : .secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(chipGlass, in: .rect(cornerRadius: 20))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // A single glass configuration whose tint animates, rather than two
    // structurally different configurations swapped on selection.
    private var chipGlass: Glass {
        .regular.tint(isSelected ? service.tint.opacity(0.45) : nil).interactive()
    }
}

struct PriorityRow: View {
    let rank: Int
    let service: Service
    let remove: () -> Void

    init(rank: Int, service: Service, remove: @escaping () -> Void) {
        self.rank = rank
        self.service = service
        self.remove = remove
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .frame(width: 28, height: 28)
                .background(service.tint.opacity(0.25), in: .circle)
            Image(systemName: service.symbol)
                .foregroundStyle(service.tint)
            Text(service.name)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(action: remove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(service.name)")
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

struct ProjectCard: View {
    let project: PortfolioProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.icon)
                    .font(.title2)
                Spacer()
                Text(project.category)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: .capsule)
            }
            Text(project.title)
                .font(.headline)
            Text(project.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
            Text(project.tags.joined(separator: " · "))
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    ContentView()
}
