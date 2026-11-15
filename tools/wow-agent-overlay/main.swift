// Murly: a floating gem button that opens a WoW-styled chat backed by the local `claude` CLI.
import Cocoa
import WebKit

let home = NSHomeDirectory()
let info = Bundle.main.infoDictionary ?? [:]
let repoDir = info["WoWAgentRepo"] as? String ?? FileManager.default.currentDirectoryPath
let wowDir = "/Applications/World of Warcraft/_forever_"

let shotsDir = NSTemporaryDirectory() + "murly"

/// Murly's instructions live in MURLY.md (copied into the app); placeholders get this machine's paths.
let systemPrompt: String = {
    try? FileManager.default.createDirectory(atPath: shotsDir, withIntermediateDirectories: true)
    let file = Bundle.main.url(forResource: "MURLY", withExtension: "md")
    let text = file.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "Your name is Murly, a World of Warcraft guide."
    return text.replacingOccurrences(of: "{{WOW}}", with: wowDir)
        .replacingOccurrences(of: "{{REPO}}", with: repoDir)
        .replacingOccurrences(of: "{{SHOTS}}", with: shotsDir)
}()

// Tools that run without a prompt; anything else is denied and reported in the chat.
let allowedTools = ["Read", "Glob", "Grep", "Edit", "Write", "WebSearch", "WebFetch", "Skill", "TodoWrite",
                    "Bash(agent-desktop:*)", "Bash(sips:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)",
                    "Bash(mkdir:*)", "Bash(ln:*)", "Bash(cp:*)", "Bash(mv:*)", "Bash(open:*)", "Bash(pgrep:*)",
                    "Bash(osascript:*)", "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
                    "Bash(lua:*)", "Bash(luac:*)"]

/// PATH from the user's interactive shell, so `claude` and nvm's `agent-desktop` resolve when launched from Finder.
func loginPath() -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/zsh")
    p.arguments = ["-lic", "echo __PATH__$PATH"]
    let out = Pipe()
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    try? p.run()
    p.waitUntilExit()
    let text = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let line = text.split(separator: "\n").last { $0.hasPrefix("__PATH__") }
    return line.map { String($0.dropFirst(8)) } ?? "\(home)/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
}

final class Claude {
    private var proc: Process?
    private var stdin: FileHandle?
    private let path = loginPath()
    var onLine: (String) -> Void = { _ in }

    func start() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["claude", "-p", "--input-format", "stream-json", "--output-format", "stream-json",
                       "--verbose", "--model", "claude-sonnet-5-5", "--permission-mode", "acceptEdits", "--add-dir", wowDir, "--add-dir", shotsDir,
                       "--append-system-prompt", systemPrompt, "--allowedTools"] + allowedTools
        p.currentDirectoryURL = URL(fileURLWithPath: repoDir)
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = path
        // Without an API key the CLI uses the logged-in Claude subscription.
        env.removeValue(forKey: "ANTHROPIC_API_KEY")
        env.removeValue(forKey: "ANTHROPIC_AUTH_TOKEN")
        p.environment = env
        let inPipe = Pipe(), outPipe = Pipe()
        p.standardInput = inPipe
        p.standardOutput = outPipe
        p.standardError = outPipe
        var buffer = Data()
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            buffer.append(h.availableData)
            while let nl = buffer.firstIndex(of: 0x0A) {
                let line = String(decoding: buffer[..<nl], as: UTF8.self)
                buffer.removeSubrange(...nl)
                if !line.isEmpty { DispatchQueue.main.async { self?.onLine(line) } }
            }
        }
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.onLine(#"{"type":"exited"}"#) }
        }
        do { try p.run() } catch {
            onLine(#"{"type":"exited","error":"claude not found in PATH"}"#)
            return
        }
        proc = p
        stdin = inPipe.fileHandleForWriting
    }

    func send(_ text: String) {
        if proc?.isRunning != true { start() }
        let msg: [String: Any] = ["type": "user", "message": ["role": "user", "content": text]]
        guard var data = try? JSONSerialization.data(withJSONObject: msg) else { return }
        data.append(0x0A)
        try? stdin?.write(contentsOf: data)
    }

    func reset() {
        proc?.terminationHandler = nil
        proc?.terminate()
        proc = nil
        start()
    }
}

/// Borderless panels refuse key focus by default; the chat needs typing.
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func makePanel(_ rect: NSRect) -> KeyPanel {
    let p = KeyPanel(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    p.level = .statusBar
    p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    p.isOpaque = false
    p.backgroundColor = .clear
    p.hasShadow = true
    p.hidesOnDeactivate = false
    return p
}

/// Round gem button: drag to move, click to toggle the chat.
final class GemView: NSView {
    var onClick: () -> Void = {}
    private var start = NSPoint.zero, moved = false

    override func draw(_ dirtyRect: NSRect) {
        // Minimap-button look: dark rim, bronze ring like the frame art, dark stone core with a yellow M.
        let r = bounds.insetBy(dx: 3, dy: 3)
        NSColor.black.setFill()
        NSBezierPath(ovalIn: r).fill()
        NSGradient(colors: [NSColor(red: 0.85, green: 0.62, blue: 0.25, alpha: 1),
                            NSColor(red: 0.42, green: 0.27, blue: 0.09, alpha: 1),
                            NSColor(red: 0.78, green: 0.55, blue: 0.2, alpha: 1)])?.draw(in: NSBezierPath(ovalIn: r.insetBy(dx: 1.5, dy: 1.5)), angle: -90)
        let core = NSBezierPath(ovalIn: r.insetBy(dx: 5, dy: 5))
        NSGradient(colors: [NSColor(red: 0.2, green: 0.17, blue: 0.12, alpha: 1),
                            NSColor(red: 0.04, green: 0.03, blue: 0.02, alpha: 1)])?.draw(in: core, relativeCenterPosition: NSPoint(x: -0.3, y: 0.4))
        let glyph = NSAttributedString(string: "M", attributes: [
            .font: NSFont(name: "Optima-Bold", size: r.height * 0.5) ?? NSFont.boldSystemFont(ofSize: r.height * 0.5),
            .foregroundColor: NSColor(red: 1, green: 0.82, blue: 0, alpha: 1)])
        let s = glyph.size()
        glyph.draw(at: NSPoint(x: bounds.midX - s.width / 2, y: bounds.midY - s.height / 2))
    }

    // The app is never active while playing, so the first click must count.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) { start = NSEvent.mouseLocation; moved = false }
    override func mouseDragged(with e: NSEvent) {
        let now = NSEvent.mouseLocation
        if abs(now.x - start.x) + abs(now.y - start.y) > 3 { moved = true }
        guard moved, let w = window else { return }
        w.setFrameOrigin(NSPoint(x: w.frame.origin.x + now.x - start.x, y: w.frame.origin.y + now.y - start.y))
        start = now
    }
    override func mouseUp(with e: NSEvent) { if !moved { onClick() } }
    override func rightMouseDown(with e: NSEvent) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Murly", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        NSMenu.popUpContextMenu(menu, with: e, for: self)
    }
}

final class App: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    let claude = Claude()
    var gem: KeyPanel!
    var chat: KeyPanel!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        gem = makePanel(NSRect(x: screen.maxX - 90, y: screen.minY + 120, width: 56, height: 56))
        gem.hasShadow = false
        let view = GemView(frame: NSRect(x: 0, y: 0, width: 56, height: 56))
        view.onClick = { [weak self] in self?.toggle() }
        gem.contentView = view
        gem.orderFrontRegardless()

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "host")
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 540), configuration: config)
        web.setValue(false, forKey: "drawsBackground")
        if let html = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        }
        chat = makePanel(web.frame)
        chat.contentView = web

        claude.onLine = { [weak self] line in
            self?.web.evaluateJavaScript("onClaude(\(Self.jsString(line)))")
        }
        claude.start()
    }

    static func jsString(_ s: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [s])
        return String(String(decoding: data, as: UTF8.self).dropFirst().dropLast())
    }

    func toggle() {
        if chat.isVisible { chat.orderOut(nil); return }
        // Open beside the gem, kept on screen.
        let g = gem.frame, size = chat.frame.size
        let vis = gem.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        var x = g.minX - size.width - 8
        if x < vis.minX { x = g.maxX + 8 }
        let y = min(max(g.maxY - size.height, vis.minY), vis.maxY - size.height)
        chat.setFrameOrigin(NSPoint(x: x, y: y))
        chat.makeKeyAndOrderFront(nil)
        web.evaluateJavaScript("focusInput()")
    }

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let body = m.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "send": claude.send(body["text"] as? String ?? "")
        case "reset": claude.reset()
        case "close": chat.orderOut(nil)
        case "quit": NSApp.terminate(nil)
        default: break
        }
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
