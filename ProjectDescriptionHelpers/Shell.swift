import Foundation

public enum Shell { }

public extension Shell {
    /// Run command and capture output
    /// - Parameter command: Command to be run
    /// - Returns: Standard output of command or nil if error occured
    static func capture(_ command: [String]) -> String? {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = nil
        task.arguments = ["-c", command.joined(separator: " ")]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            return nil
        }
        
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Run command and capture output
    /// - Parameter command: Command to be run
    /// - Returns: Standard output of command or nil if error occured
    static func capture(_ command: String...) -> String? {
        capture(Array(command))
    }
}
