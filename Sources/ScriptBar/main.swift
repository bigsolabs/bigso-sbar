import AppKit
import Foundation

struct ScriptAction: Decodable, Identifiable {
    let id: String
    let name: String
    let executable: String
    let arguments: [String]
    let workingDirectory: String
    let environment: [String: String]

    private enum CodingKeys: String, CodingKey {
        case id, name, executable, arguments, workingDirectory, environment
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        id = try values.decodeIfPresent(String.self, forKey: .id) ?? name
        executable = try values.decode(String.self, forKey: .executable)
        arguments = try values.decodeIfPresent([String].self, forKey: .arguments) ?? []
        workingDirectory = try values.decodeIfPresent(String.self, forKey: .workingDirectory) ?? "."
        environment = try values.decodeIfPresent([String: String].self, forKey: .environment) ?? [:]
    }
}

struct LauncherConfiguration: Decodable {
    let baseDirectory: String
    let scripts: [ScriptAction]
}

struct RunningAction {
    let process: Process
    let logURL: URL
}

@main
final class ScriptBarApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var configuration = LauncherConfiguration(baseDirectory: "~/BIGSO/beta-lab", scripts: [])
    private var running: [String: RunningAction] = [:]
    private var loginPath: String?

    private var supportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ScriptBar", isDirectory: true)
    }

    private var configurationURL: URL {
        supportDirectory.appendingPathComponent("scripts.json")
    }

    private var logsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/ScriptBar", isDirectory: true)
    }

    static func main() {
        let application = NSApplication.shared
        let delegate = ScriptBarApp()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        loginPath = shellPath()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⏵"
        statusItem.button?.toolTip = "ScriptBar · lanzar scripts"
        loadConfiguration(openNewFile: true)
        rebuildMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        running.values.forEach { $0.process.terminate() }
    }

    private func loadConfiguration(openNewFile: Bool = false) {
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: configurationURL.path) {
                let starter = """
                {
                  "baseDirectory": "~/BIGSO/beta-lab",
                  "scripts": []
                }

                """
                try Data(starter.utf8).write(to: configurationURL, options: .atomic)
                configuration = LauncherConfiguration(baseDirectory: "~/BIGSO/beta-lab", scripts: [])
                if openNewFile { NSWorkspace.shared.open(configurationURL) }
            } else {
                let data = try Data(contentsOf: configurationURL)
                configuration = try JSONDecoder().decode(LauncherConfiguration.self, from: data)
                let ids = configuration.scripts.map(\.id)
                guard Set(ids).count == ids.count else {
                    throw LauncherError.configuration("Cada script necesita un id único.")
                }
            }
        } catch {
            showError("No pude cargar la configuración", detail: error.localizedDescription)
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let scripts = configuration.scripts

        if scripts.isEmpty {
            let empty = NSMenuItem(title: "No hay scripts configurados", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for script in scripts {
                let isRunning = running[script.id] != nil
                let title = isRunning ? "■  Detener · \(script.name)" : "▶  \(script.name)"
                let item = NSMenuItem(title: title, action: #selector(runOrStop(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = script.id
                item.toolTip = "\(script.executable) \(script.arguments.joined(separator: " "))"
                menu.addItem(item)
            }
        }

        if !running.isEmpty {
            let status = NSMenuItem(title: "\(running.count) proceso(s) activo(s)", action: nil, keyEquivalent: "")
            status.isEnabled = false
            menu.addItem(status)
        }

        menu.addItem(.separator())
        let stopAll = NSMenuItem(title: "Detener todos", action: #selector(stopAllScripts), keyEquivalent: "")
        stopAll.target = self
        stopAll.isEnabled = !running.isEmpty
        menu.addItem(stopAll)

        let reload = NSMenuItem(title: "Recargar scripts", action: #selector(reloadScripts), keyEquivalent: "")
        reload.target = self
        menu.addItem(reload)

        let edit = NSMenuItem(title: "Editar scripts…", action: #selector(openConfiguration), keyEquivalent: "")
        edit.target = self
        menu.addItem(edit)

        let logs = NSMenuItem(title: "Abrir registros", action: #selector(openLogs), keyEquivalent: "")
        logs.target = self
        menu.addItem(logs)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Salir de ScriptBar", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.title = running.isEmpty ? "⏵" : "⏵ \(running.count)"
    }

    @objc private func runOrStop(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let script = configuration.scripts.first(where: { $0.id == id }) else { return }
        if let active = running[id] {
            active.process.terminate()
            return
        }
        do {
            try launch(script)
        } catch {
            showError("No pude iniciar \(script.name)", detail: error.localizedDescription)
        }
        rebuildMenu()
    }

    private func launch(_ script: ScriptAction) throws {
        let base = expandPath(configuration.baseDirectory)
        let requestedDirectory = expandPath(script.workingDirectory)
        let directory = requestedDirectory.hasPrefix("/")
            ? requestedDirectory
            : URL(fileURLWithPath: base, isDirectory: true).appendingPathComponent(requestedDirectory).standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw LauncherError.launch("La carpeta de trabajo no existe: \(directory)")
        }

        let executable = try resolveExecutable(script.executable, workingDirectory: directory)
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        let safeID = script.id.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        let logURL = logsDirectory.appendingPathComponent("\(safeID).log")
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        let output = try FileHandle(forWritingTo: logURL)
        try output.seekToEnd()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = script.arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory, isDirectory: true)
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = loginPath ?? environment["PATH"]
        for (key, value) in script.environment { environment[key] = value }
        process.environment = environment
        process.standardOutput = output
        process.standardError = output
        process.terminationHandler = { [weak self] finished in
            try? output.close()
            DispatchQueue.main.async {
                guard let self,
                      let active = self.running[script.id], active.process === finished else { return }
                self.running.removeValue(forKey: script.id)
                self.rebuildMenu()
            }
        }
        try process.run()
        running[script.id] = RunningAction(process: process, logURL: logURL)
        rebuildMenu()
    }

    private func resolveExecutable(_ requested: String, workingDirectory: String) throws -> String {
        let expanded = expandPath(requested)
        if expanded.contains("/") {
            let candidate = expanded.hasPrefix("/")
                ? expanded
                : URL(fileURLWithPath: workingDirectory, isDirectory: true).appendingPathComponent(expanded).standardizedFileURL.path
            guard FileManager.default.isExecutableFile(atPath: candidate) else {
                throw LauncherError.launch("No encuentro un ejecutable en \(candidate)")
            }
            return candidate
        }

        let path = loginPath ?? ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"
        for folder in path.split(separator: ":").map(String.init) {
            let candidate = URL(fileURLWithPath: folder, isDirectory: true).appendingPathComponent(expanded).path
            if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
        }
        throw LauncherError.launch("No encuentro `\(requested)` en el PATH de tu shell. Puedes poner la ruta absoluta en scripts.json.")
    }

    private func expandPath(_ value: String) -> String {
        let expanded = (value as NSString).expandingTildeInPath
        if expanded.hasPrefix("/") { return URL(fileURLWithPath: expanded).standardizedFileURL.path }
        return expanded
    }

    private func shellPath() -> String? {
        let probe = Process()
        let output = Pipe()
        probe.executableURL = URL(fileURLWithPath: "/bin/zsh")
        probe.arguments = ["-lc", "print -r -- $PATH"]
        probe.standardOutput = output
        probe.standardError = FileHandle.nullDevice
        do {
            try probe.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            probe.waitUntilExit()
            guard probe.terminationStatus == 0 else { return nil }
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func showError(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func reloadScripts() {
        loadConfiguration()
        rebuildMenu()
    }

    @objc private func openConfiguration() {
        do {
            try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: configurationURL.path) { loadConfiguration() }
            NSWorkspace.shared.open(configurationURL)
        } catch {
            showError("No pude abrir scripts.json", detail: error.localizedDescription)
        }
    }

    @objc private func openLogs() {
        do {
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(logsDirectory)
        } catch {
            showError("No pude abrir los registros", detail: error.localizedDescription)
        }
    }

    @objc private func stopAllScripts() {
        running.values.forEach { $0.process.terminate() }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

enum LauncherError: LocalizedError {
    case configuration(String)
    case launch(String)

    var errorDescription: String? {
        switch self {
        case .configuration(let message), .launch(let message): message
        }
    }
}
