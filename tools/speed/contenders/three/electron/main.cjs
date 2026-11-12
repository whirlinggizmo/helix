// three.js's page as a desktop program: Electron's main process, opening one window of WIDTH x HEIGHT on URL with Chromium's frame
// rate cap and vsync off, ANGLE over BACKEND (vulkan, gl, or swiftshader off a GPU). tools/speed/run_page.cjs starts it with
// --electron, and reads the page as it reads a browser's. Usage: electron main.cjs URL WIDTH HEIGHT BACKEND
const {app, BrowserWindow} = require('electron');
const [url, width, height, backend] = process.argv.slice(-4);
for (const name of ['disable-gpu-vsync', 'disable-frame-rate-limit', 'mute-audio'])
	app.commandLine.appendSwitch(name);
app.commandLine.appendSwitch('use-angle', backend);
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');
// Off a GPU (the private display), ANGLE's software renderer, which Chromium runs only when allowed.
app.commandLine.appendSwitch('enable-unsafe-swiftshader');
app.whenReady().then(() => {
	const window = new BrowserWindow({width: Number(width), height: Number(height), useContentSize: true, autoHideMenuBar: true,
		webPreferences: {backgroundThrottling: false}});
	window.loadURL(url);
});
app.on('window-all-closed', () => app.quit());
