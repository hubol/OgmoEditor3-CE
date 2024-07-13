package io;

import js.node.fs.Stats;
import js.jquery.JQuery;
import haxe.Json;
import js.Browser;
import js.html.Document;
import js.html.ImageData;
import js.html.ImageElement;
import js.lib.Uint8Array;
import js.node.Buffer;
import js.node.Fs;
import electron.FileFilter;
import features.ElectronRemote;

class FileSystem
{
	// Resolves ., .., // + converts \ to /
	public static function normalize(path:String):String
	{
		return haxe.io.Path.normalize(path);
	}

	public static function chooseFile(title:String, filters:Array<FileFilter>, ?defaultPath:String)
	{
		if (defaultPath != null)
			defaultPath = js.node.Path.normalize(defaultPath); // Converts / back to \ on Windows, or else won't work

		var files = Ogmo.dialog.showOpenDialogSync(
			ElectronRemote.getCurrentWindow(),
			{
				title: title,
				properties: ['openFile'],
				filters: filters,
				defaultPath: defaultPath
			}
		);

		if (files != null) return normalize(files[0]);
		return '';
	}

	public static function chooseSaveFile(title:String, filters:Array<FileFilter>, ?defaultPath:String):String
	{
		if (defaultPath != null)
			defaultPath = js.node.Path.normalize(defaultPath); // Converts / back to \ on Windows, or else won't work

		var file = Ogmo.dialog.showSaveDialogSync(
			ElectronRemote.getCurrentWindow(),
			{
				title: title,
				filters: filters,
				defaultPath: defaultPath
			}
		);
		if (file != null) return normalize(file);
		return '';
	}

	public static function chooseFolder(title:String):String
	{
		var files = Ogmo.dialog.showOpenDialogSync(
			ElectronRemote.getCurrentWindow(),
			{
				title: title,
				properties: ['openDirectory']
			}
		);
		if (files != null) return normalize(files[0]);
		return '';
	}

	public static function removeFolder(dir:String)
	{
		if (!exists(dir)) return;
	}

	public static function exists(path:String):Bool
	{
		return Fs.existsSync(path);
	}

	public static function readDirectory(path:String):Array<String>
	{
		return Fs.readdirSync(path);
	}

	public static function stat(path:String):Stats
	{
		return Fs.statSync(path);
	}

	public static function loadString(path:String):String
	{
		return Fs.readFileSync(path, "utf8");
	}

	public static function loadImage(path:String):ImageElement
	{
		if (FileSystem.exists(path))
		{
			var image = Browser.document.createImageElement();
			var b = Buffer.from(Fs.readFileSync(path));
			image.src = "data:image/png;base64," + b.toString("base64");
			return image;
		}
		return null;
	}

	public static function saveString(data:String, path:String)
	{
		Fs.writeFileSync(path, data);
	}

	public static function saveRGBAToPNG(data:Uint8Array, width:Int, height:Int, path:String)
	{
		var canvas = Browser.document.createCanvasElement();
		canvas.width = width;
		canvas.height = height;

		var ctx = canvas.getContext("2d");
		var imageData:ImageData = ctx.createImageData(Math.ffloor(width), Math.ffloor(height));
		for (i in 0...imageData.data.length)
			imageData.data[i] = data[i];
		ctx.putImageData(imageData, 0, 0);

		var nativeImage = js.Lib.require('electron').nativeImage;
		var img = nativeImage.createFromDataURL(canvas.toDataURL("image/png"));
		Fs.writeFileSync(path, img.toPNG());

		canvas.remove();
	}

	/*
		JSON
	*/

	public static function stringToJSON(str:String):Dynamic
	{
		return Json.parse(str);
	}

	public static function JSONtoString(data:Dynamic, compact:Bool = false):String
	{
		return compact ? Json.stringify(data) : new util.Stringify(data, {maxLength: 100000, maxNesting: 1});
	}

	public static function loadJSON(path:String):Dynamic
	{
		return FileSystem.stringToJSON(FileSystem.loadString(path));
	}

	public static function saveJSON(data:Dynamic, path:String):String
	{
		var str = FileSystem.JSONtoString(data, OGMO.project == null ? false : OGMO.project.compactExport);
		FileSystem.saveString(str, path);
		return str;
	}

	/*
		XML
	*/

	public static function stringToXML(str:String):Document
	{
		return JQuery.parseXML(str);
	}

	public static function XMLtoString(xml:Document, ?pretty:Bool):String
	{
		var str = xml.documentElement.outerHTML;
		// TODO - ugh do we have to? -01010111
		//if (pretty == true) str = FileSystem.prettyXML(str);
		return str;
	}

	// TODO - dependant on stringToXML() -01010111
	public static function loadXML(path:String):Document
	{
		return FileSystem.stringToXML(FileSystem.loadString(path));
	}

	public static function saveXML(xml:Document, path:String, ?pretty:Bool):String
	{
		var str = FileSystem.XMLtoString(xml, pretty);
		FileSystem.saveString(str, path);
		return str;
	}

	// TODO - ugh do we have to? (part two) -01010111
	/*public static function prettyXML(xml:String):String
	{
		var formatted = '';
		var reg = ~/(>)(<)(\/*)/g;
		xml = xml.replace(reg, '$1\r\n$2$3');
		var pad = 0;
		jQuery.each(xml.split('\r\n'), function(index, node) {
			var indent = 0;
			if (node.match( ~/.+<\/\w[^>]*>$/ )) {
				indent = 0;
			} else if (node.match( ~/^<\/\w/ )) {
				if (pad != 0) {
					pad -= 1;
				}
			} else if (node.match( ~/^<\w[^>]*[^\/]>.*$/ )) {
				indent = 1;
			} else {
				indent = 0;
			}

			var padding = '';
			for (var i = 0; i < pad; i++) {
				padding += '  ';
			}

			formatted += padding + node + '\r\n';
			pad += indent;
		});

		return formatted;
	}*/

}

enum UnsavedOptions
{
	Save;
	NoSave;
	Cancel;
}