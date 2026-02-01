import {useCallback, useEffect, useRef, useState} from 'react';

interface Point {
    x: number;
    y: number;
}

export interface MarkerStroke {
    id: number;
    points: Point[];
    createdAt: number;
    permanent: boolean;
}

export const MARKER_FADE_MS = 3000;

export function pointsToPath(points: Point[]): string {
    if (points.length === 0) return '';
    if (points.length === 1) return `M ${points[0].x} ${points[0].y} l 0.1 0`;
    let d = `M ${points[0].x} ${points[0].y}`;
    for (let i = 1; i < points.length - 1; i++) {
        const mx = (points[i].x + points[i + 1].x) / 2;
        const my = (points[i].y + points[i + 1].y) / 2;
        d += ` Q ${points[i].x} ${points[i].y} ${mx} ${my}`;
    }
    d += ` L ${points[points.length - 1].x} ${points[points.length - 1].y}`;
    return d;
}

export function useMarkerTool(panZoomValue: {a: number; d: number; e: number; f: number}) {
    const [isActive, setIsActive] = useState(false);
    const [strokes, setStrokes] = useState<MarkerStroke[]>([]);
    const drawingRef = useRef(false);
    const nextId = useRef(0);
    const overlayRef = useRef<HTMLDivElement>(null);
    const pvRef = useRef(panZoomValue);
    const rafRef = useRef(0);
    const pendingRef = useRef<Point[]>([]);

    useEffect(() => {
        pvRef.current = panZoomValue;
    }, [panZoomValue]);

    useEffect(() => {
        return () => {
            if (rafRef.current) cancelAnimationFrame(rafRef.current);
        };
    }, []);

    const toSvg = useCallback((cx: number, cy: number): Point => {
        const el = overlayRef.current;
        if (!el) return {x: 0, y: 0};
        const r = el.getBoundingClientRect();
        const {a, d, e, f} = pvRef.current;
        return {x: (cx - r.left - e) / a, y: (cy - r.top - f) / d};
    }, []);

    const onPointerDown = useCallback(
        (ev: React.PointerEvent) => {
            ev.preventDefault();
            ev.stopPropagation();
            (ev.target as HTMLElement).setPointerCapture(ev.pointerId);
            drawingRef.current = true;
            const pt = toSvg(ev.clientX, ev.clientY);
            setStrokes(prev => [...prev, {id: ++nextId.current, points: [pt], createdAt: Date.now(), permanent: ev.shiftKey}]);
        },
        [toSvg],
    );

    const onPointerMove = useCallback(
        (ev: React.PointerEvent) => {
            if (!drawingRef.current) return;
            ev.preventDefault();
            const pt = toSvg(ev.clientX, ev.clientY);
            pendingRef.current.push(pt);

            if (!rafRef.current) {
                rafRef.current = requestAnimationFrame(() => {
                    const batch = pendingRef.current;
                    pendingRef.current = [];
                    rafRef.current = 0;
                    setStrokes(prev => {
                        const c = [...prev];
                        const last = c[c.length - 1];
                        if (last) c[c.length - 1] = {...last, points: [...last.points, ...batch]};
                        return c;
                    });
                });
            }
        },
        [toSvg],
    );

    const onPointerUp = useCallback((ev: React.PointerEvent) => {
        if (!drawingRef.current) return;
        drawingRef.current = false;
        (ev.target as HTMLElement).releasePointerCapture(ev.pointerId);
    }, []);

    const removeStroke = useCallback((id: number) => {
        setStrokes(prev => prev.filter(s => s.id !== id));
    }, []);

    const clearAll = useCallback(() => setStrokes([]), []);
    const toggle = useCallback(() => setIsActive(p => !p), []);

    return {
        isActive,
        toggle,
        strokes,
        clearAll,
        hasStrokes: strokes.length > 0,
        removeStroke,
        overlayRef,
        onPointerDown,
        onPointerMove,
        onPointerUp,
    };
}
