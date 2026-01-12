import {useCallback, useEffect, useRef, useState} from 'react';

export interface FileMonitorState {
    isMonitoring: boolean;
    fileName: string | null;
    lastModified: Date | null;
    error: string | null;
    isSupported: boolean;
    isRestoring: boolean;
    isSaving: boolean;
    lastSaved: Date | null;
}

export interface FileMonitorActions {
    selectFile: () => Promise<void>;
    stopMonitoring: () => void;
    saveToFile: (content: string) => Promise<boolean>;
}

export interface UseFileMonitorResult {
    state: FileMonitorState;
    actions: FileMonitorActions;
}

const POLL_INTERVAL_MS = 500;
const DB_NAME = 'FileMonitorDB';
const STORE_NAME = 'fileHandles';
const HANDLE_KEY = 'lastMonitoredFile';

async function openDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, 1);
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        request.onupgradeneeded = () => {
            const db = request.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME);
            }
        };
    });
}

async function saveFileHandle(handle: FileSystemFileHandle): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const tx = db.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const request = store.put(handle, HANDLE_KEY);
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve();
        tx.oncomplete = () => db.close();
    });
}

async function loadFileHandle(): Promise<FileSystemFileHandle | null> {
    try {
        const db = await openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readonly');
            const store = tx.objectStore(STORE_NAME);
            const request = store.get(HANDLE_KEY);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result || null);
            tx.oncomplete = () => db.close();
        });
    } catch {
        return null;
    }
}

async function clearFileHandle(): Promise<void> {
    try {
        const db = await openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readwrite');
            const store = tx.objectStore(STORE_NAME);
            const request = store.delete(HANDLE_KEY);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve();
            tx.oncomplete = () => db.close();
        });
    } catch {
        // Ignore errors when clearing
    }
}

export const useFileMonitor = (onContentChange: (content: string) => void): UseFileMonitorResult => {
    const [isMonitoring, setIsMonitoring] = useState(false);
    const [fileName, setFileName] = useState<string | null>(null);
    const [lastModified, setLastModified] = useState<Date | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [isRestoring, setIsRestoring] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [lastSaved, setLastSaved] = useState<Date | null>(null);

    const fileHandleRef = useRef<FileSystemFileHandle | null>(null);
    const lastContentRef = useRef<string>('');
    const pollIntervalRef = useRef<NodeJS.Timeout | null>(null);
    const hasAttemptedRestore = useRef(false);

    const isSupported = typeof window !== 'undefined' && 'showOpenFilePicker' in window;

    const readFileContent = useCallback(async (handle: FileSystemFileHandle): Promise<{content: string; modified: Date}> => {
        const file = await handle.getFile();
        const content = await file.text();
        return {content, modified: new Date(file.lastModified)};
    }, []);

    const pollFile = useCallback(async () => {
        if (!fileHandleRef.current) return;

        try {
            const {content, modified} = await readFileContent(fileHandleRef.current);

            if (content !== lastContentRef.current) {
                lastContentRef.current = content;
                setLastModified(modified);
                onContentChange(content);
            }
            setError(null);
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to read file';
            setError(message);
        }
    }, [readFileContent, onContentChange]);

    const startPolling = useCallback(() => {
        if (pollIntervalRef.current) {
            clearInterval(pollIntervalRef.current);
        }
        pollIntervalRef.current = setInterval(pollFile, POLL_INTERVAL_MS);
    }, [pollFile]);

    const stopPolling = useCallback(() => {
        if (pollIntervalRef.current) {
            clearInterval(pollIntervalRef.current);
            pollIntervalRef.current = null;
        }
    }, []);

    const selectFile = useCallback(async () => {
        if (!isSupported) {
            setError('File System Access API is not supported in this browser');
            return;
        }

        try {
            const [handle] = await window.showOpenFilePicker({
                types: [
                    {
                        description: 'Wardley Map files',
                        accept: {
                            'text/plain': ['.txt', '.owm', '.wardley'],
                        },
                    },
                ],
                multiple: false,
            });

            fileHandleRef.current = handle;
            setFileName(handle.name);
            setError(null);

            // Persist handle to IndexedDB for restore on refresh
            saveFileHandle(handle).catch(() => {
                // Non-critical: persistence failed but monitoring works
            });

            // Read initial content
            const {content, modified} = await readFileContent(handle);
            lastContentRef.current = content;
            setLastModified(modified);
            onContentChange(content);

            setIsMonitoring(true);
            startPolling();
        } catch (err) {
            if (err instanceof Error && err.name === 'AbortError') {
                // User cancelled file picker
                return;
            }
            const message = err instanceof Error ? err.message : 'Failed to open file';
            setError(message);
        }
    }, [isSupported, readFileContent, onContentChange, startPolling]);

    const stopMonitoring = useCallback(() => {
        stopPolling();
        fileHandleRef.current = null;
        lastContentRef.current = '';
        setIsMonitoring(false);
        setFileName(null);
        setLastModified(null);
        setError(null);
        setLastSaved(null);
        // Clear persisted handle
        clearFileHandle();
    }, [stopPolling]);

    const saveToFile = useCallback(async (content: string): Promise<boolean> => {
        if (!fileHandleRef.current) {
            setError('No file selected');
            return false;
        }

        setIsSaving(true);
        setError(null);

        // Pause polling during write to prevent reload
        stopPolling();

        try {
            // Request write permission if needed
            const permission = await fileHandleRef.current.requestPermission({mode: 'readwrite'});
            if (permission !== 'granted') {
                setError('Write permission denied');
                startPolling();
                setIsSaving(false);
                return false;
            }

            // Create writable stream and write content
            const writable = await fileHandleRef.current.createWritable();
            await writable.write(content);
            await writable.close();

            // Update lastContentRef to prevent triggering a reload on next poll
            lastContentRef.current = content;
            setLastSaved(new Date());
            setError(null);

            // Resume polling
            startPolling();
            setIsSaving(false);
            return true;
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to save file';
            setError(message);
            startPolling();
            setIsSaving(false);
            return false;
        }
    }, [stopPolling, startPolling]);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            stopPolling();
        };
    }, [stopPolling]);

    // Attempt to restore previously monitored file on mount
    useEffect(() => {
        if (!isSupported || hasAttemptedRestore.current) return;
        hasAttemptedRestore.current = true;

        const restoreFile = async () => {
            setIsRestoring(true);
            try {
                const handle = await loadFileHandle();
                if (!handle) {
                    setIsRestoring(false);
                    return;
                }

                // Request permission - required after page reload
                const permission = await handle.requestPermission({mode: 'read'});
                if (permission !== 'granted') {
                    // Permission denied - clear stored handle and let user pick again
                    await clearFileHandle();
                    setIsRestoring(false);
                    return;
                }

                // Permission granted - resume monitoring
                fileHandleRef.current = handle;
                setFileName(handle.name);

                const {content, modified} = await readFileContent(handle);
                lastContentRef.current = content;
                setLastModified(modified);
                onContentChange(content);

                setIsMonitoring(true);
                startPolling();
            } catch {
                // Restore failed - clear stored handle
                await clearFileHandle();
            } finally {
                setIsRestoring(false);
            }
        };

        restoreFile();
    }, [isSupported, readFileContent, onContentChange, startPolling]);

    return {
        state: {
            isMonitoring,
            fileName,
            lastModified,
            error,
            isSupported,
            isRestoring,
            isSaving,
            lastSaved,
        },
        actions: {
            selectFile,
            stopMonitoring,
            saveToFile,
        },
    };
};
