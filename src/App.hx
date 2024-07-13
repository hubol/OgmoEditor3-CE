import electron.main.IpcMain;
import js.Node.process;
import js.Node.__dirname;
import js.node.Path;
import js.node.Url;
import electron.main.App as ElectronApp;
import electron.main.BrowserWindow;
import util.WindowStateKeeper;

class App
{

	static var mainWindow:BrowserWindow = null;
	static var forceClose:Bool = false;

	public static function getMainWindow():BrowserWindow
	{
		return mainWindow;
	}

	static function main()
	{
		// Indeed, you must initialize and enable
		// https://github.com/electron/remote/issues/79#issuecomment-921004401
		// https://github.com/electron/remote/issues/94#issuecomment-1024849702
		js.Lib.require('@electron/remote/main').initialize();

		ElectronApp.on('browser-window-created', (_, window) -> {
			js.Lib.require("@electron/remote/main").enable(window.webContents);
		});

		ElectronApp.on('window-all-closed', (e) -> {
			// Keep the app open if even if windows are closed on OSX (normal mac app behavior)
			if (process.platform != 'darwin') {
				ElectronApp.quit();
				process.exit(0);
			}
		});

		ElectronApp.on('ready', (e) -> createWindow());

		// On macOS it's common to re-create a window in the app when the
		// dock icon is clicked and there are no other windows open.
		ElectronApp.on('activate', (e) -> if (mainWindow == null) createWindow());
	}

	static function createWindow()
	{
		var mainWindowState = WindowStateKeeper.create({
			defaultWidth: 1024,
			defaultHeight: 768
		});

		mainWindow = new BrowserWindow({
			backgroundColor: '#ffffff',
			title: '',
			icon: Webpack.require('./assets/img/icon32.png'),
			x: mainWindowState.x,
			y: mainWindowState.y,
			width: mainWindowState.width,
			height: mainWindowState.height,
			minWidth: 1024,
			minHeight: 600,
			webPreferences: {
				contextIsolation: false,
				enableRemoteModule: true,
				nodeIntegration: true
			} 
		});

		mainWindowState.manage(mainWindow);

		// Closing Stuff
		{
			mainWindow.on('close', (e) -> {
				if (!forceClose)
				{
					mainWindow.webContents.send('quit');
					e.preventDefault();
				}
			});

			IpcMain.on('quit', (e) -> {
				forceClose = true;
				mainWindow.close();
			});

			IpcMain.on('updateMenu', (e) -> {
				util.AppMenu.build();
			});

			mainWindow.on('closed', (e) -> {
				mainWindow = null;
			});
		}

		// mainWindow.setMenu(null);

		// Compile in debug mode to load from webpack-dev-server and open dev tools on startup
		#if debug
		mainWindow.webContents.openDevTools();
		mainWindow.loadURL(Url.format({
			protocol: 'http:',
			host: 'localhost:8080',
			pathname: 'index.html',
			slashes: true
		}));
		#else
		mainWindow.loadURL(Url.format({
			protocol: 'file:',
			pathname: Path.join(__dirname, 'index.html'),
			slashes: true
		}));
		#end
	}

}