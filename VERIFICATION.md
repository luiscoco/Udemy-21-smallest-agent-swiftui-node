# Verification record

Verified on Windows for this edition:

- Node backend TypeScript typecheck and production compilation.
-20 backend tests with injected SDK iterators and actual HTTP transport: final-result mapping, environment isolation, errors, native calls, exact browser-origin allowlist, real progressive SSE/client disconnect and repeated oversized-body/keep-alive behavior.
- Live placeholder-key HTTP health, input/media/origin boundaries, missing-key query503 and SSE error without done, OpenAPI/docs/UML and unknown/secret-file404 behavior. No paid inference.
- Native project/resource checks: all ten Swift source/test files referenced, shared scheme, separate Debug/Release ATS files, five tabs and16 generated source snippets with valid file/line markers. The OpenStep Xcode object graph, plist files and scheme XML also parse successfully.
- All ten Swift files parsed without syntax errors using tree-sitter0.26.1 + tree-sitter-swift0.7.4. A syntax parser does not resolve SwiftUI types or replace Xcode compilation.
- Production npm dependency audit: zero reported vulnerabilities at verification time.

Not available on this Windows host: Xcode compiler/SDKs, native XCTest execution, Simulator/device UI interaction, release signing and Apple screenshots. Run `sh scripts/verify-apple.sh` on macOS and perform this native UI checklist before relying on a device build:

1. Open all five tabs and confirm the prompt, mode, answer and timeline survive navigation.
2. Test large Dynamic Type and narrow iPhone/iPad sizes; code and UML must scroll inside their own regions.
3. Save a reachable API origin, restart the app and verify theme/address persistence.
4. With a placeholder key, run Stream and Simple and confirm readable missing-key feedback and reusable controls.
5. With your working key, explicitly submit an intended real prompt and check safe lifecycle events, result metrics, cancellation and no false success after failed results.
6. Check all16 native UML/source cards, syntax colors in both themes, copy/export and SVG/PlantUML sharing.
7. Build Release against HTTPS, confirm HTTP origins are rejected and verify no provider key exists in the bundle.
