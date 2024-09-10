package features;

import js.Browser;
import js.lib.Date;
import js.lib.Set;
import util.Klaw.Walker;
import rendering.Texture;
import js.node.Path;
import js.node.fs.Stats;
import util.Chokidar;

typedef TextureDirectory = 
{
    texturePaths: Set<String>,
    directories: Map<String, TextureDirectory>,
    updatedAt: Float,
}

class TextureRepository {
    var isDestroyed = false;
    final root:String;
    final watcher:FSWatcher;
    final directory: TextureDirectory;
    final directories = new Map<String, TextureDirectory>();
    final textures = new Map<String, Texture>();
    final texturePathsToLoad = new Set<String>();

    public function new(path:String) {
        this.root = normalizeSeparators(path);
        this.directory = createTextureDirectory();
        populateDirectoryFromWalker();
        this.watcher = Chokidar.watch([ this.root ])
            .on('add', this.onAdd)
            .on('addDir', this.onAdd)
            .on('change', this.onChange)
            .on('unlink', this.onUnlink)
            .on('unlinkDir', this.onUnlink);
        Browser.window.setInterval(this.onInterval);
    }

    function onInterval() {
        for (texturePath in this.texturePathsToLoad) {
            final existingTexture = textures.get(texturePath);
            if (existingTexture != null) {
                existingTexture.dispose();
            }
            final path = Path.resolve(this.root, texturePath);
            final texture = Texture.fromFile(path);
            textures.set(texturePath, texture);
        }

        this.texturePathsToLoad.clear();
    }

    function disposeDirectory(dir:TextureDirectory) {
        final textureKeysToRemove: Array<String> = [];

        for (texturePath in dir.texturePaths) {
            final texture = this.getTexture(texturePath);
            if (texture != null) {
                texture.dispose();
                textureKeysToRemove.push(texturePath);
            }
        }

        for (keys in textureKeysToRemove)
            this.textures.remove(keys);

        for (directory in dir.directories)
            this.disposeDirectory(directory);
    }

    function populateDirectoryFromWalker() {
        new Walker(this.root)
        .on('data', item -> this.upsert(item.path, item.stats));
    }

    static final windowsPathSeparatorRegExp = ~/\\/g;

    static function normalizeSeparators(path:String) {
        return windowsPathSeparatorRegExp.replace(path, '/');
    }

    function normalize(path:String) {
        return normalizeSeparators(Path.relative(this.root, normalizeSeparators(path)));
    }

    static function createTextureDirectory(): TextureDirectory {
        return { texturePaths: new Set(), directories: new Map(), updatedAt: Date.now() };
    }

    function upsertDirectory(parent:TextureDirectory, path:String) {
        var directory = parent.directories.get(path);
        if (directory == null) {
            directory = createTextureDirectory();
            parent.directories.set(path, directory);
            parent.updatedAt = Date.now();
            this.directories.set(path, directory);
        }

        return directory;
    }

    function upsertTexture(parent:TextureDirectory, path:String) {
        parent.updatedAt = Date.now();
        parent.texturePaths.add(path);
        this.texturePathsToLoad.add(path);
    }

    static function isProcessablePath(relativePath:String) {
        return relativePath.length > 0 && relativePath.indexOf('..') == -1 && relativePath.indexOf('.pdnSave') == -1;
    }

    function upsert(path:String, stats:Stats) {
        final relativePath = normalize(path);

        if (!isProcessablePath(relativePath))
            return;

        final ext = Path.extname(relativePath);
        final isTextureFile = (ext == ".png" || ext == ".jpeg" || ext == ".jpg" || ext == ".bmp") && stats.isFile();

        final directoryPathsToFindOrCreate = new Array<String>();
        var node = relativePath;
        while (true) {
            final parent = Path.dirname(node);
            if (parent == '.')
                break;
            node = parent;
            directoryPathsToFindOrCreate.unshift(parent);
        }

        var dir = this.directory;

        for (parent in directoryPathsToFindOrCreate) {
            final nextDir = dir.directories.get(parent);
            if (nextDir != null) {
                dir = nextDir;
                continue;
            }

            dir = upsertDirectory(dir, parent);
        }

        if (isTextureFile)
            upsertTexture(dir, relativePath);
        else
            upsertDirectory(dir, relativePath);

        trace('------- Upsert -------');
        trace(isTextureFile ? 'Texture File' : 'Directory');
        trace(relativePath);
        trace(this.directory);
    }

    function delete(path:String) {
        final relativePath = normalize(path);

        if (!isProcessablePath(relativePath))
            return;

        final directory = this.directories.get(relativePath);

        final parentPath = Path.dirname(relativePath);
        var parentDirectory = this.directories.get(parentPath);
        if (parentDirectory == null)
            parentDirectory = this.directory;

        parentDirectory.updatedAt = Date.now();

        trace('------- Delete -------');
        trace(directory == null ? 'Texture File' : 'Directory');
        trace(relativePath);

        if (directory != null) {
            parentDirectory.directories.remove(relativePath);
            deleteDirectory(relativePath, directory);
            trace(this.directory);
            return;
        }

        deleteTexture(parentDirectory, relativePath);
        trace(this.directory);
    }

    function deleteTexture(directory:TextureDirectory, path:String) {
        directory.texturePaths.delete(path);
        this.texturePathsToLoad.delete(path);
        final texture = this.textures.get(path);
        if (texture != null)
            texture.dispose();
    }

    function deleteDirectory(path:String, self:TextureDirectory) {
        this.directories.remove(path);
        for (texturePath in self.texturePaths)
            deleteTexture(self, texturePath);
        for (path => directory in self.directories)
            deleteDirectory(path, directory);
    }

    function onAdd(path:String, stats:Stats) {
        this.upsert(path, stats);
    }

    function onChange(path:String, stats:Stats) {
        this.upsert(path, stats);
    }

    function onUnlink(path:String) {
        this.delete(path);
    }

    public function getTexture(path:String) {
        // TODO what happens when it doesn't exist?!
        return this.textures.get(path);
    }

    public function destroy() {
        if (this.isDestroyed)
            return;

        this.watcher.close();
        for (texture in this.textures)
            texture.dispose();
        this.isDestroyed = true;
    }

    // watchers[i] = Chokidar.watch(paths[i], {depth: OGMO.project.directoryDepth })
	// 			.on('add', (path:String, stats:Stats) ->
	// 			{
	// 				if (path != paths[i] && items[i].children != null) recursiveAdd(path, stats, items[i]);
	// 			})
	// 			.on('addDir', (path:String, stats:Stats) ->
	// 			{
	// 				if (path != paths[i] && items[i].children != null) recursiveAdd(path, stats, items[i]);
	// 			})
	// 			.on('change', (path:String, stats:Stats) ->
	// 			{
	// 				// TODO: use this event to notify user of opened level changes? - austin
	// 			})
	// 			.on('unlink', (path:String) ->
	// 			{
	// 				if (path != paths[i] && items[i].children != null) recursiveRemove(path, items[i]);
	// 			})
	// 			.on('unlinkDir', (path:String) ->
	// 			{
	// 				if (path != paths[i] && items[i].children != null) recursiveRemove(path, items[i]);
	// 			});

    // files = { name: "root", parent: null, textures: [], subdirs: [] };

	// 	function recursiveAdd(item:Item, parent:Files):Bool
	// 	{
	// 		if (OGMO.project == null) return false;
	// 		var dirname = Path.dirname(item.path);
	// 		if (dirname == Path.join(parent.dirname, parent.name) || parent.name == 'root' && dirname == parent.dirname)
	// 		{
	// 			// add to parent
	// 			if (item.stats.isDirectory())
	// 			{
	// 				var obj = { name: Path.basename(item.path), dirname: dirname, parent: parent, textures: [], subdirs: [] };
	// 				parent.subdirs.push(obj);
	// 			}
	// 			else if (item.stats.isFile())
	// 			{
	// 				parent.textures.push(haxe.io.Path.normalize(item.path));
	// 			}
	// 			return true;
	// 		}
	// 		else
	// 		{
	// 			var found = false;
	// 			var i = 0;
	// 			while (i < parent.subdirs.length && !found)
	// 			{
	// 				found = recursiveAdd(item, parent.subdirs[i]);
	// 				i++;
	// 			}
	// 			return found;
	// 		}
	// 		return false;
	// 	}

    // var path = Path.join(Path.dirname(project.path), folder);
	// 	files.dirname = path;
	// 	if (FileSystem.exists(path))
	// 	{
	// 		walker = new Walker(path)
	// 		.on("data", (item:Item) -> { if(item.path != path) recursiveAdd(item, files); })
	// 		.on("end", () -> {
	// 			// remove sequences
	// 			if (!includeImageSequence)
	// 			{
	// 				function removeSequence (obj:Files)
	// 				{
	// 					// remove sequence
	// 					obj.textures.sort(function(a, b)
	// 					{
	// 						if(a < b) return -1;
	// 						if(a > b) return 1;
	// 						return 0;
	// 					});

	// 					var newList:Array<String> = [];
	// 					var lastName = "";
	// 					for (texture in obj.textures)
	// 					{
	// 						// get next name
	// 						var nextName = Path.basename(texture);
	// 						// TODO - willl have to double check this
	// 						nextName = '.' + nextName.split(".").pop();
							
	// 						// remove numbers
	// 						var lastNumber = nextName.length - 1;
	// 						while (lastNumber >= 0 && !nextName.charAt(lastNumber).parseInt().isNaN()) lastNumber --;
	// 						nextName = nextName.substr(0, lastNumber + 1);

	// 						// check if the last name was the same
	// 						if (lastName == "" || lastName != nextName)
	// 						{
	// 							lastName = nextName;
	// 							newList.push(texture);
	// 						}
	// 					}

	// 					obj.textures = newList;

	// 					// do the same on subdirectories
	// 					for	(subdir in obj.subdirs) removeSequence(subdir);
	// 				}

	// 				removeSequence(files);
	// 			}

	// 			// load textures
	// 			function loadTextures (obj:Files)
	// 			{
	// 				var textures = [];
	// 				for (texture in obj.textures)
	// 				{
	// 					var ext = Path.extname(texture);
	// 					if (ext != ".png" && ext != ".jpeg" && ext != ".jpg" && ext != ".bmp")
	// 						continue;
							
	// 					var tex = Texture.fromFile(texture);
	// 					if (tex != null)
	// 					{
	// 						tex.path = Path.relative(Path.dirname(project.path), texture);
	// 						this.textures.push(tex);
	// 						textures.push(tex);
	// 					}
	// 				}

	// 				obj.textures = textures;

	// 				for (subdir in obj.subdirs) loadTextures(subdir);
	// 			}

	// 			loadTextures(files);
	// 			if (doRefresh != null) doRefresh();
	// 		});
	// 	}
}

class TextureRepositoryPager {
    final repository:TextureRepository;

    var path = '';
    var lastUpdatedAt = -1;
    final subdirectoryNames = new Array<String>();
    final texturePaths = new Array<String>();

    public function new(repository:TextureRepository) {
        this.repository = repository;
    }

    public function update() {

    }

    public function isOutdated():Bool {
        return true;
    }
}