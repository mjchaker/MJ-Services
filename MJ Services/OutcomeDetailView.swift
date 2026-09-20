import SwiftUI

/// Everything a client might want to know about one outcome before picking it:
/// what they get, situations it fits, practical costs, and related past work.
struct OutcomeDetailView: View {
    let outcome: Outcome
    let relatedProjects: [PortfolioProject]
    let isSelected: Bool
    let toggle: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    examples
                    if let note = outcome.goodToKnow {
                        Callout(symbol: "lightbulb", text: note, tint: outcome.tint)
                    }
                    if !relatedProjects.isEmpty {
                        related
                    }
                    underTheHood
                    Button {
                        toggle()
                        dismiss()
                    } label: {
                        Label(isSelected ? "Remove from my request" : "Add to my request",
                              systemImage: isSelected ? "minus.circle" : "plus.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSelected ? .gray : outcome.tint)
                }
                .padding(20)
            }
            .navigationTitle(outcome.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: outcome.symbol)
                .font(.largeTitle)
                .foregroundStyle(outcome.tint)
                .frame(width: 44)
            Text(outcome.promise)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sounds like you if…")
                .font(.headline)
            ForEach(outcome.examples, id: \.self) { example in
                Label {
                    Text(example)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(outcome.tint)
                }
                .font(.subheadline)
            }
        }
    }

    private var related: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related work by MJ")
                .font(.headline)
            ForEach(relatedProjects) { project in
                ProjectCard(project: project)
            }
        }
    }

    private var underTheHood: some View {
        DisclosureGroup {
            Text(outcome.underTheHood)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        } label: {
            Label("How MJ usually builds this", systemImage: "gearshape.2")
                .font(.subheadline.weight(.medium))
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}
