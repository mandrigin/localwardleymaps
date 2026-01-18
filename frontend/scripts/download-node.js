#!/usr/bin/env node
/**
 * Downloads a portable Node.js binary for bundling with Electron.
 * Run before electron-builder to prepare the Node.js binary.
 *
 * Usage: node scripts/download-node.js [platform] [arch]
 * Defaults to current platform/arch if not specified.
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const {execSync} = require('child_process');

// Use Node 22 LTS
const NODE_VERSION = '22.12.0';

const PLATFORMS = {
    darwin: {
        arm64: `node-v${NODE_VERSION}-darwin-arm64`,
        x64: `node-v${NODE_VERSION}-darwin-x64`,
    },
    win32: {
        x64: `node-v${NODE_VERSION}-win-x64`,
        arm64: `node-v${NODE_VERSION}-win-arm64`,
    },
    linux: {
        x64: `node-v${NODE_VERSION}-linux-x64`,
        arm64: `node-v${NODE_VERSION}-linux-arm64`,
    },
};

function getDownloadUrl(platform, arch) {
    const platformConfig = PLATFORMS[platform];
    if (!platformConfig) {
        throw new Error(`Unsupported platform: ${platform}`);
    }

    const nodePkg = platformConfig[arch];
    if (!nodePkg) {
        throw new Error(`Unsupported arch ${arch} for platform ${platform}`);
    }

    const ext = platform === 'win32' ? 'zip' : 'tar.gz';
    return {
        url: `https://nodejs.org/dist/v${NODE_VERSION}/${nodePkg}.${ext}`,
        pkg: nodePkg,
        ext,
    };
}

async function download(url, dest) {
    return new Promise((resolve, reject) => {
        console.log(`Downloading ${url}...`);
        const file = fs.createWriteStream(dest);

        https
            .get(url, response => {
                if (response.statusCode === 302 || response.statusCode === 301) {
                    // Follow redirect
                    https.get(response.headers.location, redirectResponse => {
                        redirectResponse.pipe(file);
                        file.on('finish', () => {
                            file.close();
                            resolve();
                        });
                    });
                } else if (response.statusCode === 200) {
                    response.pipe(file);
                    file.on('finish', () => {
                        file.close();
                        resolve();
                    });
                } else {
                    reject(new Error(`Download failed with status ${response.statusCode}`));
                }
            })
            .on('error', err => {
                fs.unlink(dest, () => {}); // Delete partial file
                reject(err);
            });
    });
}

function extractNodeBinary(archivePath, platform, pkg, outputDir) {
    console.log(`Extracting Node.js binary...`);

    // Create output directory
    fs.mkdirSync(outputDir, {recursive: true});

    if (platform === 'win32') {
        // For Windows, extract using PowerShell
        const tempDir = path.join(path.dirname(archivePath), 'node-temp');
        execSync(`powershell -command "Expand-Archive -Path '${archivePath}' -DestinationPath '${tempDir}' -Force"`, {
            stdio: 'inherit',
        });

        // Copy node.exe
        const nodeSrc = path.join(tempDir, pkg, 'node.exe');
        const nodeDest = path.join(outputDir, 'node.exe');
        fs.copyFileSync(nodeSrc, nodeDest);

        // Copy npm files
        const npmDir = path.join(tempDir, pkg, 'node_modules', 'npm');
        const npmDest = path.join(outputDir, 'node_modules', 'npm');
        fs.mkdirSync(path.join(outputDir, 'node_modules'), {recursive: true});
        execSync(`xcopy "${npmDir}" "${npmDest}" /E /I /H /Y`, {stdio: 'inherit'});

        // Copy npm.cmd
        fs.copyFileSync(path.join(tempDir, pkg, 'npm.cmd'), path.join(outputDir, 'npm.cmd'));
        fs.copyFileSync(path.join(tempDir, pkg, 'npx.cmd'), path.join(outputDir, 'npx.cmd'));

        // Cleanup
        fs.rmSync(tempDir, {recursive: true, force: true});
    } else {
        // For macOS/Linux, use tar
        const tempDir = path.join(path.dirname(archivePath), 'node-temp');
        fs.mkdirSync(tempDir, {recursive: true});

        execSync(`tar -xzf "${archivePath}" -C "${tempDir}"`, {stdio: 'inherit'});

        // Copy just the node binary (not npm - we don't need it, we run next directly)
        const nodeSrc = path.join(tempDir, pkg, 'bin', 'node');
        const nodeDest = path.join(outputDir, 'node');
        fs.copyFileSync(nodeSrc, nodeDest);
        fs.chmodSync(nodeDest, 0o755);

        // Cleanup
        fs.rmSync(tempDir, {recursive: true, force: true});
    }

    console.log(`Node.js binary extracted to ${outputDir}`);
}

async function main() {
    const targetPlatform = process.argv[2] || process.platform;
    const targetArch = process.argv[3] || process.arch;

    console.log(`Downloading Node.js ${NODE_VERSION} for ${targetPlatform}-${targetArch}`);

    const {url, pkg, ext} = getDownloadUrl(targetPlatform, targetArch);
    const frontendDir = path.resolve(__dirname, '..');
    const resourcesDir = path.join(frontendDir, 'resources');
    const nodeDir = path.join(resourcesDir, 'node');
    const archivePath = path.join(resourcesDir, `node.${ext}`);

    // Create resources directory
    fs.mkdirSync(resourcesDir, {recursive: true});

    // Check if already downloaded
    const nodeBinary = path.join(nodeDir, targetPlatform === 'win32' ? 'node.exe' : 'node');
    if (fs.existsSync(nodeBinary)) {
        console.log(`Node.js binary already exists at ${nodeBinary}`);
        return;
    }

    // Download
    await download(url, archivePath);

    // Extract
    extractNodeBinary(archivePath, targetPlatform, pkg, nodeDir);

    // Cleanup archive
    fs.unlinkSync(archivePath);

    console.log('Done!');
}

main().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});
