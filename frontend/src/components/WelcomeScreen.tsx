import MapIcon from '@mui/icons-material/Map';
import {Box, Paper, Typography} from '@mui/material';
import React from 'react';
import {RecentFile} from '../hooks/useRecentFiles';
import {useI18n} from '../hooks/useI18n';
import RecentFilesList from './editor/RecentFilesList';

interface WelcomeScreenProps {
    recentFiles: RecentFile[];
    isLoading: boolean;
    onFileSelect: (filePath: string) => void;
    onRemoveFile: (filePath: string) => void;
    onClearAll: () => void;
    onBrowse: () => void;
    isLightTheme: boolean;
}

const WelcomeScreen: React.FC<WelcomeScreenProps> = ({
    recentFiles,
    isLoading,
    onFileSelect,
    onRemoveFile,
    onClearAll,
    onBrowse,
    isLightTheme,
}) => {
    const {t} = useI18n();

    return (
        <Box
            sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                height: '100%',
                width: '100%',
                backgroundColor: isLightTheme ? '#f5f5f5' : '#121212',
                padding: 4,
            }}>
            <Paper
                elevation={3}
                sx={{
                    maxWidth: 500,
                    width: '100%',
                    borderRadius: 3,
                    overflow: 'hidden',
                    backgroundColor: isLightTheme ? '#fff' : '#1e1e1e',
                }}>
                {/* Header */}
                <Box
                    sx={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 2,
                        padding: 3,
                        background: isLightTheme
                            ? 'linear-gradient(135deg, #1a237e 0%, #3949ab 100%)'
                            : 'linear-gradient(135deg, #0d1b2a 0%, #1b263b 100%)',
                    }}>
                    <MapIcon sx={{fontSize: 48, color: '#fff'}} />
                    <Box>
                        <Typography
                            variant="h5"
                            sx={{
                                fontWeight: 700,
                                color: '#fff',
                            }}>
                            {t('welcome.title', 'Local Wardley Maps')}
                        </Typography>
                        <Typography
                            variant="body2"
                            sx={{
                                color: 'rgba(255, 255, 255, 0.8)',
                            }}>
                            {t('welcome.subtitle', 'Create and edit Wardley Maps locally')}
                        </Typography>
                    </Box>
                </Box>

                {/* Recent Files */}
                <Box sx={{p: 2}}>
                    <RecentFilesList
                        recentFiles={recentFiles}
                        isLoading={isLoading}
                        onFileSelect={onFileSelect}
                        onRemoveFile={onRemoveFile}
                        onClearAll={onClearAll}
                        onBrowse={onBrowse}
                        isLightTheme={isLightTheme}
                    />
                </Box>

                {/* Tips */}
                <Box
                    sx={{
                        px: 3,
                        pb: 3,
                        pt: 1,
                    }}>
                    <Typography
                        variant="caption"
                        sx={{
                            color: isLightTheme ? '#666' : '#888',
                            display: 'block',
                            textAlign: 'center',
                        }}>
                        {t(
                            'welcome.tip',
                            'Tip: You can also open files from the command line: lwm /path/to/file.owm',
                        )}
                    </Typography>
                </Box>
            </Paper>
        </Box>
    );
};

export default WelcomeScreen;
