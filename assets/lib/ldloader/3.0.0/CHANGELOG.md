# Change Log

## v3.0.0

 - upgrade modules
 - release with compact directory structure
 - add `style` in `package.json`
 - add `main` and `browser` field in `package.json`.
 - further minimize generated js file with mangling and compression
 - remove assets files from git
 - patch test code to make it work with upgraded modules
 - update window only if window is defined


## v2.1.0

 - add `toggler` function
   - useful if we want to chain toggling to other object such as ldcover.


## v2.0.1

 - remove deprecated `ldLoader`


## v2.0.0

 - fix bug: `root` or `container` params with `NodeList` value are not treated as array, which should.
 - support `zmgr` directly in object.
 - use zmgr fallback instead of old zstack to simplify code logic
 - rename `ldloader` zmgr api ( from `set-zmgr` to `zmgr` )
 - rename `ldld.js`, `ldld.css` to `index.js`, `index.css`, including minimized version.


## v1.2.1

 - deprecate `ldLoader`. use `ldloader` instead.
 - use livescript to wrap code instead of manually do it.
 - organize `demo` to `web` folder.


## v1.2.0

 - add `setZmgr` for managing z-index globally.
 - fix bug: when `auto-z` is set to true, z value isn't calculated correctly.


## v1.1.1

 - only release `dist` files


## v1.1.0

 - use semantic delay
 - fix bug: for non-atomic loader, count should never small than 0
 - add `cancel` api

