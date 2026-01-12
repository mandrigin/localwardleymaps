import {useCallback, useEffect, useRef, useState} from 'react';

export interface FileMonitorState {
    isMonitoring: boolean;
    fileName: string | null;
    lastModified: Date | null;
    error: string | null;
    isSupported: boolean;
}

export interface FileMonitorActions {
    selectFile: () => Promise<void>;
    stopMonitoring: () => void;
}

export interface UseFileMonitorResult {
    state: FileMonitorState;
    actions: FileMonitorActions;
}

const POLL_INTERVAL_MS = 500;

export const useFileMonitor = (onContentChange: (content: string) => void): UseFileMonitorResult => {
    const [isMonitoring, setIsMonitoring] = useState(false);
    const [fileName, setFileName] = useState<string | null>(null);
    const [lastModified, setLastModified] = useState<Date | null>(null);
    const [error, setError] = useState<string | null>(null);

    const fileHandleRef = useRef<FileSystemFileHandle | null>(null);
    const lastContentRef = useRef<string>('');
    const pollIntervalRef = useRef<NodeJS.Timeout | null>(null);

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
    }, [stopPolling]);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            stopPolling();
        };
    }, [stopPolling]);

    return {
        state: {
            isMonitoring,
            fileName,
            lastModified,
            error,
            isSupported,
        },
        actions: {
            selectFile,
            stopMonitoring,
        },
    };
};
