# PlexusOne Tasks

## Open

### Desktop App

- [ ] **Scroll position indicator**: Display line position (e.g., "123/615") while scrolling through terminal scrollback. Shows current position relative to total lines.

- [ ] **macOS app icon**: Create a polished, "glassy" macOS-friendly icon for PlexusOne/Nexus. Should follow Apple HIG with proper squircle shape, gradients, and depth effects.

- [ ] **Scrollbar visibility**: Verify scrollbar thumb appears and is draggable when there's scrollback content (native scrollback, not tmux).

## Completed

### Documentation (CLAUDE.md)

- [x] **Add prerequisites section**: Documented required tool versions (Xcode 15+, Flutter 3.x, Go 1.22+, tmux, macOS 14+). (2026-03-29)

- [x] **Fix build command accuracy**: Updated desktop build instructions to show `.build/debug/PlexusOneDesktop` instead of .app bundle. (2026-03-29)

- [x] **Add CI/CD context**: Added Local Checks section with pre-push commands for all components. Noted CI workflows not yet configured. (2026-03-29)

- [x] **Document environment variables**: Added table of SHELL, TERM, LANG variables used by desktop app. (2026-03-29)

- [x] **Add Swift/Dart linting tools**: Added Linting section with tools and commands per component. (2026-03-29)

- [x] **List valid commit scopes**: Added valid scopes table (desktop, mobile, tuiparser, docs) to Commit Messages section. (2026-03-29)

### Desktop App

- [x] **Terminal trackpad scrolling**: Fixed two-finger trackpad scrolling by sending mouse wheel escape sequences (button 64/65) to terminal applications like tmux. Updated SwiftTerm to main branch for NSScroller Auto Layout fix. (2026-03-28)
