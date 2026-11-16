import SwiftUI

struct LearnView: View {
    let concepts = [
        ("One small agent, two runtimes", "SwiftUI owns the native interface. URLSession sends JSON and reads POST SSE. Node owns the real TypeScript Claude Agent SDK and its CLI process."),
        ("Private credentials", "The Anthropic API key stays in backend/.env. The Apple application stores only the API address and theme. A shipped native app cannot protect a hard-coded server secret."),
        ("Real streaming", "Stream mode shows safe SDK lifecycle, assistant and final-result events. Completion requires a typed final result and done. Reported cost remains unknown when the SDK omits it."),
        ("Bounded execution", "Node validates 32 KiB JSON and a trimmed 1–4000 character prompt. Runs have a 180-second deadline, bounded turns, disabled tools and fresh temporary work/home/config directories."),
        ("Cancel through every layer", "Cancel stops the owned URLSession operation. The closed HTTP connection aborts Node and its SDK controller. Lesson navigation keeps prompt and result state."),
        ("Native, readable output", "Large text, pastel cards, system accessibility, persistent theme and safe native Markdown. Code is rendered as attributed text with colored tokens; no generated HTML is executed.")]
    var body: some View {
        Page(title: "Small enough to understand. Real enough to explore.", subtitle: "Learn the responsibilities of each layer.") {
            ForEach(Array(concepts.enumerated()), id: \.offset) { index, item in LessonCard(tint: index % 2 == 0 ? .blue : .purple) { Text("0\(index + 1) / LEARN").font(.headline); Text(item.0).font(.title2.bold()); Text(item.1) } }
        }
    }
}
struct SetupView: View {
    let showSettings: () -> Void
    var body: some View {
        Page(title: "SwiftUI and Node. One small agent.", subtitle: "Run Node on Windows, macOS or Linux. Build the native app in Xcode on a Mac.") {
            LessonCard { Text("01 / Start the Node backend").font(.title2.bold()); CodeBlock(code: #"""
                cd .\21-smallest-agent-swiftui-node
                npm ci
                npm run setup
                notepad backend\.env
                """#, language: "powershell"); Text("Set your own ANTHROPIC_API_KEY in backend/.env. Keep CLAUDE_MODEL blank for the SDK default, then run:"); CodeBlock(code: "npm run dev", language: "powershell"); Text("API: http://127.0.0.1:9600 · API reference: /api/docs. Health reports key presence, not account access or credits.") }
            LessonCard(tint: .purple) { Text("02 / Build the Apple app").font(.title2.bold()); Text("On macOS, open apple/SmallestAgent.xcodeproj in Xcode 16 or newer. Select the SmallestAgent scheme and My Mac or an iOS 17+ Simulator, then Run. No npm frontend or browser UI is needed."); CodeBlock(code: "open apple/SmallestAgent.xcodeproj", language: "bash"); Text("For a physical iPhone/iPad, select your signing team and a reachable API server. Simulator localhost points to the Mac, not a Windows PC.") }
            LessonCard(tint: .green) { Text("03 / Connect the app").font(.title2.bold()); Button("Open connection settings", action: showSettings).buttonStyle(.borderedProminent); Text("Set the server origin only, with no /api path. Debug builds support local development HTTP; Release requires HTTPS. A remote API needs your HTTPS ingress and user access controls. Never put the Anthropic key in the app.") }
            LessonCard(tint: .orange) { Text("04 / Verify and build").font(.title2.bold()); CodeBlock(code: "npm run typecheck\nnpm test\nnpm run verify:project\nnpm run build\nnpm start", language: "powershell"); Text("Stop development before npm start. Run native XCTest with the shared Xcode scheme on macOS. README.md includes commands and device networking guidance.") }
        }
    }
}
struct StepCard: View {
    let step: WorkflowStep
    var body: some View {
        LessonCard(tint: step.number % 2 == 0 ? .purple : .blue) {
            Text("\(step.number). \(step.title)").font(.title2.bold()); Text(step.text)
            Text("\(step.source):\(step.line)").font(.callout.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
            CodeBlock(code: step.code, language: step.language)
            Text("How this code explains step \(step.number)").font(.headline); Text(step.explanation)
        }
    }
}
struct ArchitectureView: View {
    var body: some View {
        Page(title: "See how the pieces connect.", subtitle: "SwiftUI → URLSession → Node API → Claude Agent SDK → Claude API") {
            LessonCard { Text("From a click to a final answer").font(.title2.bold()); Text("Read downward. Scroll inside the diagram to inspect all six lifelines. Loop and alternative frames show streaming, completion, failure and missing configuration."); ScrollView(.horizontal) { WorkflowDiagram().frame(width: 1680, height: 1660) }.frame(height: 1660); HStack { if let url = Resources.url("workflow", "svg") { ShareLink("Share SVG", item: url) }; if let url = Resources.url("workflow", "puml") { ShareLink("Share PlantUML", item: url) } } }
            Text("Follow every UML arrow in the code").font(.title.bold())
            if Resources.steps.isEmpty { Text("Workflow resources are missing. Run npm run generate:lesson before building the app.").foregroundStyle(.red) }
            ForEach(Resources.steps) { StepCard(step: $0) }
        }
    }
}
struct WalkthroughView: View {
    var body: some View {
        Page(title: "One request. Every layer explained.", subtitle: "Colored excerpts generated from this edition’s actual Swift and TypeScript source.") {
            ForEach(Resources.steps.filter { [1, 2, 3, 5, 10, 12].contains($0.number) }) { StepCard(step: $0) }
        }
    }
}
