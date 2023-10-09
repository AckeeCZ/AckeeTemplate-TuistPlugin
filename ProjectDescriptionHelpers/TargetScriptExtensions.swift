import ProjectDescription

public extension TargetScript {
    /// Action that tries to run Swiftlint using mint, or directly if mint is not installed
    /// 
    /// If Swiftlint cannot be found, then it does nothing
    /// - Parameter inputPaths: List of files to be linted, useful when user script sandbox is enabled
    /// - Returns: Target script to be run
    static func swiftlint(
        inputPaths: [FileListGlob] = []
    ) -> TargetScript {
        .post(
            script: """
            export PATH=/opt/homebrew/bin:${PATH}
            
            set -e
            
            if ! [ -f ".swiftlint.yml" ]; then
                echo "No swiftlint.yml found, not running it"
                exit 0
            fi
            
            if command -v mint &> /dev/null && grep -iq swiftlint Mintfile; then
                echo "Mint"
                pushd "$SRCROOT"
                xcrun --sdk macosx mint run swiftlint --fix
                xcrun --sdk macosx mint run swiftlint
                popd
                exit 0
            fi
            
            if command -v "swiftlint" &> /dev/null; then
                echo "Direct"
                pushd "$SRCROOT"
                xcrun --sdk macosx swiftlint --fix
                xcrun --sdk macosx swiftlint
                popd
                exit 0
            fi
            
            echo "SwiftLint not found, not running it"
            """,
            name: "SwiftLint",
            inputPaths: inputPaths,
            basedOnDependencyAnalysis: false
        )
    }
}

public extension [TargetScript] {
    /// Downloads latest upload dSYM script from Firebase repository and uses it to upload dSYMs
    /// - Parameter outputDir: Destination where fetched scripts from Crashlytics will be saved
    /// - Returns: Target scripts to be run
    static func crashlytics(
        outputDir: String = "$SRCROOT/Derived"
    ) -> [TargetScript] {
        [
            .pre(
                script: """
                set -e
                
                curl "https://raw.githubusercontent.com/firebase/firebase-ios-sdk/master/Crashlytics/run" > \(outputDir)/run
                curl "https://raw.githubusercontent.com/firebase/firebase-ios-sdk/master/Crashlytics/upload-symbols" > \(outputDir)/upload-symbols
                chmod +x \(outputDir)/run \(outputDir)/upload-symbols
                """,
                name: "Fetch Crashlytics scripts",
                outputPaths: [
                    "\(outputDir)/run",
                    "\(outputDir)/upload-symbols",
                ]
            ),
            .post(
                script: """
                set -e
                
                "$SCRIPT_INPUT_FILE_0"
                """,
                name: "Crashlytics",
                inputPaths: [
                    // Input from fetching scripts
                    "\(outputDir)/run",
                    "\(outputDir)/upload-symbols",
                    // Crashlytics files - https://firebase.google.com/docs/crashlytics/get-started?platform=ios#set-up-dsym-uploading
                    "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                    "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                    "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                    "$(BUILT_PRODUCTS_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                    "$(BUILT_PRODUCTS_DIR)/$(EXECUTABLE_PATH)",
                    "$(INSTALL_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                ],
                basedOnDependencyAnalysis: false
            )
        ]
    }
}
