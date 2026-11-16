# The Smallest Agent — SwiftUI + Node.js

Edition 21 is a **native iPhone, iPad and Mac application** backed by Node.js 24 + TypeScript and the real Claude Agent SDK. It includes five working native tabs, retained lab state, Stream/Simple modes, cancellation, copy/Markdown export, pastel cards, readable Dynamic Type, persistent theme/API settings, colored Swift/TypeScript/JSON/shell snippets, a native Canvas UML and 16 source-linked explanations.

The frontend is not a website and has no browser URL. Windows can run the backend; **building and running SwiftUI requires macOS with Xcode 16 or newer**. No XcodeGen, CocoaPods or third-party Swift UI packages are required. A shared Xcode project and scheme are included.

## Start Node on Windows

From **Lesson 0**, in PowerShell:

```powershell
cd .\21-smallest-agent-swiftui-node
npm ci
npm run setup
notepad backend\.env
```

Replace only the `ANTHROPIC_API_KEY` placeholder with your own key. Blank `CLAUDE_MODEL` uses the SDK default; a custom model must be available to your account. `AGENT_MAX_TURNS` accepts 1–10. Save and run:

```powershell
npm run dev
```

API health: **http://127.0.0.1:9600/api/health**. API reference: **http://127.0.0.1:9600/api/docs**. This browser page documents the backend; the application runs natively in SwiftUI. Ctrl+C stops Node. Restart after changing configuration.

Setup installs the backend's pinned npm dependencies, creates `backend/.env` only if absent, and regenerates lesson resources. It never copies keys from another edition. Environment variables override the module-relative file. No model call occurs during setup, tests or build.

```dotenv
ANTHROPIC_API_KEY=sk-ant-replace-with-your-key
CLAUDE_MODEL=
AGENT_SYSTEM_PROMPT=You are a concise teaching assistant.
AGENT_MAX_TURNS=1
API_HOST=127.0.0.1
API_PORT=9600
ALLOWED_ORIGINS=
```

Native URLSession calls have no browser Origin. `ALLOWED_ORIGINS` is an optional comma-separated list of exact origins for browser integrations; it defaults to none. CORS is not end-user authentication. This is a local teaching backend; use authenticated HTTPS access controls before remote exposure. Health reports key presence, not credits, provider authentication or model access.

## Open SwiftUI in Xcode

Copy this whole edition to a Mac, including generated `apple/SmallestAgent/Resources`; exclude node_modules, dist, .tools, DerivedData and private .env files. If running Node on that Mac, install Node.js 24 and run `npm ci`, `npm run setup`, configure your own key and `npm run dev` there.

In another macOS terminal, from this edition:

```bash
open apple/SmallestAgent.xcodeproj
```

Select the **SmallestAgent** scheme and **My Mac** or an installed **iOS 17+ Simulator**, then press Run (⌘R). macOS deployment target is 14.0. The Swift sources use Swift 5 language mode and Apple frameworks only. The app opens in a native window or Simulator, not a browser.

Open the gear button for **Connection and theme settings**. When Node runs on the same Mac, use `http://127.0.0.1:9600`. Simulator localhost points to the Mac. A physical device's localhost points to that device; it cannot reach your computer that way. If Node runs on Windows or another host, use a reachable server origin. Debug builds allow development HTTP; Release validates HTTPS and uses the default ATS policy.

To test another device over your private development network, set `API_HOST=0.0.0.0`, restart Node, allow inbound port9600 through the host firewall only on the intended private network, and enter the computer's reachable IP/hostname in the app. Do not use `0.0.0.0` as the client address. For remote access use your authenticated HTTPS ingress and its hostname. A physical iPhone/iPad also needs an Apple development signing team selected in Xcode, a unique bundle identifier and a trusted device. This project does not install/sign/distribute an IPA automatically.

The Apple app stores only its non-secret API origin and appearance preference in UserDefaults. **Never put ANTHROPIC_API_KEY into Swift, Info.plist, app assets, a mobile token or the app settings.** The API key stays on Node. A hard-coded shared token in a shipped native app cannot serve as a private server credential.

## Run checks

```powershell
npm run typecheck
npm test
npm run verify:project
npm run build
```

`npm run build` regenerates native lesson resources and builds Node; it does **not** compile SwiftUI. `npm start` runs the compiled backend after stopping development. With a placeholder key and Node running in a second terminal, `npm run verify:http` checks actual HTTP behavior without inference. `npm run verify:project` checks native source/resource references and generated excerpts; it is not a Swift compiler.

On macOS with Xcode's command-line tools selected:

```bash
sh scripts/verify-apple.sh
```

This runs the nine XCTest cases on macOS and builds for a generic iOS Simulator without device signing. Equivalent commands:

```bash
xcodebuild -project apple/SmallestAgent.xcodeproj -scheme SmallestAgent -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
xcodebuild -project apple/SmallestAgent.xcodeproj -scheme SmallestAgent -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

Use Xcode to run/sign on a device. No Apple build, Simulator, native screenshots or XCTest run can be performed from this Windows workspace; those checks remain to be run on a Mac. VERIFICATION.md records the actual local checks.

## Understand the implementation

- `apple/SmallestAgent/`: native UI, main-actor state model, URLSession API client, bounded SSE parser, attributed syntax highlighting and Canvas sequence diagram.
- `apple/SmallestAgentTests/`: native tests for UTF-8/CRLF/multiline SSE, oversized/truncated input, URL boundaries, final-result decoding and bundled workflow resources.
- `backend/src/`: real SDK execution, input validation, safe event projection, native HTTP transport and cancellation.
- `scripts/generate-lesson.mjs`: extracts actual Swift/TypeScript source markers and line numbers into 16 explanation cards plus SVG and PlantUML downloads. Build fails if a marker is missing. Regenerate before a native build after editing source.
- `BUILD-PROMPT.txt`: reusable creation prompt, also supplied as a separate prompt beside this edition.

Stream mode shows safe SDK messages, not guaranteed token deltas. Its parser requires a typed final result and done; non-success SDK results stay errors and missing cost stays unknown. Cancel closes the owned URLSession and propagates to Node and its SDK controller. Final-result processing continues even after the 500-row history cap. Native Markdown uses text, not HTML execution; fenced code is colored and unknown languages stay plain text. See DEPLOYMENT.md for hosting boundaries.

References: [Apple SwiftUI TabView](https://developer.apple.com/documentation/swiftui/tabview), [URLSession async bytes](https://developer.apple.com/documentation/foundation/urlsession/bytes(for:delegate:)), [Claude Agent SDK TypeScript](https://code.claude.com/docs/en/agent-sdk/typescript), [course design reference](https://github.com/luiscoco/Udemy-Claude-Agent-SDK-lesson01-app).

The astronaut is reused from the existing local course editions. No new asset license is claimed.
