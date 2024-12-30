 <p align="center">
  <img src="assets/gfx/logo.png" alt="Ogmo Editor 3"/>
</p>

### Open Source 2D level editor written in Haxe!
For more information, check out the [Ogmo 3 homepage](https://ogmo-editor-3.github.io/). Or just go straight to the [downloads page](https://ogmoeditor.itch.io/editor)! If you need a build for 32 bit Windows, @vontoGH has graciously made them [available here](https://github.com/vontoGH/OgmoEditor3-CE/releases)!

# Getting Started

This project requires Haxe v4.0.0 or later, Node v10+, and various dependencies for each of them.

### Node
* Install [Node](https://nodejs.org/)

### Haxe
* Install [Haxe](https://haxe.org/download/)
* Run the following commands:
```
haxelib setup
haxelib install electron 12.0.4
haxelib install jQueryExtern
haxelib install haxe-loader
```

## Build
```
npm i
npm run build
```
This builds the App and puts it in the `bin` directory. You can then start the app by running `npm start`, or by starting electron in the directory.

## Development
Speed up development by using Webpack's dev server! Running `npm run dev` builds the app, starts a server that will watch for changes in the project, then starts electron. If changes are found, Webpack will rebuild the source and refresh the app. If there are errors, they will show up in the app's DevTools.

While running the dev server, all code that is within `#if debug` conditionals are added in.

NOTES: 
  * Changes to `App.hx` are not watched, and the app will need to manually be rebuilt if changes are made there.
  * The app will need to be rebuilt normally (`npm run build`) in order to run it again after using the dev server.

## Packaging
```
npm i
npm run build
npm run dist
```
This builds, then packages the App into an executable.

# Credits
 - Created by [Maddy Thorson](https://twitter.com/MaddyThorson) and [Noel Berry](https://twitter.com/noelfb)
 - Icons & Logo by [Kyle Pulver](https://twitter.com/kylepulver)
 - Ported to Haxe and extended by [Caleb Cornett](https://twitter.com/thespydog), [Will Blanton](https://twitter.com/x01010111), and [Austin East](https://twitter.com/austinweast)

## Hubol's notes
- Node v12.22.9 works fine (some higher versions do not)
- Haxe version I'm using is 4.2.4
- Haxelib version is 4.0.2 (Not sure of relationship between haxe-haxelib versions)