import ClearIcon from '@mui/icons-material/Clear';
import DeleteIcon from '@mui/icons-material/Delete';
import DescriptionIcon from '@mui/icons-material/Description';
import FolderOpenIcon from '@mui/icons-material/FolderOpen';
import {
    Box,
    Button,
    CircularProgress,
    Divider,
    IconButton,
    List,
    ListItem,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    Paper,
    Tooltip,
    Typography,
} from '@mui/material';
import React from 'react';
import {RecentFile} from '../../hooks/useRecentFiles';
import {useI18n} from '../../hooks/useI18n';

interface RecentFilesListProps {
    recentFiles: RecentFile[];
    isLoading: boolean;
    onFileSelect: (filePath: string) => void;
    onRemoveFile: (filePath: string) => void;
    onClearAll: () => void;
    onBrowse: () => void;
    isLightTheme: boolean;
}

const RecentFilesList: React.FC<RecentFilesListProps> = ({
    recentFiles,
    isLoading,
    onFileSelect,
    onRemoveFile,
    onClearAll,
    onBrowse,
    isLightTheme,
}) => {
    const {t} = useI18n();

    const formatDate = (timestamp: number) => {
        const date = new Date(timestamp);
        const now = new Date();
        const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

        if (diffDays === 0) {
            return t('recentFiles.today', 'Today') + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'});
        } else if (diffDays === 1) {
            return t('recentFiles.yesterday', 'Yesterday');
        } else if (diffDays < 7) {
            return date.toLocaleDateString([], {weekday: 'long'});
        } else {
            return date.toLocaleDateString();
        }
    };

    if (isLoading) {
        return (
            <Box sx={{display: 'flex', justifyContent: 'center', alignItems: 'center', py: 4}}>
                <CircularProgress size={24} />
            </Box>
        );
    }

    return (
        <Paper
            elevation={0}
            sx={{
                backgroundColor: isLightTheme ? '#fafafa' : '#1e1e1e',
                borderRadius: 2,
                overflow: 'hidden',
            }}>
            <Box
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    px: 2,
                    py: 1.5,
                    backgroundColor: isLightTheme ? '#e3f2fd' : '#1a237e',
                }}>
                <Typography
                    variant="subtitle1"
                    sx={{
                        fontWeight: 600,
                        color: isLightTheme ? '#1565c0' : '#90caf9',
                    }}>
                    {t('recentFiles.title', 'Recent Files')}
                </Typography>
                {recentFiles.length > 0 && (
                    <Tooltip title={t('recentFiles.clearAll', 'Clear all')}>
                        <IconButton
                            size="small"
                            onClick={onClearAll}
                            sx={{color: isLightTheme ? '#1565c0' : '#90caf9'}}>
                            <ClearIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                )}
            </Box>

            <List disablePadding>
                {recentFiles.length === 0 ? (
                    <ListItem>
                        <ListItemText
                            primary={t('recentFiles.noFiles', 'No recent files')}
                            secondary={t('recentFiles.openFile', 'Open a file to get started')}
                            sx={{
                                '& .MuiListItemText-primary': {
                                    color: isLightTheme ? '#666' : '#aaa',
                                },
                                '& .MuiListItemText-secondary': {
                                    color: isLightTheme ? '#999' : '#666',
                                },
                            }}
                        />
                    </ListItem>
                ) : (
                    recentFiles.map((file, index) => (
                        <React.Fragment key={file.path}>
                            {index > 0 && <Divider />}
                            <ListItem
                                disablePadding
                                secondaryAction={
                                    <Tooltip title={t('recentFiles.remove', 'Remove from list')}>
                                        <IconButton
                                            edge="end"
                                            size="small"
                                            onClick={e => {
                                                e.stopPropagation();
                                                onRemoveFile(file.path);
                                            }}
                                            sx={{
                                                opacity: 0.5,
                                                '&:hover': {opacity: 1},
                                            }}>
                                            <DeleteIcon fontSize="small" />
                                        </IconButton>
                                    </Tooltip>
                                }>
                                <ListItemButton onClick={() => onFileSelect(file.path)}>
                                    <ListItemIcon sx={{minWidth: 40}}>
                                        <DescriptionIcon
                                            sx={{
                                                color: isLightTheme ? '#1976d2' : '#64b5f6',
                                            }}
                                        />
                                    </ListItemIcon>
                                    <ListItemText
                                        primary={file.name}
                                        secondary={
                                            <Box
                                                component="span"
                                                sx={{
                                                    display: 'flex',
                                                    flexDirection: 'column',
                                                    gap: 0.25,
                                                }}>
                                                <Typography
                                                    variant="caption"
                                                    component="span"
                                                    sx={{
                                                        color: isLightTheme ? '#666' : '#888',
                                                        fontFamily: 'monospace',
                                                        fontSize: '0.7rem',
                                                        overflow: 'hidden',
                                                        textOverflow: 'ellipsis',
                                                        whiteSpace: 'nowrap',
                                                        display: 'block',
                                                    }}>
                                                    {file.path}
                                                </Typography>
                                                <Typography
                                                    variant="caption"
                                                    component="span"
                                                    sx={{
                                                        color: isLightTheme ? '#999' : '#666',
                                                        fontSize: '0.7rem',
                                                    }}>
                                                    {formatDate(file.lastOpened)}
                                                </Typography>
                                            </Box>
                                        }
                                        sx={{
                                            '& .MuiListItemText-primary': {
                                                fontWeight: 500,
                                                color: isLightTheme ? '#333' : '#eee',
                                            },
                                        }}
                                    />
                                </ListItemButton>
                            </ListItem>
                        </React.Fragment>
                    ))
                )}
            </List>

            <Divider />

            <Box sx={{p: 1.5}}>
                <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<FolderOpenIcon />}
                    onClick={onBrowse}
                    sx={{
                        textTransform: 'none',
                        borderColor: isLightTheme ? '#90caf9' : '#3949ab',
                        color: isLightTheme ? '#1565c0' : '#90caf9',
                        '&:hover': {
                            borderColor: isLightTheme ? '#1976d2' : '#5c6bc0',
                            backgroundColor: isLightTheme ? 'rgba(25, 118, 210, 0.04)' : 'rgba(92, 107, 192, 0.08)',
                        },
                    }}>
                    {t('recentFiles.browse', 'Browse for file...')}
                </Button>
            </Box>
        </Paper>
    );
};

export default RecentFilesList;
