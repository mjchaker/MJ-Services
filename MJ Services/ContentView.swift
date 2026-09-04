import SwiftUI

// MARK: - App entry

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content view

struct ContentView: View {
    @State private var portfolio = PortfolioModel()
    @State private var brief: RequestBrief
    @State private var resumedDraft: Bool
    @State private var detailOutcome: Outcome?
    @State private var isReviewing = false
    @State private var isConfirmingReset = false
    @State private var workFilter: WorkFilter = .related

    enum WorkFilter: String, CaseIterable, Identifiable {
        case related, everything
        var id: String { rawValue }
        var label: String {
            switch self {
            case .related: "Related to your request"
            case .everything: "Everything"
            }
        }
    }

    init() {
        let draft = RequestBrief.loadDraft()
        _brief = State(initialValue: draft)
        _resumedDraft = State(initialValue: !draft.isBlank)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero
                if resumedDraft {
                    resumedBanner
                }
                outcomePicker
                if brief.canSend {
                    if brief.outcomes.count > 1 {
                        priorityList
                    }
                    briefForm
                    practicalities
                    contactSection
                    sendSection
                }
                processSection
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
        .onChange(of: brief) { _, newValue in
            newValue.saveDraft()
        }
        .sheet(item: $detailOutcome) { outcome in
            OutcomeDetailView(
                outcome: outcome,
                relatedProjects: portfolio.loaded?.projects(relatedTo: [outcome]) ?? [],
                isSelected: brief.outcomes.contains(outcome)
            ) {
                toggle(outcome)
            }
        }
        .sheet(isPresented: $isReviewing) {
            RequestReviewSheet(brief: brief)
        }
        .confirmationDialog("Start over?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Clear everything", role: .destructive) {
                withAnimation(.smooth) {
                    brief = RequestBrief()
                    resumedDraft = false
                }
            }
        } message: {
            Text("This clears what you've picked and written. Nothing has been sent to MJ yet.")
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
            Text("Tell MJ what you want to make happen. No technical knowledge needed — describe it the way you'd explain it to a friend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 28))
    }

    private var resumedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle")
                .foregroundStyle(.blue)
            Text("Picked up where you left off.")
                .font(.subheadline)
            Spacer()
            Button("Start over") { isConfirmingReset = true }
                .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }

    private var outcomePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "What do you want to make happen?",
                subtitle: "Pick as many as apply. Tap ⓘ for examples, costs to expect, and related work."
            )
            // Container spacing must stay below the grid spacing; a larger value
            // makes the chip glass shapes blend at rest and re-update every frame.
            GlassEffectContainer(spacing: 8) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(Outcome.catalog) { outcome in
                        OutcomeChip(
                            outcome: outcome,
                            isSelected: brief.outcomes.contains(outcome),
                            toggle: { toggle(outcome) },
                            showDetails: { detailOutcome = outcome }
                        )
                    }
                }
            }
        }
    }

    private var priorityList: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "What matters most?",
                subtitle: "Drag to reorder — the top item is what MJ tackles first."
            )
            VStack(spacing: 10) {
                ForEach(brief.outcomes) { outcome in
                    PriorityRow(
                        rank: (brief.outcomes.firstIndex(of: outcome) ?? 0) + 1,
                        outcome: outcome
                    ) {
                        toggle(outcome)
                    }
                }
                .reorderable()
            }
            .reorderContainer(for: Outcome.self) { difference in
                withAnimation(.smooth) {
                    difference.apply(to: &brief.outcomes)
                }
            }
        }
    }

    private var briefForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: "Tell MJ about it",
                subtitle: "A few sentences in your own words. Skip anything you're not sure about."
            )
            BriefField(
                question: "What are you trying to accomplish?",
                hint: "e.g. Customers keep phoning to book, and I want them to do it themselves online.",
                text: $brief.goal
            )
            BriefField(
                question: "Who is it for?",
                hint: "e.g. Our 12 field technicians, or the public, or just me.",
                text: $brief.audience
            )
            BriefField(
                question: "Is there anything already in place?",
                hint: "e.g. An old website, a spreadsheet we live in, an app another developer started.",
                text: $brief.existing
            )
        }
    }

    private var practicalities: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Budget and timing",
                subtitle: "Rough answers are fine — they help MJ suggest the right size of solution."
            )
            ChoiceRow(title: "Budget", symbol: "banknote", selection: $brief.budget) { $0.label }
            ChoiceRow(title: "Timeline", symbol: "calendar", selection: $brief.timeline) { $0.label }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "How should MJ reply?")
            TextField("Your name", text: $brief.name)
                .textFieldStyle(.plain)
                .padding(14)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
            ChoiceRow(title: "Preferred contact", symbol: brief.contact.symbol, selection: $brief.contact) { $0.label }
            if brief.contact != .email {
                TextField("Phone number", text: $brief.phone)
                    .textFieldStyle(.plain)
                    .phoneKeyboard()
                    .padding(14)
                    .background(.thinMaterial, in: .rect(cornerRadius: 16))
            }
        }
    }

    private var sendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isReviewing = true
            } label: {
                Label("Review and send", systemImage: "paperplane.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            HStack {
                Text("You'll see exactly what MJ receives before anything is sent. Your draft is saved automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Start over", role: .destructive) { isConfirmingReset = true }
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private var processSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "What happens next")
            ProcessStep(
                number: 1,
                title: "Your request lands in MJ's inbox",
                detail: "It goes out as an ordinary email from your own address, so you can attach files or forward it to a colleague."
            )
            ProcessStep(
                number: 2,
                title: "MJ replies to talk it through",
                detail: "A short conversation to ask the questions that matter and make sure the goal is clear."
            )
            ProcessStep(
                number: 3,
                title: "You get a plan in plain language",
                detail: "What will be built, roughly how long it takes and what it costs — before any work starts."
            )
            ProcessStep(
                number: 4,
                title: "You own what gets built",
                detail: "Progress updates along the way, and the finished code, accounts and designs are yours."
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "MJ's recent work", subtitle: "Live from mjchaker.github.io")
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
                    .buttonStyle(.bordered)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: .rect(cornerRadius: 20))
            case .loaded(let loaded):
                let related = loaded.projects(relatedTo: brief.outcomes)
                if !related.isEmpty && related.count < loaded.projects.count {
                    Picker("Show", selection: $workFilter) {
                        ForEach(WorkFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                let shown = (workFilter == .related && !related.isEmpty) ? related : loaded.projects
                if shown.isEmpty {
                    Text("No projects are listed on the site right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(shown) { project in
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

    private var statusText: String {
        if let status = portfolio.loaded?.status, !status.isEmpty { return status }
        return "Open to new opportunities"
    }

    private var headlineText: String {
        if let headline = portfolio.loaded?.headline, !headline.isEmpty { return headline }
        return "Computer programmer with an ear for detail."
    }

    // MARK: Actions

    // Deliberately not animated: animating the glass tint in the same frame as
    // the interactive-glass press reaction re-enters the glass update cycle
    // ("glassEffect() tried to update multiple times per frame").
    private func toggle(_ outcome: Outcome) {
        if let index = brief.outcomes.firstIndex(of: outcome) {
            brief.outcomes.remove(at: index)
        } else {
            brief.outcomes.append(outcome)
        }
    }
}

#Preview {
    ContentView()
}
