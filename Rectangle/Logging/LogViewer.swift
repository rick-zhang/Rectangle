//
//  LogViewer.swift
//  Multitouch
//
//  Created by Ryan Hanson on 8/6/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class Logger {
    
    static var logging = false
    
    static private var logWindowController: LogWindowController?
    static private let diagnosticLogURL = URL(fileURLWithPath: "/private/tmp/rectangle-display-move.log")
#if DEBUG
    static var diagnosticsEnabled = false
#endif
    
    static func showLogging(sender: Any?) {
        if logWindowController == nil {
            logWindowController = LogWindowController.freshController()
        }
        NSApp.activate(ignoringOtherApps: true)
        logWindowController?.showWindow(sender)
        logging = true
    }
    
    static func log(_ string: String) {
        if logging {
            logWindowController?.append(string)
        }
    }

    static func diagnostic(_ string: String) {
        if logging {
            logWindowController?.append(string)
        }
#if DEBUG
        guard diagnosticsEnabled else { return }
        let line = "\(datestamp()): \(string)\n"
        let data = Data(line.utf8)
        if FileManager.default.fileExists(atPath: diagnosticLogURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: diagnosticLogURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: diagnosticLogURL.path, contents: data)
        }
#endif
    }

#if DEBUG
    static var diagnosticLogPath: String {
        diagnosticLogURL.path
    }

    static func clearDiagnosticLog() {
        try? "".write(to: diagnosticLogURL, atomically: true, encoding: .utf8)
    }

    static func openDiagnosticLog() {
        if !FileManager.default.fileExists(atPath: diagnosticLogURL.path) {
            FileManager.default.createFile(atPath: diagnosticLogURL.path, contents: nil)
        }
        NSWorkspace.shared.open(diagnosticLogURL)
    }

    @discardableResult
    static func toggleDiagnostics() -> Bool {
        diagnosticsEnabled.toggle()
        if diagnosticsEnabled {
            clearDiagnosticLog()
            diagnostic("Rectangle debug diagnostics started, logPath: \(diagnosticLogPath)")
        }
        return diagnosticsEnabled
    }
#endif

    static private func datestamp() -> String {
        if #available(OSX 10.12, *) {
            return ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone.current, formatOptions: .withInternetDateTime)
        }
        return String(NSDate().timeIntervalSince1970)
    }
}

class LogWindowController: NSWindowController, NSWindowDelegate {

    @IBAction func clearClicked(_ sender: Any) {
        (contentViewController as? LogViewController)?.clear()
    }
    
    func append(_ string: String) {
        var datestamp: String
        if #available(OSX 10.12, *) {
            datestamp = ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone.current, formatOptions: .withInternetDateTime)
        } else {
            datestamp = String(NSDate().timeIntervalSince1970)
        }
        (contentViewController as? LogViewController)?.append(datestamp + ": " + string + "\n")
    }
    
    func windowWillClose(_ notification: Notification) {
        Logger.logging = false
        clearClicked(self)
    }
}

extension LogWindowController {
    // MARK: Storyboard instantiation
    static func freshController() -> LogWindowController {
        let storyboard = NSStoryboard(name: "LogViewer", bundle: nil)
        let identifier = "LogWindowController"
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? LogWindowController else {
            fatalError("Unable to find WindowController")
        }
        
        windowController.window?.delegate = windowController
        
        return windowController
    }
}


class LogViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    
    let font = NSFont(name:"Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)
    
    let textColorAttribute =
        [NSAttributedString.Key.foregroundColor: NSColor.textColor,
         NSAttributedString.Key.font: NSFont(name:"Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)]
            
            as [NSAttributedString.Key: Any]
    
    func append(_ string: String) {
        let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY
        
        textView.textStorage?.append(NSAttributedString(string: string, attributes: textColorAttribute))
        
        if smartScroll{
            textView.scrollToEndOfDocument(self)
        }
    }

    func clear() {
        textView.string = ""
    }
    
    override func viewDidLoad() {
        textView.isEditable = false
    }
    
}

class KeyDownTextView: NSTextView {
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            switch event.charactersIgnoringModifiers! {
            case "w":
                self.window?.close()
            case "h":
                self.window?.orderOut(self)
            default:
                super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }
}
