import { contextBridge, ipcRenderer } from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // File system helpers
  getAppPath: (): Promise<string> => ipcRenderer.invoke('get-app-path'),

  // Platform detection
  platform: process.platform,
  isElectron: true,
});

// Type declarations for the exposed API
declare global {
  interface Window {
    electronAPI?: {
      getAppPath: () => Promise<string>;
      platform: NodeJS.Platform;
      isElectron: boolean;
    };
  }
}
