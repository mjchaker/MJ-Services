import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Outcome chip

struct OutcomeChip: View {
    let outcome: Outcome
    let isSelected: Bool
    let toggle: () -> Void
    let showDetails: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: outcome.symbol)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(outcome.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(outcome.name)
                        .font(.subheadline.weight(.semibold))
                    Text(outcome.promise)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? outcome.tint : .secondary)
                    Button(action: showDetails) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("More about \(outcome.name)")
                }
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
        if isSelected {
            return .regular.tint(outcome.tint.opacity(0.45)).interactive()
        } else {
            return .regular.interactive()
        }
    }
}

// MARK: - Priority row

struct PriorityRow: View {
    let rank: Int
    let outcome: Outcome
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .frame(width: 28, height: 28)
                .background(outcome.tint.opacity(0.25), in: .circle)
            Image(systemName: outcome.symbol)
                .foregroundStyle(outcome.tint)
            Text(outcome.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Spacer()
            Button(action: remove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(outcome.name)")
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Brief question

struct BriefField: View {
    let question: String
    let hint: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline.weight(.semibold))
            TextField(hint, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...6)
                .padding(14)
                .background(.thinMaterial, in: .rect(cornerRadius: 16))
        }
    }
}

// MARK: - Choice row

/// A labelled row with a menu of choices, for questions a client can answer
/// without knowing anything technical (budget, timing, how to be contacted).
struct ChoiceRow<Choice: CaseIterable & Hashable & Identifiable>: View where Choice.AllCases: RandomAccessCollection {
    let title: String
    let symbol: String
    @Binding var selection: Choice
    let label: (Choice) -> String

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.medium))
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(Choice.allCases) { choice in
                    Text(label(choice)).tag(choice)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Process step

struct ProcessStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline.monospacedDigit())
                .frame(width: 28, height: 28)
                .background(.blue.opacity(0.2), in: .circle)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Callout

struct Callout: View {
    let symbol: String
    let text: String
    var tint: Color = .blue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Project card

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

// MARK: - Platform helpers

extension View {
    /// Shows the phone keypad where there is a software keyboard.
    @ViewBuilder
    func phoneKeyboard() -> some View {
        #if os(macOS)
        self
        #else
        self.keyboardType(.phonePad)
        #endif
    }
}

enum Clipboard {
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}
