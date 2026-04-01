# Change Logs

## v0.0.12

 - update `window` only if `module` is not found
 - further minimize generated js file with mangling and compression
 - add `style` in `package.json`
 - add `main` and `browser` field in `package.json`.
 - upgrade modules
 - remove assets files from git
 - patch test code to make it work with upgraded modules
 - release with compact directory structure


## v0.0.11

 - add API for getting root node


## v0.0.10

 - add `getNodes` and `getGroups` api for convenience.
 - round result for more crisp rendering
 - add `cached` option in `getBox` for returning cached box.


## v0.0.9

 - use resizeObserver to watch resize and add config for toggling it on/off.
 - add `destroy` function to prevent further resizing event.
 - update build script to make it faster


## v0.0.8

 - fix bug: check return value of init callback before accessing its members.


## v0.0.7

 - always get the latest box info when `getBox` is called.


## v0.0.6

 - fix bug: init cb with promise should use long wavy arrow 


## v0.0.5

 - add css rules for `data-debug` for checking layout result
 - add `data-only` tag for indicating layout elements with manually generated render element counterparts.
 - add option in `update` function call to force not rendering.


## v0.0.4

 - tweak init process:
   - layout init ( including prepare dom ) 
   - caller init ( may alter dom )
   - layout update ( lookup dom nodes again )
     - wait init resolves if init return a promise.


## v0.0.3

 - better scoping CSS class with `pdl` prefix. 
 - unify class name and attribute between render and layout elements.
 - add feature: auto generate SVG tree.


## v0.0.2

 - use better namespaced class name.
 - tweak demo code file structure


## v0.0.1

init commit
