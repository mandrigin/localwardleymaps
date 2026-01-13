import html2canvas from 'html2canvas';
import React, {MouseEvent, useCallback, useEffect, useMemo, useRef, useState} from 'react';
import {ReactSVGPanZoom, TOOL_NONE, UncontrolledReactSVGPanZoom} from 'react-svg-pan-zoom';
import {EvolutionStages, MapCanvasDimensions, MapDimensions, Offsets} from '../../constants/defaults';
import {MapElements} from '../../processing/MapElements';
import {MapTheme} from '../../types/map/styles';
import {UnifiedWardleyMap} from '../../types/unified/map';
import {processLinks} from '../../utils/mapProcessing';
import {useFeatureSwitches} from '../FeatureSwitchesContext';
import {useModKeyPressedConsumer} from '../KeyPressContext';
import MapCanvasToolbar from './MapCanvasToolbar';
import MapGridGroup from './MapGridGroup';
import PositionCalculator from './PositionCalculator';
import UnifiedMapContent from './UnifiedMapContent';

interface ModernUnifiedMapCanvasProps {
    wardleyMap: UnifiedWardleyMap;
    mapDimensions: MapDimensions;
    mapCanvasDimensions: MapCanvasDimensions;
    mapStyleDefs: MapTheme;
    mapEvolutionStates: EvolutionStages;
    evolutionOffsets: Offsets;
    mapText: string;
    mutateMapText: (newText: string) => void;
    setHighlightLine: React.Dispatch<React.SetStateAction<number>>;
    setNewComponentContext: React.Dispatch<React.SetStateAction<{x: string; y: string} | null>>;
    launchUrl: (urlId: string) => void;
    showLinkedEvolved: boolean;
    shouldHideNav?: () => void;
    hideNav?: boolean;
    mapAnnotationsPresentation: any;
    handleMapCanvasClick?: (pos: {x: number; y: number}) => void;
}

function UnifiedMapCanvas(props: ModernUnifiedMapCanvasProps) {
    const featureSwitches = useFeatureSwitches();
    const {enableAccelerators, showMapToolbar, allowMapZoomMouseWheel} = featureSwitches;

    const {
        wardleyMap,
        mapText,
        mutateMapText,
        setHighlightLine,
        setNewComponentContext,
        showLinkedEvolved,
        launchUrl,
        mapDimensions,
        mapCanvasDimensions,
        mapStyleDefs,
        evolutionOffsets,
        mapEvolutionStates,
        mapAnnotationsPresentation,
    } = props;

    const isModKeyPressed = useModKeyPressedConsumer();
    const Viewer = useRef<ReactSVGPanZoom>(null);

    const mapElements = useMemo(() => {
        return new MapElements(wardleyMap);
    }, [wardleyMap]);

    const processedLinks = useMemo(() => {
        return processLinks(
            wardleyMap.links.map(link => ({
                start: link.start,
                end: link.end,
                line: link.line ?? 0,
                flow: link.flow ?? false,
                flowValue: link.flowValue ?? '',
                future: link.future ?? false,
                past: link.past ?? false,
                context: link.context ?? '',
            })),
            mapElements,
            wardleyMap.anchors.map(anchor => ({
                ...anchor,
                line: anchor.line ?? 0,
                evolved: anchor.evolved ?? false,
                inertia: anchor.inertia ?? false,
                increaseLabelSpacing: anchor.increaseLabelSpacing ?? 0,
                pseudoComponent: anchor.pseudoComponent ?? false,
                offsetY: anchor.offsetY ?? 0,
                evolving: anchor.evolving ?? false,
                decorators: anchor.decorators ?? {
                    buy: false,
                    build: false,
                    outsource: false,
                    ecosystem: false,
                    market: false,
                },
            })),
            showLinkedEvolved,
        );
    }, [wardleyMap.links, mapElements, wardleyMap.anchors, showLinkedEvolved]);

    const [enableZoomOnClick] = useState(true);
    const [tool, setTool] = useState(TOOL_NONE as any);
    const [scaleFactor, setScaleFactor] = useState(1);
    const [value, setValue] = useState({
        version: 2 as const,
        mode: TOOL_NONE as any,
        focus: false,
        a: 1,
        b: 0,
        c: 0,
        d: 1,
        e: 0,
        f: 0,
        viewerWidth: mapCanvasDimensions.width,
        viewerHeight: mapCanvasDimensions.height,
        SVGWidth: mapDimensions.width + 105,
        SVGHeight: mapDimensions.height + 137,
        miniatureOpen: false,
    });

    const handleZoomChange = (newValue: any) => {
        setValue(newValue);
        setScaleFactor(newValue.a); // a is the scale factor
    };

    const [mapElementsClicked, setMapElementsClicked] = useState<
        Array<{
            el: any;
            e: MouseEvent<Element>;
        }>
    >([]);

    useEffect(() => {
        if (!isModKeyPressed && mapElementsClicked.length > 0) {
            setMapElementsClicked([]);
        }
    }, [isModKeyPressed, mapElementsClicked]);

    const handleMapClick = (event: any) => {
        if (enableZoomOnClick && props.handleMapCanvasClick) {
            const pos = {x: event.x || 0, y: event.y || 0};
            props.handleMapCanvasClick(pos);
        }
    };

    const handleMapDoubleClick = (event: any) => {
        if (enableZoomOnClick) {
            const svgPos = {x: event.x || 0, y: event.y || 0};

            const positionCalc = new PositionCalculator();
            const maturity = parseFloat(positionCalc.xToMaturity(svgPos.x, mapDimensions.width));
            const visibility = parseFloat(positionCalc.yToVisibility(svgPos.y, mapDimensions.height));

            console.log('Double-click coordinates:', {
                svgX: svgPos.x,
                svgY: svgPos.y,
                maturity,
                visibility,
            });

            setNewComponentContext({
                x: maturity.toFixed(2),
                y: visibility.toFixed(2),
            });
        }
    };

    const handleMapMouseMove = () => {};

    const clicked = function (ctx: {el: any; e: MouseEvent<Element> | null}) {
        console.log('mapElementsClicked::clicked', ctx);
        setHighlightLine(ctx.el.line || 0);
        if (isModKeyPressed === false) return;
        if (ctx.e === null) return;
        const s = [...mapElementsClicked, {el: ctx.el, e: ctx.e}];
        if (s.length === 2) {
            mutateMapText(mapText + '\r\n' + s.map(r => r.el.name).join('->'));
            setMapElementsClicked([]);
        } else setMapElementsClicked(s);
    };

    // Spread overlapping components that don't have explicit positions
    const handleSpreadComponents = useCallback(() => {
        const allComponents = mapElements.getMergedComponents();

        // Find components at default position (0,0) or very close together
        const THRESHOLD = 0.05; // Components within 5% of each other are considered overlapping
        const DEFAULT_POS_THRESHOLD = 0.02; // Components at (0,0) or very close

        // Group components by their approximate position
        const positionGroups: Map<string, typeof allComponents> = new Map();

        allComponents.forEach(comp => {
            // Check if component is at default position (no explicit coords)
            // In Wardley maps: maturity 0 = genesis (left), visibility 0 = invisible (bottom)
            const isAtDefault = comp.maturity < DEFAULT_POS_THRESHOLD && comp.visibility < DEFAULT_POS_THRESHOLD;

            if (isAtDefault) {
                const key = 'default';
                if (!positionGroups.has(key)) {
                    positionGroups.set(key, []);
                }
                positionGroups.get(key)!.push(comp);
            } else {
                // Group by approximate position
                const gridX = Math.round(comp.maturity / THRESHOLD) * THRESHOLD;
                const gridY = Math.round(comp.visibility / THRESHOLD) * THRESHOLD;
                const key = `${gridX.toFixed(2)},${gridY.toFixed(2)}`;

                if (!positionGroups.has(key)) {
                    positionGroups.set(key, []);
                }
                positionGroups.get(key)!.push(comp);
            }
        });

        // Find groups with overlapping components (more than 1 component)
        const overlappingGroups = Array.from(positionGroups.entries()).filter(([, comps]) => comps.length > 1);

        if (overlappingGroups.length === 0) {
            console.log('No overlapping components found');
            return;
        }

        // Calculate new positions for overlapping components
        let newMapText = mapText;

        overlappingGroups.forEach(([key, comps]) => {
            // Determine center point and spread radius based on number of components
            let centerX: number, centerY: number;
            // Larger spread for more components, minimum 20%, up to 50% for many components
            const baseRadius = 0.20;
            const SPREAD_RADIUS = Math.min(0.50, baseRadius + comps.length * 0.03);

            if (key === 'default') {
                // For default position components, spread them across the map
                // Center in upper-left quadrant (genesis/custom, high visibility)
                centerX = 0.35;
                centerY = 0.65; // Upper area (visibility 0.65 = visible)
            } else {
                // Use the average position of the group
                centerX = comps.reduce((sum, c) => sum + c.maturity, 0) / comps.length;
                centerY = comps.reduce((sum, c) => sum + c.visibility, 0) / comps.length;
            }

            // Spread components in a circle around the center
            comps.forEach((comp, index) => {
                const angle = (2 * Math.PI * index) / comps.length;
                const radius = SPREAD_RADIUS * (0.7 + Math.random() * 0.3); // Randomize radius 70-100%

                let newX = centerX + radius * Math.cos(angle);
                let newY = centerY + radius * Math.sin(angle);

                // Clamp to valid range [0.05, 0.95] to keep components away from edges
                newX = Math.max(0.05, Math.min(0.95, newX));
                newY = Math.max(0.05, Math.min(0.95, newY));

                // Update the map text
                // Match component definition with or without coordinates
                const escapedName = comp.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

                // Pattern for component with existing coordinates: component Name [x, y]
                const withCoordsPattern = new RegExp(
                    `^(component\\s+${escapedName}\\s*)\\[([\\d.]+),\\s*([\\d.]+)\\]`,
                    'gm',
                );

                // Pattern for component without coordinates: component Name (at end of line or before other attributes)
                const withoutCoordsPattern = new RegExp(`^(component\\s+${escapedName})(?=\\s*$|\\s+label|\\s+inertia)`, 'gm');

                if (withCoordsPattern.test(newMapText)) {
                    // Component has coordinates, update them
                    newMapText = newMapText.replace(withCoordsPattern, `$1[${newY.toFixed(2)}, ${newX.toFixed(2)}]`);
                } else if (withoutCoordsPattern.test(newMapText)) {
                    // Component doesn't have coordinates, add them
                    newMapText = newMapText.replace(
                        withoutCoordsPattern,
                        `$1 [${newY.toFixed(2)}, ${newX.toFixed(2)}]`,
                    );
                }
            });
        });

        if (newMapText !== mapText) {
            mutateMapText(newMapText);
            console.log('Spread components:', overlappingGroups.map(([key, comps]) => `${key}: ${comps.length} components`));
        }
    }, [mapElements, mapText, mutateMapText]);

    const handleScreenshot = useCallback(async () => {
        const mapCanvas = document.getElementById('map-canvas');
        if (!mapCanvas) {
            console.error('Map canvas not found');
            return;
        }

        // Hide toolbar during screenshot
        const toolbar = document.getElementById('map-canvas-toolbar');
        if (toolbar) {
            toolbar.style.display = 'none';
        }

        try {
            // Use html2canvas to capture the map
            const canvas = await html2canvas(mapCanvas, {
                backgroundColor: '#ffffff',
                scale: 2, // Higher resolution
                useCORS: true,
                logging: false,
            });

            // Convert canvas to blob
            const blob = await new Promise<Blob | null>(resolve => {
                canvas.toBlob(resolve, 'image/png');
            });

            if (!blob) {
                console.error('Failed to create blob from canvas');
                return;
            }

            // Try to copy to clipboard
            // For Electron compatibility, we need to handle this carefully
            // The ClipboardItem API doesn't work in all Electron versions
            if (typeof ClipboardItem !== 'undefined' && navigator.clipboard?.write) {
                try {
                    const clipboardItem = new ClipboardItem({'image/png': blob});
                    await navigator.clipboard.write([clipboardItem]);
                    console.log('Screenshot copied to clipboard');
                    return;
                } catch (clipboardError) {
                    console.warn('ClipboardItem API failed, trying fallback:', clipboardError);
                }
            }

            // Fallback: Download the image instead
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `wardley-map-${Date.now()}.png`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
            console.log('Screenshot downloaded as file (clipboard not available)');
        } catch (error) {
            console.error('Screenshot failed:', error);
        } finally {
            // Restore toolbar visibility
            if (toolbar) {
                toolbar.style.display = '';
            }
        }
    }, []);

    useEffect(() => {
        if (Viewer.current) {
            const element = Viewer.current;
            if (element && element.setState) {
                element.setState(value);
            }
        }
    }, [value]);

    useEffect(() => {
        if (mapDimensions.width > 0 && mapDimensions.height > 0) {
            console.log('Initial fit effect triggered', {
                width: mapDimensions.width,
                height: mapDimensions.height,
                components: wardleyMap.components.length,
            });

            const performDelayedFit = () => {
                console.log('performDelayedFit called');
                if (Viewer.current && Viewer.current.fitSelection) {
                    // Check if map has actually rendered components
                    const mapContainer = document.getElementById('map');
                    const renderedComponents = mapContainer?.querySelectorAll('circle, rect');

                    console.log('Checking rendered components:', renderedComponents?.length);

                    if (renderedComponents && renderedComponents.length > 0) {
                        console.log('Components found, scheduling fit');
                        // Wait for any localStorage restoration or other initialization to complete
                        setTimeout(() => {
                            if (Viewer.current && Viewer.current.fitSelection) {
                                console.log('EXECUTING INITIAL FIT TO SELECTION');
                                // Gentle fit with conservative margins
                                Viewer.current.fitSelection(
                                    -60, // Margin for value chain labels on left
                                    -70, // Margin for title at top
                                    mapDimensions.width + 80, // Margin for evolution labels on right
                                    mapDimensions.height + 90, // Margin for evolution labels at bottom
                                );
                            }
                        }, 1500); // Wait for localStorage restoration to complete
                    } else {
                        console.log('Components not rendered yet, retrying...');
                        // Components not rendered yet, try again
                        setTimeout(performDelayedFit, 300);
                    }
                } else {
                    console.log('Viewer.current or fitSelection not available');
                }
            };

            // Start the fit process after a delay
            const timer = setTimeout(performDelayedFit, 800);
            return () => clearTimeout(timer);
        } else {
            console.log('Initial fit conditions not met', {
                width: mapDimensions.width,
                height: mapDimensions.height,
                components: wardleyMap.components.length,
            });
        }
    }, [mapDimensions.width, mapDimensions.height]);
    const fill = {
        wardley: 'url(#wardleyGradient)',
        colour: 'white',
        plain: 'white',
        handwritten: 'white',
        dark: '#353347',
    };

    const svgBackground = mapStyleDefs.className === 'wardley' ? 'white' : fill[mapStyleDefs.className as keyof typeof fill] || 'white';

    return (
        <div id="map-canvas" style={{width: '100%', height: '100%', position: 'relative'}}>
            <UncontrolledReactSVGPanZoom
                ref={Viewer}
                SVGBackground={svgBackground}
                background="white"
                tool={tool}
                width={mapCanvasDimensions.width || window.innerWidth - 100} // Use larger fallback width
                height={mapCanvasDimensions.height || window.innerHeight - 200} // Use larger fallback height
                detectAutoPan={false}
                detectWheel={allowMapZoomMouseWheel}
                miniatureProps={{
                    position: 'none',
                    background: '#eee',
                    width: 200,
                    height: 200,
                }}
                toolbarProps={{
                    position: 'none',
                }}
                preventPanOutside={false}
                onClick={handleMapClick}
                onDoubleClick={handleMapDoubleClick}
                onMouseMove={handleMapMouseMove}
                onZoom={handleZoomChange}
                scaleFactorOnWheel={allowMapZoomMouseWheel ? 1.1 : 1}
                style={{
                    userSelect: 'none',
                    fontFamily: mapStyleDefs.fontFamily,
                    width: '100%',
                    height: '100%', // Use full height since toolbar is now fixed position
                    display: 'block',
                }}>
                <svg
                    className={[mapStyleDefs.className, 'mapCanvas'].join(' ')}
                    width={mapDimensions.width + 105}
                    height={mapDimensions.height + 137}
                    viewBox={`-35 -45 ${mapDimensions.width + 105} ${mapDimensions.height + 137}`}
                    id="svgMap"
                    version="1.1"
                    xmlns="http://www.w3.org/2000/svg"
                    xmlnsXlink="http://www.w3.org/1999/xlink">
                    <MapGridGroup
                        mapDimensions={mapDimensions}
                        mapStyleDefs={mapStyleDefs}
                        mapEvolutionStates={mapEvolutionStates}
                        evolutionOffsets={evolutionOffsets}
                        mapTitle={wardleyMap.title}
                    />
                    <UnifiedMapContent
                        mapElements={mapElements}
                        mapDimensions={mapDimensions}
                        mapStyleDefs={mapStyleDefs}
                        launchUrl={launchUrl}
                        mapAttitudes={wardleyMap.attitudes}
                        mapText={mapText}
                        mutateMapText={mutateMapText}
                        scaleFactor={scaleFactor}
                        mapElementsClicked={mapElementsClicked}
                        links={processedLinks}
                        evolutionOffsets={evolutionOffsets}
                        enableNewPipelines={true}
                        setHighlightLine={setHighlightLine}
                        clicked={clicked}
                        enableAccelerators={enableAccelerators}
                        mapAccelerators={wardleyMap.accelerators.map((accelerator: any) => ({
                            ...accelerator,
                            type: accelerator.deaccelerator ? 'deaccelerator' : 'accelerator',
                            label: accelerator.label || {x: 0, y: 0},
                        }))}
                        mapNotes={wardleyMap.notes}
                        mapAnnotations={wardleyMap.annotations}
                        mapAnnotationsPresentation={mapAnnotationsPresentation}
                        mapMethods={wardleyMap.methods}
                    />
                </svg>
            </UncontrolledReactSVGPanZoom>
            {showMapToolbar && (
                <div
                    id="map-canvas-toolbar"
                    style={{
                        position: 'absolute',
                        bottom: '20px', // Reduced from 60px to 20px, saving 40px
                        left: '20px',
                        zIndex: 1000,
                        backgroundColor: 'rgba(255, 255, 255, 0.95)',
                        borderRadius: '8px',
                        padding: '8px',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                        border: '1px solid rgba(0,0,0,0.1)',
                    }}>
                    <MapCanvasToolbar
                        shouldHideNav={props.shouldHideNav || (() => {})}
                        hideNav={props.hideNav || false}
                        tool={tool}
                        handleChangeTool={(event, newTool) => setTool(newTool)}
                        _fitToViewer={() => {
                            if (Viewer.current) {
                                // Use conservative margins to avoid clipping
                                if (Viewer.current.fitSelection) {
                                    Viewer.current.fitSelection(
                                        -60, // Margin for value chain labels on left
                                        -70, // Margin for title at top
                                        mapDimensions.width + 80, // Margin for evolution labels on right
                                        mapDimensions.height + 90, // Margin for evolution labels at bottom
                                    );
                                }
                            }
                        }}
                        onSpreadComponents={handleSpreadComponents}
                        onScreenshot={handleScreenshot}
                    />
                </div>
            )}
        </div>
    );
}

export default UnifiedMapCanvas;
