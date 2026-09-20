import SwiftUI

/// Shows the client exactly what MJ will receive, then offers three ways to
/// get it there: the mail app, the share sheet, or the clipboard.
struct RequestReviewSheet: View {
    let brief: RequestBrief

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var copied = false
    @State private var mailUnavailable = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This is what MJ will read. Nothing is sent until you press Send in your mail app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if brief.needsPhoneNumber {
                        Callout(
                            symbol: "exclamationmark.triangle",
                            text: "You asked for a \(brief.contact.label.lowercased()) but haven't given a number. MJ will reply by email instead.",
                            tint: .orange
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("To: \(RequestBrief.recipient)")
                        Text("Subject: \(brief.subject)")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    Text(brief.body)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: .rect(cornerRadius: 20))

                    actions
                }
                .padding(20)
            }
            .navigationTitle("Review your request")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("No mail app found", isPresented: $mailUnavailable) {
                Button("Copy the request") { copyRequest() }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Copy or share the request instead, and send it to \(RequestBrief.recipient) however you like.")
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                sendByMail()
            } label: {
                Label("Open in Mail", systemImage: "envelope.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            HStack(spacing: 12) {
                ShareLink(item: brief.body, subject: Text(brief.subject)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    copyRequest()
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Text("Prefer another way? MJ's address is \(RequestBrief.recipient).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    private func sendByMail() {
        guard let url = brief.mailtoURL else {
            mailUnavailable = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                mailUnavailable = true
            }
        }
    }

    private func copyRequest() {
        Clipboard.copy("Subject: \(brief.subject)\n\n\(brief.body)")
        withAnimation { copied = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { copied = false }
        }
    }
}
