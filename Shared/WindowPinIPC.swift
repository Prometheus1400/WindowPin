import Foundation

public enum WindowPinCommand: String, Codable, CaseIterable, Sendable {
    case toggle
    case list
    case unpinAll = "unpin-all"
}

public struct PinnedWindowInfo: Codable, Equatable, Sendable {
    public let windowID: UInt32
    public let ownerPID: Int32
    public let ownerName: String
    public let windowTitle: String

    public init(windowID: UInt32, ownerPID: Int32, ownerName: String, windowTitle: String) {
        self.windowID = windowID
        self.ownerPID = ownerPID
        self.ownerName = ownerName
        self.windowTitle = windowTitle
    }
}

public struct WindowPinResponse: Codable, Equatable, Sendable {
    public let success: Bool
    public let message: String?
    public let windows: [PinnedWindowInfo]

    public init(success: Bool, message: String? = nil, windows: [PinnedWindowInfo] = []) {
        self.success = success
        self.message = message
        self.windows = windows
    }
}

public enum WindowPinIPC {
    public static let appBundleIdentifier = "cc.jorviksoftware.WindowPin"
    public static let commandNotification = Notification.Name("cc.jorviksoftware.WindowPin.cli-command")
    public static let responseNotification = Notification.Name("cc.jorviksoftware.WindowPin.cli-response")
    public static let requestIDKey = "requestID"
    public static let commandKey = "command"
    public static let payloadKey = "payload"

    public static func encode(_ response: WindowPinResponse) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(response), as: UTF8.self)
    }

    public static func decode(_ payload: String) throws -> WindowPinResponse {
        try JSONDecoder().decode(WindowPinResponse.self, from: Data(payload.utf8))
    }
}
