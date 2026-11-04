import OSLog

/// Unified logging categories. Never log window titles, captured pixels or configuration contents.
public enum AetherLog {
    public static let lifecycle = Logger(subsystem: "com.aether.desktop", category: "lifecycle")
    public static let configuration = Logger(subsystem: "com.aether.desktop", category: "configuration")
    public static let permissions = Logger(subsystem: "com.aether.desktop", category: "permissions")
}