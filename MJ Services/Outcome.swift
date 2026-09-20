import SwiftUI

// MARK: - Outcomes: what a client wants to end up with

/// Something a client wants to make happen, described in their words.
///
/// Clients rarely care whether the answer is Swift or Rails; they care whether
/// they end up with an app in the store, a chore that runs itself, or a bug
/// that finally goes away. The catalog is therefore organised by *outcome*,
/// and the technology MJ would reach for is tucked away in `underTheHood`
/// for the minority who want to know.
struct Outcome: Identifiable, Hashable {
    let id: String
    /// Plain-language name, e.g. "An app for iPhone, iPad or Mac".
    let name: String
    /// One sentence describing what the client gets.
    let promise: String
    /// Concrete situations a client will recognise themselves in.
    let examples: [String]
    /// A practical, factual note that helps someone budget or prepare.
    let goodToKnow: String?
    /// The tools and techniques MJ typically uses — for the curious only.
    let underTheHood: String
    let symbol: String
    let tint: Color
    /// Lower-case words that mark a portfolio project as related to this outcome.
    let portfolioKeywords: [String]
}

extension Outcome {
    static func find(_ id: String) -> Outcome? {
        catalog.first { $0.id == id }
    }

    static let catalog: [Outcome] = [
        Outcome(
            id: "app",
            name: "An app for iPhone, iPad, Mac or Vision Pro",
            promise: "Your idea, working smoothly on Apple devices and ready for the App Store.",
            examples: [
                "A customer-facing app for your business",
                "An internal tool your team uses every day",
                "An app that controls a smart-home device",
            ],
            goodToKnow: "Publishing on the App Store needs an Apple Developer account, which Apple charges US$99 a year for.",
            underTheHood: "Swift, SwiftUI, HomeKit & Matter",
            symbol: "iphone",
            tint: .blue,
            portfolioKeywords: ["ios", "swift", "iphone", "ipad", "mac", "apple", "homekit", "matter", "watchos", "visionos", "app"]
        ),
        Outcome(
            id: "website",
            name: "A website or web app",
            promise: "A site or online tool people can use from any browser, on any device.",
            examples: [
                "A site for your business, practice or portfolio",
                "An online store, booking page or sign-up flow",
                "A dashboard that shows your data at a glance",
            ],
            goodToKnow: "You'll want a domain name, usually US$10–20 a year. Hosting for a simple site is often free.",
            underTheHood: "Rails, React, Flask, WebGL",
            symbol: "globe",
            tint: .teal,
            portfolioKeywords: ["web", "rails", "react", "flask", "site", "html", "css", "javascript", "typescript", "webgl", "browser"]
        ),
        Outcome(
            id: "automation",
            name: "Automate something tedious",
            promise: "Turn a repetitive chore into something that runs itself.",
            examples: [
                "Move data between two tools without copy-pasting",
                "Generate reports or files on a schedule",
                "Clean up and combine messy spreadsheets",
            ],
            goodToKnow: "A list of the steps you do by hand today is the best possible starting point.",
            underTheHood: "Python, shell scripting, REST APIs",
            symbol: "wand.and.stars",
            tint: .green,
            portfolioKeywords: ["python", "script", "automation", "automate", "cli", "tool", "workflow"]
        ),
        Outcome(
            id: "fix",
            name: "Fix or finish an existing project",
            promise: "Get something that's broken, slow or half-done working again.",
            examples: [
                "A crash or bug nobody has managed to track down",
                "Code a previous developer left unfinished",
                "An app that needs updating for the latest OS",
            ],
            goodToKnow: "Access to the existing code and accounts makes this go much faster.",
            underTheHood: "Debugging, profiling, migrations — whatever the project is written in",
            symbol: "wrench.and.screwdriver",
            tint: .orange,
            portfolioKeywords: []
        ),
        Outcome(
            id: "ai",
            name: "Add AI to your product",
            promise: "A helpful assistant or smart feature inside what you already have.",
            examples: [
                "A chat assistant that knows your documents",
                "Smart search, summaries or suggestions",
                "An agent that carries out tasks on a user's behalf",
            ],
            goodToKnow: "AI features usually carry an ongoing usage cost from the model provider, separate from development.",
            underTheHood: "LLM tool-calling, MCP servers, agents",
            symbol: "sparkles",
            tint: .purple,
            portfolioKeywords: ["ai", "llm", "mcp", "agent", "claude", "gpt", "model", "assistant"]
        ),
        Outcome(
            id: "integration",
            name: "Connect two things together",
            promise: "Make the tools you already use talk to each other.",
            examples: [
                "Sync your store with your accounting software",
                "Send form submissions straight into your CRM",
                "Build a plugin or extension for a tool you rely on",
            ],
            goodToKnow: nil,
            underTheHood: "APIs, webhooks, plugins, Java, C#/.NET",
            symbol: "link",
            tint: .indigo,
            portfolioKeywords: ["api", "plugin", "integration", "java", "c#", ".net", "sync", "extension"]
        ),
        Outcome(
            id: "performance",
            name: "Make it faster or more reliable",
            promise: "Speed up software that feels slow, or stop it falling over.",
            examples: [
                "An app that lags, stutters or drains the battery",
                "A server that struggles when traffic picks up",
                "Software that has to run on new hardware",
            ],
            goodToKnow: nil,
            underTheHood: "C, C++, compilers, AArch64, profiling",
            symbol: "gauge.with.dots.needle.67percent",
            tint: .red,
            portfolioKeywords: ["c", "c++", "compiler", "performance", "systems", "aarch64", "arm", "assembly", "low-level", "kernel"]
        ),
        Outcome(
            id: "audio",
            name: "Something with sound or music",
            promise: "Tools, effects or apps that record, process or play audio.",
            examples: [
                "An audio effect or instrument plugin",
                "An app that analyses recordings",
                "Custom tooling for a studio or live show",
            ],
            goodToKnow: nil,
            underTheHood: "DSP, signal processing, audio frameworks",
            symbol: "waveform",
            tint: .pink,
            portfolioKeywords: ["audio", "dsp", "music", "sound", "synth", "vst", "au", "signal"]
        ),
        Outcome(
            id: "unsure",
            name: "Not sure yet — let's talk",
            promise: "Describe the problem in your own words and MJ will suggest a way forward.",
            examples: [
                "I have an idea but don't know where to start",
                "I want a second opinion before committing a budget",
            ],
            goodToKnow: "There's no wrong way to describe a problem. Everyday language is better than guessing at jargon.",
            underTheHood: "A short conversation, no jargon required",
            symbol: "bubble.left.and.bubble.right",
            tint: .gray,
            portfolioKeywords: []
        ),
    ]
}
