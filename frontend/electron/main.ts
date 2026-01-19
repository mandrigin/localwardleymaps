import {app, BrowserWindow, dialog, ipcMain, Menu} from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import {spawn, ChildProcess} from 'child_process';

let mainWindow: BrowserWindow | null = null;
let nextProcess: ChildProcess | null = null;
let cliFilePath: string | null = null;
let isQuitting = false;

const isDev = process.env.NODE_ENV === 'development';

/**
 * Get additional Node.js paths for development mode.
 * When launched from Finder/Dock, the shell PATH doesn't include nvm or Homebrew paths.
 * This function detects common Node.js installation locations.
 */
function getNodePaths(): string[] {
    const paths: string[] = [];
    const home = process.env.HOME || '';

    // Check nvm paths - find installed node versions
    const nvmDir = path.join(home, '.nvm', 'versions', 'node');
    if (fs.existsSync(nvmDir)) {
        try {
            const versions = fs.readdirSync(nvmDir);
            // Sort versions descending to prefer newer versions
            versions.sort((a, b) => b.localeCompare(a, undefined, {numeric: true}));
            for (const version of versions) {
                const binPath = path.join(nvmDir, version, 'bin');
                if (fs.existsSync(binPath)) {
                    paths.push(binPath);
                    break; // Use the newest version
                }
            }
        } catch {
            // Ignore errors reading nvm directory
        }
    }

    // Check Homebrew paths (Apple Silicon and Intel)
    const homebrewPaths = ['/opt/homebrew/bin', '/usr/local/bin'];
    for (const brewPath of homebrewPaths) {
        if (fs.existsSync(path.join(brewPath, 'node'))) {
            paths.push(brewPath);
        }
    }

    return paths;
}

/**
 * Get augmented PATH with Node.js paths for spawning processes.
 */
function getAugmentedPath(): string {
    const nodePaths = getNodePaths();
    const currentPath = process.env.PATH || '';
    if (nodePaths.length === 0) {
        return currentPath;
    }
    return [...nodePaths, currentPath].join(path.delimiter);
}

/**
 * Get the path to the bundled Node.js binary (production) or null (development).
 * In production, Node.js is bundled in the resources directory.
 */
function getBundledNodePath(): string | null {
    if (isDev) {
        return null;
    }

    const platform = process.platform;
    const nodeBinary = platform === 'win32' ? 'node.exe' : 'node';
    const nodePath = path.join(process.resourcesPath, 'node', nodeBinary);

    if (fs.existsSync(nodePath)) {
        return nodePath;
    }

    console.warn('Bundled Node.js not found at:', nodePath);
    return null;
}

// Recent files storage
interface RecentFile {
    path: string;
    name: string;
    lastOpened: number;
}

const MAX_RECENT_FILES = 10;

function getRecentFilesPath(): string {
    return path.join(app.getPath('userData'), 'recent-files.json');
}

async function loadRecentFiles(): Promise<RecentFile[]> {
    try {
        const filePath = getRecentFilesPath();
        if (!fs.existsSync(filePath)) {
            return [];
        }
        const content = await fs.promises.readFile(filePath, 'utf-8');
        const files = JSON.parse(content) as RecentFile[];
        // Filter out files that no longer exist
        const validFiles = files.filter(f => fs.existsSync(f.path));
        return validFiles.slice(0, MAX_RECENT_FILES);
    } catch {
        return [];
    }
}

async function saveRecentFiles(files: RecentFile[]): Promise<void> {
    const filePath = getRecentFilesPath();
    await fs.promises.writeFile(filePath, JSON.stringify(files, null, 2), 'utf-8');
}

async function addToRecentFiles(filePath: string): Promise<RecentFile[]> {
    const files = await loadRecentFiles();
    const name = path.basename(filePath);
    const absPath = path.resolve(filePath);

    // Remove if already exists
    const filtered = files.filter(f => f.path !== absPath);

    // Add at the beginning
    const newFiles: RecentFile[] = [{path: absPath, name, lastOpened: Date.now()}, ...filtered].slice(0, MAX_RECENT_FILES);

    await saveRecentFiles(newFiles);
    return newFiles;
}
const PORT = process.env.PORT || 3000;

// Parse CLI arguments for file path
function parseCliFilePath(): string | null {
    // Skip electron binary and script path
    // In dev: electron . /path/to/file.owm
    // In prod: ./App /path/to/file.owm
    const args = process.argv.slice(isDev ? 2 : 1);

    for (const arg of args) {
        // Skip flags
        if (arg.startsWith('-')) continue;
        // Skip the current directory arg in dev mode
        if (arg === '.') continue;
        // Check if it looks like a file path and exists
        if (fs.existsSync(arg)) {
            return path.resolve(arg);
        }
    }
    return null;
}

cliFilePath = parseCliFilePath();

function createWindow(): void {
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 800,
        minHeight: 600,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            contextIsolation: true,
            nodeIntegration: false,
        },
        title: 'Local Wardley Maps',
        show: false,
    });

    mainWindow.once('ready-to-show', () => {
        mainWindow?.show();
    });

    if (isDev) {
        mainWindow.loadURL(`http://localhost:${PORT}`);
        mainWindow.webContents.openDevTools();
    } else {
        mainWindow.loadURL(`http://localhost:${PORT}`);
    }

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

async function startNextServer(): Promise<void> {
    return new Promise((resolve, reject) => {
        const bundledNode = getBundledNodePath();

        if (isDev) {
            // Development mode: use system npm
            // Augment PATH to include nvm/Homebrew paths when launched from Finder
            nextProcess = spawn('npm', ['run', 'dev'], {
                cwd: path.join(__dirname, '..'),
                shell: true,
                detached: true,
                env: {
                    ...process.env,
                    PATH: getAugmentedPath(),
                    PORT: String(PORT),
                },
            });
        } else {
            // Production mode: use bundled Node.js to run Next.js directly
            const appDir = path.join(process.resourcesPath, 'app');
            const nextBin = path.join(appDir, 'node_modules', 'next', 'dist', 'bin', 'next');

            if (!bundledNode) {
                reject(new Error('Bundled Node.js not found'));
                return;
            }

            nextProcess = spawn(bundledNode, [nextBin, 'start'], {
                cwd: appDir,
                detached: true,
                env: {
                    ...process.env,
                    PORT: String(PORT),
                    NODE_ENV: 'production',
                },
            });
        }

        nextProcess.stdout?.on('data', (data: Buffer) => {
            const output = data.toString();
            console.log('[Next.js]', output);
            if (output.includes('Ready') || output.includes('started server')) {
                resolve();
            }
        });

        nextProcess.stderr?.on('data', (data: Buffer) => {
            console.error('[Next.js Error]', data.toString());
        });

        nextProcess.on('error', err => {
            console.error('Failed to start Next.js server:', err);
            reject(err);
        });

        // Fallback resolve after timeout (server may already be ready)
        setTimeout(() => resolve(), 5000);
    });
}

function killNextServer(): void {
    if (nextProcess && nextProcess.pid) {
        if (process.platform === 'win32') {
            spawn('taskkill', ['/pid', String(nextProcess.pid), '/f', '/t']);
        } else {
            // Kill entire process group (negative PID kills the group)
            // This ensures child processes spawned by shell are also killed
            try {
                process.kill(-nextProcess.pid, 'SIGTERM');
            } catch {
                // Fallback to regular kill if process group kill fails
                nextProcess.kill('SIGTERM');
            }
        }
        nextProcess = null;
    }
}

app.whenReady().then(async () => {
    // Set up application menu (required for Cmd+Q on macOS)
    if (process.platform === 'darwin') {
        const template: Electron.MenuItemConstructorOptions[] = [
            {
                label: app.name,
                submenu: [
                    {role: 'about'},
                    {type: 'separator'},
                    {role: 'hide'},
                    {role: 'hideOthers'},
                    {role: 'unhide'},
                    {type: 'separator'},
                    {role: 'quit'},
                ],
            },
            {
                label: 'File',
                submenu: [{role: 'close'}],
            },
            {
                label: 'Edit',
                submenu: [
                    {role: 'undo'},
                    {role: 'redo'},
                    {type: 'separator'},
                    {role: 'cut'},
                    {role: 'copy'},
                    {role: 'paste'},
                    {role: 'selectAll'},
                ],
            },
            {
                label: 'View',
                submenu: [
                    {role: 'reload'},
                    {role: 'forceReload'},
                    {role: 'toggleDevTools'},
                    {type: 'separator'},
                    {role: 'resetZoom'},
                    {role: 'zoomIn'},
                    {role: 'zoomOut'},
                    {type: 'separator'},
                    {role: 'togglefullscreen'},
                ],
            },
            {
                label: 'Window',
                submenu: [{role: 'minimize'}, {role: 'zoom'}, {type: 'separator'}, {role: 'front'}],
            },
        ];
        Menu.setApplicationMenu(Menu.buildFromTemplate(template));
    }

    try {
        await startNextServer();
        createWindow();
    } catch (err) {
        console.error('Failed to start application:', err);
        app.quit();
    }

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    killNextServer();
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('before-quit', event => {
    if (isQuitting) return; // Already quitting, don't recurse

    if (nextProcess) {
        event.preventDefault(); // Prevent quit until server is killed
        isQuitting = true;
        killNextServer();
        // Give time for process to die, then force exit
        setTimeout(() => {
            app.exit(0); // Use exit() to bypass event handlers
        }, 500);
    }
});

app.on('will-quit', () => {
    // Final cleanup - ensure server is dead
    killNextServer();
});

// IPC handlers for file system access
ipcMain.handle('get-app-path', () => {
    return app.getPath('userData');
});

ipcMain.handle('get-cli-file-path', () => {
    return cliFilePath;
});

ipcMain.handle('read-file', async (_event, filePath: string) => {
    try {
        const content = await fs.promises.readFile(filePath, 'utf-8');
        const stats = await fs.promises.stat(filePath);
        return {content, lastModified: stats.mtimeMs};
    } catch (err) {
        throw new Error(`Failed to read file: ${err instanceof Error ? err.message : String(err)}`);
    }
});

ipcMain.handle('write-file', async (_event, filePath: string, content: string) => {
    try {
        await fs.promises.writeFile(filePath, content, 'utf-8');
        return true;
    } catch (err) {
        throw new Error(`Failed to write file: ${err instanceof Error ? err.message : String(err)}`);
    }
});

ipcMain.handle('get-file-stats', async (_event, filePath: string) => {
    try {
        const stats = await fs.promises.stat(filePath);
        return {lastModified: stats.mtimeMs};
    } catch (err) {
        throw new Error(`Failed to get file stats: ${err instanceof Error ? err.message : String(err)}`);
    }
});

// Recent files IPC handlers
ipcMain.handle('get-recent-files', async () => {
    return await loadRecentFiles();
});

ipcMain.handle('add-recent-file', async (_event, filePath: string) => {
    return await addToRecentFiles(filePath);
});

ipcMain.handle('remove-recent-file', async (_event, filePath: string) => {
    const files = await loadRecentFiles();
    const absPath = path.resolve(filePath);
    const filtered = files.filter(f => f.path !== absPath);
    await saveRecentFiles(filtered);
    return filtered;
});

ipcMain.handle('clear-recent-files', async () => {
    await saveRecentFiles([]);
    return [];
});

// File dialog handler - returns file path for Electron native file selection
ipcMain.handle('show-open-dialog', async () => {
    if (!mainWindow) return null;

    const result = await dialog.showOpenDialog(mainWindow, {
        properties: ['openFile'],
        filters: [
            {name: 'Wardley Map files', extensions: ['owm', 'wardley', 'txt']},
            {name: 'All files', extensions: ['*']},
        ],
    });

    if (result.canceled || result.filePaths.length === 0) {
        return null;
    }

    return result.filePaths[0];
});
