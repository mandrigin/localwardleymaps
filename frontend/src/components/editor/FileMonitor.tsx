import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import StopIcon from '@mui/icons-material/Stop';
import VisibilityIcon from '@mui/icons-material/Visibility';
import WarningIcon from '@mui/icons-material/Warning';
import {Box, Button, Typography} from '@mui/material';
import React from 'react';
import {FileMonitorActions, FileMonitorState} from '../../hooks/useFileMonitor';

export interface FileMonitorProps {
    state: FileMonitorState;
    actions: FileMonitorActions;
    isLightTheme: boolean;
    collapsed?: boolean;
}

export const FileMonitor: React.FC<FileMonitorProps> = ({state, actions, isLightTheme, collapsed = false}) => {
    const {isMonitoring, fileName, lastModified, error, isSupported} = state;
    const {selectFile, stopMonitoring} = actions;

    const formatTime = (date: Date | null): string => {
        if (!date) return '';
        return date.toLocaleTimeString();
    };

    const backgroundColor = isLightTheme ? '#fafafa' : '#1e1e1e';
    const textColor = isLightTheme ? '#333' : '#ccc';
    const borderColor = isLightTheme ? '#ddd' : '#444';

    if (!isSupported) {
        return (
            <Box
                sx={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: '100%',
                    padding: 4,
                    backgroundColor,
                    color: textColor,
                }}>
                <WarningIcon sx={{fontSize: 48, color: '#f57c00', mb: 2}} />
                <Typography variant="h6" gutterBottom>
                    Browser Not Supported
                </Typography>
                <Typography variant="body2" textAlign="center">
                    File monitoring requires the File System Access API, which is not supported in this browser. Please use Chrome, Edge, or another
                    Chromium-based browser.
                </Typography>
            </Box>
        );
    }

    // Collapsed mode: minimal UI when monitoring is active
    if (collapsed && isMonitoring) {
        return (
            <Box
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    height: '100%',
                    padding: 2,
                    backgroundColor,
                    color: textColor,
                }}>
                <Button
                    variant="outlined"
                    color="error"
                    startIcon={<StopIcon />}
                    onClick={stopMonitoring}
                    size="small"
                    sx={{textTransform: 'none'}}>
                    Stop Monitoring
                </Button>
            </Box>
        );
    }

    return (
        <Box
            sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                height: '100%',
                padding: 4,
                backgroundColor,
                color: textColor,
            }}>
            {!isMonitoring ? (
                <>
                    <FolderOpenIcon sx={{fontSize: 64, color: '#666', mb: 2}} />
                    <Typography variant="h6" gutterBottom>
                        Local File Monitoring
                    </Typography>
                    <Typography variant="body2" textAlign="center" sx={{mb: 3, maxWidth: 300}}>
                        Select a local file to monitor. The map will automatically update when the file changes.
                    </Typography>
                    <Button variant="contained" startIcon={<FolderOpenIcon />} onClick={selectFile} sx={{textTransform: 'none'}}>
                        Select File
                    </Button>
                </>
            ) : (
                <>
                    <VisibilityIcon sx={{fontSize: 48, color: '#4caf50', mb: 2}} />
                    <Typography variant="h6" gutterBottom>
                        Monitoring File
                    </Typography>
                    <Box
                        sx={{
                            backgroundColor: isLightTheme ? '#e3f2fd' : '#1a237e',
                            padding: 2,
                            borderRadius: 1,
                            mb: 2,
                            textAlign: 'center',
                            border: `1px solid ${borderColor}`,
                            minWidth: 200,
                        }}>
                        <Typography variant="body1" fontWeight="bold" sx={{wordBreak: 'break-all'}}>
                            {fileName}
                        </Typography>
                        {lastModified && (
                            <Typography variant="caption" color="textSecondary">
                                Last updated: {formatTime(lastModified)}
                            </Typography>
                        )}
                    </Box>
                    {error && (
                        <Box
                            sx={{
                                backgroundColor: '#ffebee',
                                color: '#c62828',
                                padding: 1,
                                borderRadius: 1,
                                mb: 2,
                                maxWidth: 300,
                            }}>
                            <Typography variant="body2">{error}</Typography>
                        </Box>
                    )}
                    <Box sx={{display: 'flex', gap: 1}}>
                        <Button variant="outlined" startIcon={<FolderOpenIcon />} onClick={selectFile} size="small" sx={{textTransform: 'none'}}>
                            Change File
                        </Button>
                        <Button
                            variant="outlined"
                            color="error"
                            startIcon={<StopIcon />}
                            onClick={stopMonitoring}
                            size="small"
                            sx={{textTransform: 'none'}}>
                            Stop
                        </Button>
                    </Box>
                </>
            )}
        </Box>
    );
};

export default FileMonitor;
