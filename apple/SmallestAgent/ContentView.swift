import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct LessonCard<Content: View>: View {
    var tint: Color = .blue
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 18) { content }.frame(maxWidth: .infinity, alignment: .leading).padding(24).background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(tint.opacity(0.18))) }
}
struct Page<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) { Text(title).font(.largeTitle.bold()); Text(subtitle).foregroundStyle(.secondary); content }.padding(24).frame(maxWidth: 1120).frame(maxWidth: .infinity) }
        .navigationTitle("The Smallest Agent")
    }
}
struct ContentView: View {
    @StateObject private var model = AgentModel()
    @AppStorage("agent21.server") private var server = "http://127.0.0.1:9600"
    @AppStorage("agent21.theme") private var theme = "system"
    @State private var settings = false
    @ScaledMetric(relativeTo: .body) private var bodySize = 21.0
    var body: some View {
        TabView {
            NavigationStack { LabView(model: model, server: server) }.tabItem { Label("Lab", systemImage: "sparkles") }
            NavigationStack { LearnView() }.tabItem { Label("Learn", systemImage: "book") }
            NavigationStack { SetupView(showSettings: { settings = true }) }.tabItem { Label("How to run", systemImage: "terminal") }
            NavigationStack { ArchitectureView() }.tabItem { Label("Workflow", systemImage: "arrow.triangle.branch") }
            NavigationStack { WalkthroughView() }.tabItem { Label("Code", systemImage: "curlybraces") }
        }.font(.system(size: bodySize)).tint(.blue)
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        .overlay(alignment: .topTrailing) { Button { settings = true } label: { Image(systemName: "gearshape.fill").padding(14).background(.regularMaterial, in: Circle()) }.buttonStyle(.plain).accessibilityLabel("Connection and theme settings").padding(8) }
        .sheet(isPresented: $settings) { SettingsView(server: $server, theme: $theme) }
        .task(id: server) { await model.checkHealth(server) }
        .onDisappear { model.cancel() }
        .environment(\.openURL, OpenURLAction { url in ["http", "https"].contains(url.scheme?.lowercased() ?? "") ? .systemAction : .discarded })
    }
}
struct SettingsView: View {
    @Binding var server: String
    @Binding var theme: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var error = ""
    var body: some View {
        NavigationStack { Form {
            Section("Node API address") {
                TextField("Server origin", text: $draft).autocorrectionDisabled()
                Text("Mac and iOS Simulator: localhost means your Mac. A physical device needs a reachable server address. The Anthropic key stays in backend/.env.").font(.callout).foregroundStyle(.secondary)
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
            }
            Section("Appearance") { Picker("Theme", selection: $theme) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") } }
            Button("Save connection") { do { _ = try APIClient.validatedURL(draft); server = draft.trimmingCharacters(in: .whitespacesAndNewlines); dismiss() } catch { self.error = error.localizedDescription } }
        }.navigationTitle("Settings").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } } }.frame(minWidth: 300, minHeight: 360).onAppear { draft = server }
    }
}
struct MarkdownDocument: FileDocument {
    static let markdown = UTType(filenameExtension: "md") ?? .plainText
    static var readableContentTypes: [UTType] { [markdown, .plainText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? "" }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
struct LabView: View {
    @ObservedObject var model: AgentModel
    let server: String
    @State private var exporting = false
    var body: some View {
        Page(title: "Your first agent. A real native application.", subtitle: "SwiftUI + Node.js · Claude Agent SDK") {
            LessonCard(tint: .purple) {
                HStack(alignment: .top) { VStack(alignment: .leading, spacing: 12) { Text("Small enough to understand.").font(.title2.bold()); Text("Ask a question. Follow the SDK messages. Learn every step.") }; Spacer(); if let url = Resources.url("astronaut", "png"), let data = try? Data(contentsOf: url) { CourseImage(data: data).frame(width: 110, height: 140) } }
                Label(model.health == nil ? "Backend offline" : "Backend connected", systemImage: model.health == nil ? "wifi.exclamationmark" : "checkmark.circle.fill").foregroundStyle(model.health == nil ? Color.orange : Color.green)
                if model.health?.apiKeyConfigured == false { Text("API key not configured. Set ANTHROPIC_API_KEY in backend/.env and restart Node.").foregroundStyle(.orange) }
            }
            LessonCard {
                Text("01 / PROMPT").font(.headline).foregroundStyle(.blue)
                Text("Give your agent a prompt").font(.title2.bold())
                TextEditor(text: $model.prompt).frame(minHeight: 150).padding(10).background(.background, in: RoundedRectangle(cornerRadius: 12)).disabled(model.running).accessibilityLabel("What would you like to ask?")
                Text("\(model.prompt.utf16.count)/4000 characters").font(.callout).foregroundStyle(.secondary)
                ForEach(["Hello world!", "Explain what an AI agent is in one sentence.", "What is SwiftUI?"], id: \.self) { text in Button(text) { model.prompt = text }.disabled(model.running).buttonStyle(.bordered) }
                Picker("Response mode", selection: $model.streaming) { Text("Stream").tag(true); Text("Simple").tag(false) }.pickerStyle(.segmented).disabled(model.running)
                HStack { Button(model.running ? "Running…" : "Run agent ↗") { model.run(server) }.buttonStyle(.borderedProminent).disabled(model.running || model.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.prompt.utf16.count > 4000).keyboardShortcut(.return, modifiers: .command)
                    if model.running { ProgressView(); Button("Cancel") { model.cancel() } }
                }
                Text("Command + Return · Real requests may use API credits.").font(.callout).foregroundStyle(.secondary)
            }
            LessonCard(tint: .green) {
                Text("02 / OUTPUT").font(.headline).foregroundStyle(.blue)
                HStack { Text("Agent’s answer").font(.title2.bold()); Spacer(); Text(model.phase).font(.callout.bold()) }
                if model.running { Text("Working · \(model.elapsed) ms").accessibilityLabel("Agent is working") }
                if !model.notice.isEmpty { HStack(alignment: .top) { Text(model.notice).foregroundStyle(model.phase == "error" ? Color.red : Color.secondary); Spacer(); Button("Dismiss") { model.notice = "" } } }
                if model.result != nil || !model.partial.isEmpty { AnswerView(text: model.result?.result ?? model.partial) }
                else if !model.running { Text("Your next discovery starts with a question. No sample answer is preloaded.").foregroundStyle(.secondary) }
                if let result = model.result {
                    Text("\(result.numTurns) turns · \(Int(result.durationMs)) ms · \(result.totalCostUsd.map { String(format: "$%.6f", $0) } ?? "Cost not reported")").font(.callout)
                    HStack { Button("Copy answer") { Clipboard.copy(result.result); model.notice = "Answer copied." }; Button("Export Markdown") { exporting = true } }
                }
            }
            LessonCard(tint: .orange) {
                Text("Inside the agent").font(.title2.bold()); Text("\(model.messages.count) events · selected SDK messages, not guaranteed token deltas").font(.callout).foregroundStyle(.secondary)
                if model.messages.isEmpty { Text(model.streaming ? "Run a prompt to watch the real message lifecycle." : "Simple mode returns the final result. Switch to Stream for the timeline.") }
                ForEach(model.messages) { row in DisclosureGroup("\(row.message.type) · +\(row.elapsed) ms") { Text(row.message.summary); CodeBlock(code: row.message.data.pretty, language: "json") } }
            }
        }.fileExporter(isPresented: $exporting, document: MarkdownDocument(text: model.result?.result ?? ""), contentType: MarkdownDocument.markdown, defaultFilename: "claude-answer") { result in
            switch result { case .success: model.notice = "Markdown exported."; case .failure(let error): model.notice = error.localizedDescription }
        }
    }
}
struct CourseImage: View {
    let data: Data
    var body: some View {
        #if os(iOS)
        if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Waving course astronaut") }
        #else
        if let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFit().accessibilityLabel("Waving course astronaut") }
        #endif
    }
}
