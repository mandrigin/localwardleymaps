# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Local File Monitoring** - Replace the text editor with file-based input using the File System Access API. Select a local `.txt`, `.owm`, or `.wardley` file and the app polls it every 500ms for changes, automatically updating the map when the file is modified. Edit your Wardley maps in your favorite text editor while viewing live updates in the browser. (`f48fd1f`)

- **File Persistence** - The app remembers your last monitored file across page refreshes. File handles are stored in IndexedDB and restored on page load. The browser will request permission to re-access the file; if granted, monitoring resumes automatically. (`1c29960`)

- **Save to File** - New "Save" button in the status bar writes map changes back to the source file. Useful for persisting visual edits (like moving components) to your source file. Uses `FileSystemFileHandle.createWritable()` with proper permission handling. Polling is paused during write to prevent reload loops. (`8cdf7e3`)

- **Fullscreen Mode by Default** - The app now starts in fullscreen/map-only view with the navigation panel hidden. The map takes all available screen space. A minimal status bar at the top shows the file name, last update time, and control buttons. (`64ce1be`, `a23cafa`)

- **Electron Desktop App** - The app can now run as a standalone desktop application using Electron. Benefits include native file system access without browser permission prompts and cross-platform distribution (Windows, macOS, Linux). Run with `yarn electron:dev` for development or `yarn electron:build` for distributable packages. (`ac0cd04`)

- **CLI File Argument** - Pass a file path as a command line argument to automatically open and monitor it on launch. Works in both development (`yarn electron:dev -- /path/to/map.owm`) and production builds. Uses Node.js fs module via IPC for reliable file operations in Electron. (`3deced7`)

### Changed

- **UI Layout** - Replaced the ACE Editor left panel with a compact status bar. When no file is selected, shows a "Select File" button. When monitoring, shows file path, last modified time, Save button, and Stop button.

### Removed

- **Text Editor** - The embedded ACE Editor text field has been removed. Map source is now read from local files instead of being typed directly in the browser.

### Technical Notes

- **Browser Support** - File monitoring requires the File System Access API (Chrome/Edge 86+, Opera 72+). Firefox and Safari are not supported.
- **Key Files**:
  - `src/hooks/useFileMonitor.ts` - React hook for file handle management, polling, persistence, and save functionality
  - `src/components/editor/FileMonitor.tsx` - UI component for file selection and status display
  - `src/components/MapEnvironment.tsx` - Integration with map state via `mapActions.setMapText()`
