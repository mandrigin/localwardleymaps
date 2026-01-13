import {contextBridge, ipcRenderer} from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
// Recent file type
interface RecentFile {
    path: string;
    name: string;
    lastOpened: number;
}

contextBridge.exposeInMainWorld('electronAPI', {
    // File system helpers
    getAppPath: (): Promise<string> => ipcRenderer.invoke('get-app-path'),

    // CLI file path (for auto-monitoring)
    getCliFilePath: (): Promise<string | null> => ipcRenderer.invoke('get-cli-file-path'),

    // File operations (for CLI-provided paths that bypass File System Access API)
    readFile: (filePath: string): Promise<{content: string; lastModified: number}> => ipcRenderer.invoke('read-file', filePath),
    writeFile: (filePath: string, content: string): Promise<boolean> => ipcRenderer.invoke('write-file', filePath, content),
    getFileStats: (filePath: string): Promise<{lastModified: number}> => ipcRenderer.invoke('get-file-stats', filePath),

    // Recent files
    getRecentFiles: (): Promise<RecentFile[]> => ipcRenderer.invoke('get-recent-files'),
    addRecentFile: (filePath: string): Promise<RecentFile[]> => ipcRenderer.invoke('add-recent-file', filePath),
    removeRecentFile: (filePath: string): Promise<RecentFile[]> => ipcRenderer.invoke('remove-recent-file', filePath),
    clearRecentFiles: (): Promise<RecentFile[]> => ipcRenderer.invoke('clear-recent-files'),

    // Platform detection
    platform: process.platform,
    isElectron: true,
});

// Type declarations for the exposed API
declare global {
    interface Window {
        electronAPI?: {
            getAppPath: () => Promise<string>;
            getCliFilePath: () => Promise<string | null>;
            readFile: (filePath: string) => Promise<{content: string; lastModified: number}>;
            writeFile: (filePath: string, content: string) => Promise<boolean>;
            getFileStats: (filePath: string) => Promise<{lastModified: number}>;
            getRecentFiles: () => Promise<RecentFile[]>;
            addRecentFile: (filePath: string) => Promise<RecentFile[]>;
            removeRecentFile: (filePath: string) => Promise<RecentFile[]>;
            clearRecentFiles: () => Promise<RecentFile[]>;
            platform: NodeJS.Platform;
            isElectron: boolean;
        };
    }
}
