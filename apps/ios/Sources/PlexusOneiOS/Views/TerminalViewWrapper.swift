import SwiftUI
import SwiftTerm

/// SwiftUI wrapper for SwiftTerm's TerminalView
/// Uses a fixed 80x24 size to match standard terminal dimensions
struct TerminalViewWrapper: UIViewRepresentable {
    let output: String
    @Binding var terminalSize: (cols: Int, rows: Int)

    // Fixed terminal dimensions to match server
    private let targetCols = 80
    private let targetRows = 24

    func makeUIView(context: Context) -> TerminalView {
        // Create with a reasonable initial frame
        let terminalView = TerminalView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))

        // Configure font first (affects cell size calculations)
        terminalView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        // Configure terminal appearance
        terminalView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

        // Set up terminal colors
        let terminal = terminalView.getTerminal()
        terminal.backgroundColor = .init(red: 26, green: 26, blue: 26)
        terminal.foregroundColor = .init(red: 224, green: 224, blue: 224)

        // Resize terminal to fixed dimensions
        terminal.resize(cols: targetCols, rows: targetRows)

        // Allow scrolling but disable input
        terminalView.isUserInteractionEnabled = true
        terminalView.allowMouseReporting = false

        context.coordinator.terminalView = terminalView
        context.coordinator.targetCols = targetCols
        context.coordinator.targetRows = targetRows

        return terminalView
    }

    func updateUIView(_ terminalView: TerminalView, context: Context) {
        let coordinator = context.coordinator
        let terminal = terminalView.getTerminal()

        // Ensure terminal stays at target size
        if terminal.cols != coordinator.targetCols || terminal.rows != coordinator.targetRows {
            terminal.resize(cols: coordinator.targetCols, rows: coordinator.targetRows)
        }

        // Write new output to terminal
        if output != coordinator.lastOutput {
            // Calculate what's new
            let newContent: String
            if output.hasPrefix(coordinator.lastOutput) {
                newContent = String(output.dropFirst(coordinator.lastOutput.count))
            } else {
                // Output was reset, clear and write all
                terminal.resetToInitialState()
                terminal.resize(cols: coordinator.targetCols, rows: coordinator.targetRows)
                newContent = output
            }

            if !newContent.isEmpty {
                terminalView.feed(text: newContent)
            }

            coordinator.lastOutput = output
        }

        // Update reported terminal size
        DispatchQueue.main.async {
            let newSize = (cols: terminal.cols, rows: terminal.rows)
            if newSize.cols != terminalSize.cols || newSize.rows != terminalSize.rows {
                terminalSize = newSize
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var terminalView: TerminalView?
        var lastOutput: String = ""
        var targetCols: Int = 80
        var targetRows: Int = 24
    }
}

/// Preview provider
struct TerminalViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        TerminalViewWrapper(
            output: "Welcome to PlexusOne\r\n$ ",
            terminalSize: .constant((cols: 80, rows: 24))
        )
        .frame(height: 400)
    }
}
