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

class FooPath {
    public static function resolve(parent:String, child:String) {
        return normalize(Path.resolve(parent, child));
    }

    public static function relative(parent:String, child:String) {
        return normalize(Path.relative(parent, child));
    }

    static final windowsPathSeparatorRegExp = ~/\\/g;

    public static function normalize(path:String) {
        return windowsPathSeparatorRegExp.replace(path, '/');
    }
}

class TextureRepository {
    var isDestroyed = false;
    final root:String;
    final watcher:FSWatcher;
    final directory: TextureDirectory;
    final directories = new Map<String, TextureDirectory>();
    final textures = new Map<String, Texture>();
    final texturePathsToLoad = new Set<String>();

    static final instances = new Map<String, TextureRepository>();

    public static function create(path:String) {
        final root = FooPath.normalize(path);
        final instance = instances.get(root);
        if (instance != null)
            return instance;
        return new TextureRepository(root);
    }

    function new(root:String) {
        this.root = root;
        this.directory = createTextureDirectory();
        populateDirectoryFromWalker();
        this.watcher = Chokidar.watch([ root ])
            .on('add', this.onAdd)
            .on('addDir', this.onAdd)
            .on('change', this.onChange)
            .on('unlink', this.onUnlink)
            .on('unlinkDir', this.onUnlink);
        Browser.window.setInterval(this.onInterval);
        TextureRepository.instances.set(root, this);
    }

    function onInterval() {
        for (texturePath in this.texturePathsToLoad) {
            final existingTexture = textures.get(texturePath);
            if (existingTexture != null) {
                existingTexture.dispose();
            }
            final path = FooPath.resolve(this.root, texturePath);
            trace(path);
            final texture = Texture.fromFile(path);
            textures.set(texturePath, texture);
        }

        this.texturePathsToLoad.clear();
    }

    function populateDirectoryFromWalker() {
        new Walker(this.root)
        .on('data', item -> this.upsert(item.path, item.stats));
    }

    function normalize(path:String) {
        return FooPath.relative(this.root, path);
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
        this.textures.remove(path);
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

    public function getDirectory(path:String) {
        if (path == '')
            return this.directory;
        return this.directories.get(path);
    }

    public function getTexture(path:String) {
        // TODO what happens when it doesn't exist?!
        return this.textures.get(path);
    }

    public function destroy() {
        if (this.isDestroyed)
            return;

        TextureRepository.instances.remove(this.root);
        this.watcher.close();
        for (texture in this.textures)
            texture.dispose();
        this.isDestroyed = true;
    }
}

typedef TextureRepositoryPage = {
    parent:String,
    path:String,
    exists:Bool,
    subdirectoryNames:Array<String>,
    texturePaths:Array<String>,
}

class TextureRepositoryPager {
    final repository:TextureRepository;

    var path = '';
    var lastUpdatedAt:Float = -1;

    public function new(repository:TextureRepository) {
        this.repository = repository;
    }

    static function getParentPath(path:String) {
        if (path == '')
            return null;
        final dirname = Path.dirname(path);
        if (dirname == '.')
            return '';
        return dirname;
    }

    static function sort(a:String, b:String) {
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }

    public function update(): TextureRepositoryPage {
        final parent = getParentPath(this.path);
        final directory = this.repository.getDirectory(this.path);
        final subdirectoryNames = directory == null ? [] : [for (name in directory.directories.keys()) Path.basename(name)];
        final texturePaths = directory == null ? [] : [for (path in directory.texturePaths) path];
        this.lastUpdatedAt = directory == null ? -1 : directory.updatedAt;

        subdirectoryNames.sort(sort);
        texturePaths.sort(sort);

        return {
            parent: parent,
            path: this.path,
            exists: directory != null,
            subdirectoryNames: subdirectoryNames,
            texturePaths: texturePaths,
        }
    }

    public function navigateInto(subdirectoryName:String) {
        this.path = Path.join(this.path, subdirectoryName);
        this.lastUpdatedAt = -1;
    }

    public function navigateOut() {
        this.path = getParentPath(this.path);
        this.lastUpdatedAt = -1;
    }

    public function isOutdated():IsOutdatedResult {
        final directory = this.repository.getDirectory(this.path);
        if (directory == null)
            return IsOutdatedResult.IsDeleted;
        if (directory.updatedAt != this.lastUpdatedAt)
            return IsOutdatedResult.HasChanges;
        return IsOutdatedResult.UpToDate;
    }
}

enum IsOutdatedResult {
    UpToDate;
    HasChanges;
    IsDeleted;
}