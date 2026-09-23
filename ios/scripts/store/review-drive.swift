import AppKit
import ApplicationServices

// A puppeteer for one app: real cursor, real clicks, and the app's own
// accessibility tree to find controls by what they say.
//
// It refuses to click anywhere but inside the window it was pointed at, with
// that app in front, and it gives up if the cursor has moved since it last put
// it somewhere — which means a person has taken the mouse back. A take that
// stops is a take to reshoot; a click that lands in somebody's browser is not.

let args = Array(CommandLine.arguments.dropFirst())
let env = ProcessInfo.processInfo.environment
let state = URL(fileURLWithPath: env["DRIVE_STATE"] ?? "/tmp/drive-state")
func die(_ s: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(code)
}

// MARK: - Which app

func targetApp() -> NSRunningApplication {
    if env["TARGET"] == "finder" {
        guard let f = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first
        else { die("no Finder") }
        return f
    }
    let path = env["APP_PATH"] ?? ""
    guard let app = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier == "com.arte-soft.brasspawn"
            && (path.isEmpty || ($0.bundleURL?.path.hasPrefix(path) ?? false))
    }) else { die("app not running") }
    return app
}

func attr(_ e: AXUIElement, _ name: String) -> AnyObject? {
    var v: AnyObject?
    return AXUIElementCopyAttributeValue(e, name as CFString, &v) == .success ? v : nil
}
func str(_ e: AXUIElement, _ name: String) -> String { (attr(e, name) as? String) ?? "" }
func frame(_ e: AXUIElement) -> CGRect? {
    guard let p = attr(e, kAXPositionAttribute), let s = attr(e, kAXSizeAttribute) else { return nil }
    var pt = CGPoint.zero, sz = CGSize.zero
    AXValueGetValue(p as! AXValue, .cgPoint, &pt)
    AXValueGetValue(s as! AXValue, .cgSize, &sz)
    return CGRect(origin: pt, size: sz)
}
func label(_ e: AXUIElement) -> String {
    [str(e, kAXTitleAttribute), str(e, kAXDescriptionAttribute), str(e, kAXValueAttribute),
     str(e, kAXFilenameAttribute)].filter { !$0.isEmpty }.joined(separator: " | ")
}
func walk(_ e: AXUIElement, depth: Int = 0, max: Int = 60, _ visit: (AXUIElement) -> Void) {
    guard depth <= max else { return }
    visit(e)
    for c in (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] { walk(c, depth: depth + 1, max: max, visit) }
}
func axApp() -> AXUIElement {
    let a = AXUIElementCreateApplication(targetApp().processIdentifier)
    AXUIElementSetMessagingTimeout(a, 2)
    return a
}
func mainWindow() -> AXUIElement? {
    let windows = (attr(axApp(), kAXWindowsAttribute) as? [AXUIElement]) ?? []
    if let title = env["WINDOW_TITLE"] { return windows.first { str($0, kAXTitleAttribute) == title } }
    return windows.first
}
/// Elements whose label contains `needle`, in tree order, with their frames.
func matches(_ needle: String, role: String? = nil) -> [(AXUIElement, CGRect)] {
    guard let w = mainWindow() else { return [] }
    var hits: [(AXUIElement, CGRect)] = []
    let n = needle.lowercased()
    walk(w) { e in
        if let role, str(e, kAXRoleAttribute) != role { return }
        // EXACT=1: one of the label's parts must be the needle, case and all —
        // the menu's "Play" and the mode tab's "play" are both in the tree
        // while the menu is up, and only one of them is under the cursor.
        let hit = env["EXACT"] == "1"
            ? [str(e, kAXTitleAttribute), str(e, kAXDescriptionAttribute), str(e, kAXValueAttribute)]
                .contains(needle)
            : label(e).lowercased().contains(n)
        // MAXW: skip anything wider than this — in Finder the window is titled
        // with the folder's name, which is also the app's, and it comes first.
        let widest = Double(env["MAXW"] ?? "") ?? .infinity
        if hit, let f = frame(e), f.width > 1, f.height > 1, Double(f.width) <= widest { hits.append((e, f)) }
    }
    return hits
}

// MARK: - Input, with the guard rails

let source = CGEventSource(stateID: .combinedSessionState)
func cursor() -> CGPoint { CGEvent(source: nil)!.location }

/// Where this tool last left the cursor. Anything else means a hand on the mouse.
func remember(_ p: CGPoint) { try? "\(p.x) \(p.y)".write(to: state, atomically: true, encoding: .utf8) }
func handsOff() {
    guard let s = try? String(contentsOf: state, encoding: .utf8) else { return }
    let v = s.split(separator: " ").compactMap { Double($0) }
    guard v.count == 2 else { return }
    let c = cursor()
    if abs(c.x - v[0]) > 3 || abs(c.y - v[1]) > 3 { die("ABORT: the cursor was moved by someone", code: 3) }
}
func mustBeInside(_ p: CGPoint) {
    let app = targetApp()
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    else { die("ABORT: \(app.localizedName ?? "target") is not in front", code: 4) }
    guard let w = mainWindow(), let f = frame(w), f.insetBy(dx: 2, dy: 2).contains(p)
    else { die("ABORT: \(p) is outside the window", code: 5) }
}

func post(_ t: CGEventType, _ p: CGPoint, clicks: Int64 = 1) {
    let e = CGEvent(mouseEventSource: source, mouseType: t, mouseCursorPosition: p, mouseButton: .left)!
    e.setIntegerValueField(.mouseEventClickState, value: clicks)
    e.post(tap: .cghidEventTap)
}
/// Glide rather than jump: a cursor that teleports reads as a recording that
/// skipped, and a viewer loses where the click is about to land.
func glide(to target: CGPoint, duration: Double = 0.6) {
    handsOff()
    let start = cursor()
    let steps = max(14, Int(duration * 90))
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        let k = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        post(.mouseMoved, CGPoint(x: start.x + (target.x - start.x) * k, y: start.y + (target.y - start.y) * k))
        usleep(useconds_t(duration / Double(steps) * 1_000_000))
    }
    remember(target)
}
func click(_ p: CGPoint, clicks: Int64 = 1) {
    mustBeInside(p)
    glide(to: p)
    usleep(180_000)
    mustBeInside(p)
    for n in 1...clicks {
        post(.leftMouseDown, p, clicks: n); usleep(80_000)
        post(.leftMouseUp, p, clicks: n); usleep(100_000)
    }
    remember(p)
}

// MARK: - Commands

guard let cmd = args.first else { die("usage") }
switch cmd {
case "dump":
    guard let w = mainWindow() else { die("no window") }
    walk(w) { e in
        let l = label(e)
        if let f = frame(e), !l.isEmpty { print(str(e, kAXRoleAttribute), "«\(l)»", Int(f.midX), Int(f.midY)) }
    }
case "find":
    let hits = matches(args[1], role: env["ROLE"])
    let nth = args.count > 2 ? Int(args[2])! : 0
    guard nth < hits.count else { die("not found: \(args[1])", code: 2) }
    print(Int(hits[nth].1.midX), Int(hits[nth].1.midY))
case "has":
    exit(matches(args[1], role: env["ROLE"]).isEmpty ? 1 : 0)
case "tap", "dtap":
    // tap <label> [nth] — click the centre of the nth control whose label contains it.
    let hits = matches(args[1], role: env["ROLE"] ?? (cmd == "tap" ? "AXButton" : nil))
    let nth = args.count > 2 ? Int(args[2])! : 0
    guard nth < hits.count else { die("not found: \(args[1])", code: 2) }
    // DY: aim above or below the label — in Finder the name is labelled and
    // the icon above it is not, and it is the icon a person double-clicks.
    let dy = Double(env["DY"] ?? "") ?? 0
    click(CGPoint(x: hits[nth].1.midX, y: hits[nth].1.midY + dy), clicks: cmd == "dtap" ? 2 : 1)
case "waitfor":
    // waitfor <label> <seconds> — until some element's label contains it.
    let deadline = Date().addingTimeInterval(Double(args[2])!)
    while Date() < deadline {
        if !matches(args[1]).isEmpty { exit(0) }
        usleep(250_000)
    }
    die("timed out waiting for \(args[1])", code: 6)
case "reveal":
    // reveal <label> <x> <y> — scroll at (x, y), gently, until the label is on screen.
    guard let w = mainWindow(), let wf = frame(w) else { die("no window") }
    let at = CGPoint(x: Double(args[2])!, y: Double(args[3])!)
    mustBeInside(at)
    glide(to: at)
    for _ in 0..<120 {
        if let f = matches(args[1]).first?.1, f.maxY < wf.maxY - 40, f.minY > wf.minY + 60 { exit(0) }
        handsOff()
        CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1, wheel1: -14, wheel2: 0, wheel3: 0)!
            .post(tap: .cghidEventTap)
        usleep(22_000)
    }
    die("never came into view: \(args[1])", code: 7)
case "scroll":
    // scroll <x> <y> <pixels> — a gentle scroll by roughly that much, negative is down.
    let at = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
    mustBeInside(at); glide(to: at)
    let total = Int(args[3])!, step = total < 0 ? -14 : 14
    for _ in 0..<(abs(total) / 14) {
        handsOff()
        CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1, wheel1: Int32(step), wheel2: 0, wheel3: 0)!
            .post(tap: .cghidEventTap)
        usleep(22_000)
    }
case "click":  click(CGPoint(x: Double(args[1])!, y: Double(args[2])!))
case "move":   glide(to: CGPoint(x: Double(args[1])!, y: Double(args[2])!), duration: args.count > 3 ? Double(args[3])! : 0.6)
case "park":   // put the cursor somewhere without the hands-off check, and remember it
    let p = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
    post(.mouseMoved, p); remember(p)
case "press":
    let hits = matches(args[1], role: "AXButton")
    let nth = args.count > 2 ? Int(args[2])! : 0
    guard nth < hits.count else { die("no button: \(args[1])", code: 2) }
    print(AXUIElementPerformAction(hits[nth].0, kAXPressAction as CFString) == .success ? "pressed" : "press failed")
case "win":
    guard let w = mainWindow() else { die("no window") }
    var p = CGPoint(x: Double(args[1])!, y: Double(args[2])!)
    var s = CGSize(width: Double(args[3])!, height: Double(args[4])!)
    AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &s)!)
    AXUIElementSetAttributeValue(w, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &p)!)
    AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &s)!)
    if let f = frame(w) { print(Int(f.minX), Int(f.minY), Int(f.width), Int(f.height)) }
case "winget":
    guard let w = mainWindow(), let f = frame(w) else { die("no window", code: 2) }
    print(Int(f.minX), Int(f.minY), Int(f.width), Int(f.height))
case "key":
    // key <keycode> [cmd] — only into the target app, and only if it is in front.
    let app = targetApp()
    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    else { die("ABORT: \(app.localizedName ?? "target") is not in front for a key", code: 4) }
    let code = CGKeyCode(Int(args[1])!)
    let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true)!
    let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)!
    if args.count > 2, args[2] == "cmd" { down.flags = .maskCommand; up.flags = .maskCommand }
    down.post(tap: .cghidEventTap); usleep(60_000); up.post(tap: .cghidEventTap)
case "running":
    exit(NSWorkspace.shared.runningApplications.contains {
        $0.bundleIdentifier == "com.arte-soft.brasspawn"
            && ($0.bundleURL?.path.hasPrefix(env["APP_PATH"] ?? "") ?? false)
    } ? 0 : 1)
case "front":
    print(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?")
case "raise":
    targetApp().activate()
    if let w = mainWindow() { AXUIElementPerformAction(w, kAXRaiseAction as CFString) }
case "quit":
    // A proper quit, so the window's geometry is written for the next launch.
    targetApp().terminate()
case "idle":
    // Seconds since the last keyboard or mouse input from anyone.
    let io = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
    var props: Unmanaged<CFMutableDictionary>?
    IORegistryEntryCreateCFProperties(io, &props, kCFAllocatorDefault, 0)
    let ns = ((props?.takeRetainedValue() as NSDictionary?)?["HIDIdleTime"] as? NSNumber)?.uint64Value ?? 0
    print(ns / 1_000_000_000)
default: die("unknown command \(cmd)")
}
