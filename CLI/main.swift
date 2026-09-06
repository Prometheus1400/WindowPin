import AppKit
import Darwin
import Foundation
import WindowPinIPC

private final class ResponseReceiver: NSObject {
    let requestID: String
    var response: WindowPinResponse?

    init(requestID: String) {
        self.requestID = requestID
    }

    @objc func receive(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            userInfo[WindowPinIPC.requestIDKey] as? String == requestID,
            let payload = userInfo[WindowPinIPC.payloadKey] as? String,
            let response = try? WindowPinIPC.decode(payload)
        else { return }

        self.response = response
        CFRunLoopStop(CFRunLoopGetMain())
    }
}

@main
private enum WindowPinCLI {
    private static let timeout: TimeInterval = 2

    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let json = arguments.contains("--json")
        let positional = arguments.filter { $0 != "--json" }

        guard positional.count == 1, let command = WindowPinCommand(rawValue: positional[0]) else {
            writeError("Usage: windowpinctl <toggle|list|unpin-all> [--json]")
            exit(2)
        }

        guard !NSRunningApplication.runningApplications(
            withBundleIdentifier: WindowPinIPC.appBundleIdentifier
        ).isEmpty else {
            writeError("WindowPin is not running")
            exit(1)
        }

        let requestID = UUID().uuidString
        let receiver = ResponseReceiver(requestID: requestID)
        let center = DistributedNotificationCenter.default()
        center.addObserver(
            receiver,
            selector: #selector(ResponseReceiver.receive(_:)),
            name: WindowPinIPC.responseNotification,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        defer { center.removeObserver(receiver) }

        center.postNotificationName(
            WindowPinIPC.commandNotification,
            object: nil,
            userInfo: [
                WindowPinIPC.requestIDKey: requestID,
                WindowPinIPC.commandKey: command.rawValue,
            ],
            deliverImmediately: true
        )

        let deadline = Date().addingTimeInterval(timeout)
        while receiver.response == nil && Date() < deadline {
            let nextPoll = min(deadline, Date().addingTimeInterval(0.05))
            _ = RunLoop.current.run(mode: .default, before: nextPoll)
        }

        guard let response = receiver.response else {
            writeError("WindowPin did not respond within \(Int(timeout)) seconds")
            exit(1)
        }

        if json {
            guard let payload = try? WindowPinIPC.encode(response) else {
                writeError("Failed to encode WindowPin response")
                exit(1)
            }
            print(payload)
        } else {
            printPlain(response, command: command)
        }

        if !response.success { exit(1) }
    }

    private static func printPlain(_ response: WindowPinResponse, command: WindowPinCommand) {
        if command == .list {
            for window in response.windows {
                let app = sanitize(window.ownerName)
                let title = sanitize(window.windowTitle)
                print("\(window.windowID)\t\(window.ownerPID)\t\(app)\t\(title)")
            }
        } else if let message = response.message {
            let output = response.success ? message : "Error: \(message)"
            if response.success { print(output) } else { writeError(output) }
        }
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
