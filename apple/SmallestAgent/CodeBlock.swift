import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

enum Clipboard {
    static func copy(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
enum Syntax {
    static func color(_ source: String, language: String, dark: Bool) -> AttributedString {
        var result = AttributedString(source); result.foregroundColor = Color.primary
        let supported = ["swift", "typescript", "javascript", "json", "powershell", "bash", "ini", "xml"]
        guard supported.contains(language.lowercased()) else { return result }
        let pattern = #"(?m)(//[^\n]*|#[^\n]*)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|\b(import|struct|enum|class|let|var|func|async|await|throws|throw|try|guard|if|else|return|for|in|case|switch|private|public|export|const|function|yield|new|true|false|null|nil|do|catch|defer)\b|\b[0-9]+(?:\.[0-9]+)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        for match in regex.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
            guard let range = Range(match.range, in: source), let attributed = Range(range, in: result) else { continue }
            let stringColor = dark ? Color(red: 0.4, green: 0.85, blue: 0.6) : Color(red: 0.12, green: 0.42, blue: 0.28)
            let keywordColor = dark ? Color(red: 0.74, green: 0.66, blue: 1) : Color(red: 0.48, green: 0.36, blue: 0.86)
            result[attributed].foregroundColor = match.range(at: 1).location != NSNotFound ? Color.secondary : match.range(at: 2).location != NSNotFound ? stringColor : keywordColor
        }
        return result
    }
}
struct CodeBlock: View {
    let code: String
    var language = "swift"
    @State private var copied = false
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var codeSize = 18.0
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(language.uppercased()).font(.callout.bold()); Spacer(); Button(copied ? "Copied" : "Copy") { Clipboard.copy(code); copied = true } }
            ScrollView(.horizontal) { Text(Syntax.color(code, language: language, dark: scheme == .dark)).font(.system(size: codeSize, design: .monospaced)).textSelection(.enabled).fixedSize(horizontal: true, vertical: false).padding(.bottom, 8) }
        }.padding(18).background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
    }
}
struct AnswerView: View {
    let text: String
    var body: some View {
        let blocks = text.components(separatedBy: "```")
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                if index % 2 == 1 {
                    let parts = block.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    CodeBlock(code: parts.count > 1 ? String(parts[1]) : block, language: parts.count > 1 ? String(parts[0]).trimmingCharacters(in: .whitespaces) : "text")
                } else if !block.isEmpty {
                    Text((try? AttributedString(markdown: block, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(block)).textSelection(.enabled)
                }
            }
        }
    }
}
