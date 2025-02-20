import ProjectDescription

public extension Plist.Value {
    static let buildNumber: Self = .string(.init(Shell.numberOfCommits() ?? 1))
}
