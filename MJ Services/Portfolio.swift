import SwiftUI

// MARK: - Portfolio data fetched from mjchaker.github.io

struct PortfolioProject: Identifiable {
    let id = UUID()
    let icon: String
    let category: String
    let title: String
    let summary: String
    let tags: [String]

    /// True when the project's category, title or tags mention any of the words.
    func matches(anyOf keywords: [String]) -> Bool {
        guard !keywords.isEmpty else { return false }
        let texts = ([category, title] + tags).map { $0.lowercased() }
        let separators: Set<Character> = [" ", "/", ",", "&", "(", ")", ":", ";"]
        let words = Set(texts.flatMap { $0.split { separators.contains($0) }.map(String.init) })
        return keywords.contains { keyword in
            // Short keywords like "c" must match a whole word; longer ones may
            // appear inside a word ("automation" in "automations").
            words.contains(keyword) || (keyword.count > 3 && texts.contains { $0.contains(keyword) })
        }
    }
}

struct Portfolio {
    var headline: String
    var status: String
    var skills: [String]
    var projects: [PortfolioProject]

    /// Projects related to the given outcomes, in site order.
    /// Empty when nothing matches, so the caller can fall back to everything.
    func projects(relatedTo outcomes: [Outcome]) -> [PortfolioProject] {
        let keywords = outcomes.flatMap(\.portfolioKeywords)
        guard !keywords.isEmpty else { return [] }
        return projects.filter { $0.matches(anyOf: keywords) }
    }
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

    var loaded: Portfolio? {
        if case .loaded(let portfolio) = phase { return portfolio }
        return nil
    }

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
