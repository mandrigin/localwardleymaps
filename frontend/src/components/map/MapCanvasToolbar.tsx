import CameraAltIcon from '@mui/icons-material/CameraAlt';
import ClearAllIcon from '@mui/icons-material/ClearAll';
import PanIcon from '@mui/icons-material/ControlCamera';
import FitScreenIcon from '@mui/icons-material/FitScreen';
import FullscreenIcon from '@mui/icons-material/Fullscreen';
import FullscreenExitIcon from '@mui/icons-material/FullscreenExit';
import GestureIcon from '@mui/icons-material/Gesture';
import HandIcon from '@mui/icons-material/PanToolAlt';
import ScatterPlotIcon from '@mui/icons-material/ScatterPlot';
import ZoomInIcon from '@mui/icons-material/ZoomIn';
import ZoomOutIcon from '@mui/icons-material/ZoomOut';

import {ButtonGroup, IconButton, Tooltip} from '@mui/material';
import React, {MouseEvent} from 'react';
import {TOOL_NONE, TOOL_PAN, TOOL_ZOOM_IN, TOOL_ZOOM_OUT} from 'react-svg-pan-zoom';
import {useI18n} from '../../hooks/useI18n';

interface MapCanvasToolbarProps {
    shouldHideNav: () => void;
    hideNav: boolean;
    tool: string;
    handleChangeTool: (event: MouseEvent<HTMLButtonElement>, newTool: string) => void;
    _fitToViewer: () => void;
    onScreenshot?: () => void;
    onSpreadComponents?: () => void;
    isMarkerActive?: boolean;
    onToggleMarker?: () => void;
    onClearMarkers?: () => void;
    hasMarkerStrokes?: boolean;
}

const MapCanvasToolbar: React.FC<MapCanvasToolbarProps> = ({
    shouldHideNav,
    hideNav,
    tool,
    handleChangeTool,
    _fitToViewer,
    onScreenshot,
    onSpreadComponents,
    isMarkerActive,
    onToggleMarker,
    onClearMarkers,
    hasMarkerStrokes,
}) => {
    const SelectedIconButtonStyle = {color: '#90caf9'};
    const IconButtonStyle = {color: 'rgba(0, 0, 0, 0.54)'};
    const {t} = useI18n();

    return (
        <ButtonGroup orientation="horizontal" aria-label={t('map.toolbar.group', 'button group')}>
            <IconButton
                id="wm-map-select"
                aria-label={t('map.toolbar.select', 'Select')}
                onClick={event => handleChangeTool(event, TOOL_NONE)}
                sx={tool === TOOL_NONE ? SelectedIconButtonStyle : IconButtonStyle}>
                <HandIcon />
            </IconButton>
            <IconButton
                id="wm-map-pan"
                aria-label={t('map.toolbar.pan', 'Pan')}
                onClick={event => handleChangeTool(event, TOOL_PAN)}
                sx={tool === TOOL_PAN ? SelectedIconButtonStyle : IconButtonStyle}>
                <PanIcon />
            </IconButton>
            <IconButton
                id="wm-zoom-in"
                aria-label={t('map.toolbar.zoomIn', 'Zoom In')}
                sx={tool === TOOL_ZOOM_IN ? SelectedIconButtonStyle : IconButtonStyle}
                onClick={event => handleChangeTool(event, TOOL_ZOOM_IN)}>
                <ZoomInIcon />
            </IconButton>
            <IconButton
                id="wm-zoom-out"
                aria-label={t('map.toolbar.zoomOut', 'Zoom Out')}
                sx={tool === TOOL_ZOOM_OUT ? SelectedIconButtonStyle : IconButtonStyle}
                onClick={event => handleChangeTool(event, TOOL_ZOOM_OUT)}>
                <ZoomOutIcon />
            </IconButton>
            <IconButton id="wm-map-fit" aria-label={t('map.toolbar.fit', 'Fit')} sx={IconButtonStyle} onClick={() => _fitToViewer()}>
                <FitScreenIcon />
            </IconButton>
            {onSpreadComponents && (
                <Tooltip title={t('map.toolbar.spread', 'Spread overlapping components')}>
                    <IconButton
                        id="wm-map-spread"
                        aria-label={t('map.toolbar.spread', 'Spread')}
                        sx={IconButtonStyle}
                        onClick={onSpreadComponents}>
                        <ScatterPlotIcon />
                    </IconButton>
                </Tooltip>
            )}
            {onScreenshot && (
                <Tooltip title={t('map.toolbar.screenshot', 'Copy map to clipboard')}>
                    <IconButton
                        id="wm-map-screenshot"
                        aria-label={t('map.toolbar.screenshot', 'Screenshot')}
                        sx={IconButtonStyle}
                        onClick={onScreenshot}>
                        <CameraAltIcon />
                    </IconButton>
                </Tooltip>
            )}
            {onToggleMarker && (
                <Tooltip title={t('map.toolbar.marker', 'Draw on map [M] (hold Shift for permanent)')}>
                    <IconButton
                        id="wm-map-marker"
                        aria-label={t('map.toolbar.marker', 'Marker')}
                        sx={isMarkerActive ? SelectedIconButtonStyle : IconButtonStyle}
                        onClick={onToggleMarker}>
                        <GestureIcon />
                    </IconButton>
                </Tooltip>
            )}
            {onClearMarkers && hasMarkerStrokes && (
                <Tooltip title={t('map.toolbar.clearMarkers', 'Clear all markers')}>
                    <IconButton
                        id="wm-map-clear-markers"
                        aria-label={t('map.toolbar.clearMarkers', 'Clear markers')}
                        sx={IconButtonStyle}
                        onClick={onClearMarkers}>
                        <ClearAllIcon />
                    </IconButton>
                </Tooltip>
            )}
            <IconButton
                id="wm-map-fullscreen"
                onClick={() => shouldHideNav()}
                aria-label={hideNav ? t('map.toolbar.exitFullscreen', 'Exit Fullscreen') : t('map.toolbar.fullscreen', 'Fullscreen')}>
                {hideNav ? <FullscreenExitIcon sx={IconButtonStyle} /> : <FullscreenIcon sx={IconButtonStyle} />}
            </IconButton>
        </ButtonGroup>
    );
};

export default MapCanvasToolbar;
