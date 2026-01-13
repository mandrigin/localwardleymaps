import {useCallback, useEffect, useState} from 'react';

export interface RecentFile {
    path: string;
    name: string;
    lastOpened: number;
}

export interface UseRecentFilesResult {
    recentFiles: RecentFile[];
    isLoading: boolean;
    addRecentFile: (filePath: string) => Promise<void>;
    removeRecentFile: (filePath: string) => Promise<void>;
    clearRecentFiles: () => Promise<void>;
    refresh: () => Promise<void>;
}

// IndexedDB storage for web (non-Electron)
const DB_NAME = 'RecentFilesDB';
const STORE_NAME = 'recentFiles';
const MAX_RECENT_FILES = 10;

async function openDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, 1);
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        request.onupgradeneeded = () => {
            const db = request.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, {keyPath: 'path'});
            }
        };
    });
}

async function loadRecentFilesFromIndexedDB(): Promise<RecentFile[]> {
    try {
        const db = await openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readonly');
            const store = tx.objectStore(STORE_NAME);
            const request = store.getAll();
            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                const files = request.result as RecentFile[];
                // Sort by lastOpened descending
                files.sort((a, b) => b.lastOpened - a.lastOpened);
                resolve(files.slice(0, MAX_RECENT_FILES));
            };
            tx.oncomplete = () => db.close();
        });
    } catch {
        return [];
    }
}

async function saveRecentFileToIndexedDB(file: RecentFile): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const request = store.put(file);
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve();
        tx.oncomplete = () => db.close();
    });
}

async function removeRecentFileFromIndexedDB(path: string): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const request = store.delete(path);
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve();
        tx.oncomplete = () => db.close();
    });
}

async function clearRecentFilesFromIndexedDB(): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const request = store.clear();
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve();
        tx.oncomplete = () => db.close();
    });
}

export const useRecentFiles = (): UseRecentFilesResult => {
    const [recentFiles, setRecentFiles] = useState<RecentFile[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    const isElectron = typeof window !== 'undefined' && !!window.electronAPI?.isElectron;

    const refresh = useCallback(async () => {
        setIsLoading(true);
        try {
            if (isElectron && window.electronAPI) {
                const files = await window.electronAPI.getRecentFiles();
                setRecentFiles(files);
            } else {
                const files = await loadRecentFilesFromIndexedDB();
                setRecentFiles(files);
            }
        } catch (err) {
            console.error('Failed to load recent files:', err);
        } finally {
            setIsLoading(false);
        }
    }, [isElectron]);

    const addRecentFile = useCallback(
        async (filePath: string) => {
            try {
                if (isElectron && window.electronAPI) {
                    const files = await window.electronAPI.addRecentFile(filePath);
                    setRecentFiles(files);
                } else {
                    const name = filePath.split(/[/\\]/).pop() || filePath;
                    await saveRecentFileToIndexedDB({
                        path: filePath,
                        name,
                        lastOpened: Date.now(),
                    });
                    await refresh();
                }
            } catch (err) {
                console.error('Failed to add recent file:', err);
            }
        },
        [isElectron, refresh],
    );

    const removeRecentFile = useCallback(
        async (filePath: string) => {
            try {
                if (isElectron && window.electronAPI) {
                    const files = await window.electronAPI.removeRecentFile(filePath);
                    setRecentFiles(files);
                } else {
                    await removeRecentFileFromIndexedDB(filePath);
                    await refresh();
                }
            } catch (err) {
                console.error('Failed to remove recent file:', err);
            }
        },
        [isElectron, refresh],
    );

    const clearRecentFiles = useCallback(async () => {
        try {
            if (isElectron && window.electronAPI) {
                const files = await window.electronAPI.clearRecentFiles();
                setRecentFiles(files);
            } else {
                await clearRecentFilesFromIndexedDB();
                setRecentFiles([]);
            }
        } catch (err) {
            console.error('Failed to clear recent files:', err);
        }
    }, [isElectron]);

    // Load recent files on mount
    useEffect(() => {
        refresh();
    }, [refresh]);

    return {
        recentFiles,
        isLoading,
        addRecentFile,
        removeRecentFile,
        clearRecentFiles,
        refresh,
    };
};
