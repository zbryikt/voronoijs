# ldloader

handy library to manipulate loader's state. for more information, please check [ldloader documentation](https://loading.io/lib/loader/).


## Usage

create an object for each loader you want to use:

    var ldld = new ldloader(config);


config includes following options:

 * root: element for your loader. default null
   - could be css selector, element, or array of css selectors/elements.
   - ldloader will create one automatically if omitted, and append it under container.
   - if root is an array, ldloader instance will work on every element in the array.
 * container: where root should be put in.
   - will be root.parentNode if omitted.
   - will be document.body if both root and container is omitted.
   - note: container is also an array since root by design accept array of value.
 * class-name: additional class over root. default '' and is optional.
   - you can also add classes directly onto the root element you provided.
 * active-class: class added to root when loader is toggled on. default 'running'.
   - useful when working with different css libraries.
 * inactive-class: class added to root when loader is toggled off. default is null.
 * auto-z: update root's z-index automatically. default false.
 * base-z: the minimal z-index of root. default 10000.
   - with auto-z, ldloader keeps track of all loaders' z-index and always use larger z-index for newly toggled loaders. base-z is then used as a base value for all auto-z loaders.
 * ctrl: custom animation control unit. should at least contains a member function "step(t)".
   - step(t): will be invoked repeatedly by requestAnimationFrame during loading period. context (aka this) will be root.
 * atomic: default true. when atomic is false, you will need N ldloader.off() call to dismiss ldloader if there was already N ldloader.on() call.
 * toggler(v): optional toggler triggered when `on/off` status changed. useful for chaining toggling events.
   - `v`: on/off status.

Methods:

 * on(delay): toggle loader on. return promise. (if delay is provided, wait delay(ms) before on )
 * off(delay): toggle loader off. (if delay is provided, wait delay(ms) before off )
 * cancel(v): cancel delayed action. force state to `v` if v is defined.
 * is-on: return true if loader is running, else false.
 * toggle(state,delay): toggle loader based on state(true/false). toggle according to current state if state is omitted. return promise ( delay behavior according to whether it's on or off )
 * on(event, cb): listen to events, including: ( TBD? conflict with on(delay) )
   - toggle.on
   - toggle.off


## Class Method

 * setZmgr(zmgr): set a shared z-index manager. useful to manager widget z-index globally.
   this manager should provide following methods:
   - add(baseVal, size): return actual added value.
     - baseVal: hint value for the z-index we'd like to use
     - size: hint size about how large the object we added is
   - remove(val): remove val ( returned by add ) from this manager.


## Styling and Structure

There is no constraint about how ldloader's DOM structure should be. Basically it contains an element for loader, and the element's parent in which the loader is shown. You control all the animation and effects based on `active-class` toggled by ldloader.

For convenience, ldloader is shipped with some builtin css for simple usage:

 * .ldld.bare - rotating double ring, placed at where it should be.
 * .ldld.default - rotating double ring centered in it's container. container should have style position: relatve/absolute/fixed.
 * .ldld.full - dimed full screen blocking loader, with rotating double ring in the middle.
 * size modifier for .ldld.bare  and .ldld.default:
   * .sm - 16 x 16
   * .em-1 - 1em x 1em ( useful in button )
   * .em-2 - 2em x 2em
 * color modifier:
   * without color modifier, it will `currentColor` by default.
   * .ldld.light - rgba(255,255,255,.5)
   * .ldld.dark - rgba(0,0,0,.5)

You can also use ldloader along with `loading-btn` and `loading.css`:

    <div class="btn ld-ext-right">
      Load
      <div class="ld ld-ball ld-bounce"></div>
    </div>
    <script>
      var ldld = new ldloader({root: ".ld-ext-right"});
      ldld.on(); ldld.off(1000);
    </script>
 

## License

MIT
