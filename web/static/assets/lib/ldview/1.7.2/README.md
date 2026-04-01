# ldview

A headless, logic-less HTML template engine.


## Usage

Install via npm:

    npm install --save ldview

and include in your page:

    <script src="path-to-ldview/index.min.js"></script>

construct a ldview base on how you'd like to render. For example, this render `name` tag with username:

    view = new ldview do
      root: someDomRoot
      ctx: -> user or {}
      handler: name: ({node, ctx}) -> node.textContent = ctx.user?name or 'unnamed'

which corresponds to HTML (written in Pug) such as:

    #someDomRoot: div(ld="name")


You can merge multiple configs by constructing ldview with multiple object:

    view = new ldview({root: document.body}, {handler: {...}}, {text: {...}});

You can also use `ldview.merge` to manually combine the configuration object. see `Class API` for detail.


### Basic Concept

ldview works by defining the binding between JS functions and element by `ld` attribute - consider it as the concept of `JS Selector`, like `CSS Selector`. We name elements and assign processors in JavaScript according to their names.

For example, following code names three DIVs with "ld" attributes in "plan free", "plan month", and "plan year":

    body
      div(ld="plan free")
      div(ld="plan month")
      div(ld="plan year")


To bind the corresponding processor, create a new ldview object with a handler object:

    view = new ldview do
      root: document.body
      handler:
        # this example actually demonstrates how to do a if/else or switch/case statement.
        plan: ({node, names, name, idx, ctx, local, views}) ->
          node.style.display = (if currentPlan in names => 'block' else 'none')

view by default will be rendered after initialized, but you can render it again with `render` api:

    view.render!

To separate `init` from `render`, use `init` handler:

    view = new ldview do
      root: document.body
      init: plan: -> /* do

initialization by default will be done once the view is created unless `initRender` option is false; in this case, you can initialize manually with `init` function:

    view.init!then -> /* run after initialized */

There are other types of handler, such as `action`, `text`, `style` and `attr`, See below for more information.

    view = new ldview do
      root: someDomNode
      init: someSelector: (->), ...
      text: someSelector: (->), ...
      style: someSelector: (->), ...
      attr: someSelector: (->), ...
      handle: someSelector: (->), ...
      action: /* unlike above handlers, first level of action contains different event names */
        click: someSelector: (->),
        mousedown: someSelector: (->),
        ....

in `handler` you can also loop a node with selector defined `ld-each` attribute, which is described in the next section.


### Loop with ld-each

ldview supports looping too. Declare an element to be looped with "ld-each" attribute:

    .shelf: div(ld-each="book")

the element with "book" ld-each attribute will be replaced by a comment node. Then, you can bind it with an array of elements to automatically generate a list of similar book elements with a slightly different handler config:

    new ldview do
      handler:
        # instead of a simple handler function,
        # here we have an object containing a list function and a handler function
        book:
          # tell ldview to map book elements to myBookList
          list: -> myBookList

          # optional key getter for stable update
          # key: -> it.key

          # node is one of the nodes cloned from the original book element
          # and the data is entry bound to node from myBookList.
          handler: ({node,data,name}) ->

in list config, you can use all configs available for a generic items. for example,

    book:
      list: -> ...
      init: ({node, data, name, idx}) ->
      handler: ({node, data, name, idx}) -> ...
      text: -> ...
      action: click: ({node, name, evt, idx}) -> ...


### Loop with Nested View

Usually you will want to render nodes below the looped element:

  .shelf
    div(ld-each="book")
      .name(ld="name") Sample Name
      .author(ld="author") Sample Author

This requires a nested ldview construction like below if done manually:

    new ldview do
      handler:
        book:
          list: -> myBookList
          # manual approach - use init to create nested view.
          # for illustration only, don't replicate.
          init: ({node,data}) ->
            (new ldview do
               root: node,
               handler:
                 name: (.node.textContent = data.name)
                 author: (.node.textContent = data.author)
            ).render!

however, ldview already does this for you. Simply move the view config under `view` field after `list`:

    new ldview do
      handler:
        book:
          list: -> myBookList
          # here is the trick
          view:
            handler:
              name: ({node, ctx}) -> node.textContent = ctx.name
              author: ({node, ctx}) -> node.textContent = ctx.author

In nested case, following constructor fields inherits the parent view configs unless you overwrite them explicitly:

 - `initRender`
 - `root`
 - `baseViews`
 - `ctx`
 - `ctxs`

When you apply nested config with circular reference to itself, you can then construct a recursive view:

    viewcfg = {}
    viewcfg.handler = book:
      list: ({ctx}) -> ctx.child
      view: viewcfg

Check `Recursive Views and Template` section below.


### Partial Rendering

After initialization, You probably will want to update some elements instead of updating every node. Just pass target names into render function:

    view = new ldview( ... );
    view.render!
    # after some updates ... only update ld="name" elements.
    view.render <[name]>

For updating partial entries in `ld-each`, use following syntax with keys:

    view.render {name: 'some-ld-each-name', key: [key1, key2, ... ]}

Be sure to make sure keys here matches the return value of `key` accessor, in case of matching failure.


### Customize ld-each Behavior / List Optimization

You can also specify `host` parameter to tell ldview how to process child elements. For example, with a large list of data, we may want to use `@loadingio/vscroll` for virtual scrolling, which effectively reduces amount of elements in the DOM tree:

    new ldview({
      handler:
        item:
          host: vscroll.fixed
          list: -> ...
          ...
    })

where the `host` parameter should be a constructor that mimic basic DOM element interface. For more information, check `@loadingio/vscroll`.


### Nested View and Scoping

You can use nested view on a non-looping selector, which makes you possible to reuse configs and provide better modularization:

    viewcfg = text: name: ({ctx}) -> ctx.name
    new ldview(
      {
        handler:
          userInfo: viewcfg
          classInfo: viewcfg
      },
      viewcfg
    )

however, this also introduces name conflict if selectors with the same name are used across modules, so you may want to prevent ldview from selecting nodes that belongs to nested views, such as `name` in below DOM:

    div(ld="name")
    div(ld="userInfo"): div(ld="name")
    div(ld="classInfo"): div(ld="name")

To separate the scope of interest, use `ld-scope` tag to scope the DOM fragment:

    div(ld="name")
    div(ld-scope="scope-name-1",ld="userInfo"): div(ld="name")
    div(ld-scope="scope-name-2",ld="classInfo"): div(ld="name")

ldview also provides a `scope` pug mixin and `scope` function in ldview's `index.pug`:

    include /path-to-ldview/index.pug
    +scope("scope-name")
      div(ld="node-name") my element.

`ld-scope` prevents other views to look up elements inside it.


### Using Scope with Prefix for Mixed Views

If you want to mix views, you can set the scope to `naked` by adding a `naked-scope` class:

    +scope("scope-name").naked-scope
      div(ld="node-name") my element

This will output following:

    <div ld="node-name"> my element </div>

While this seems to equal to doing nothing, you can prefix `ld` attribute by `scope-name` with `prefix` function in order to distinguish elements for different views:

    +scope("scope-name").naked-scope
      div(ld=prefix("node-name")) my element
      div(ld="global-name") global element

becomes

    <div ld="scope-name$node-name"> my element </div>
    <div ld="global-name"> global element </div>

To access prefix-ed node, adding `prefix` option when initializing ldview:

    var localView = new ldview({prefix: 'scope-name', handler: {
      "node-name": function(node) { ... }
    });
    var localNode = localView.get("node-name");

    var globalView = new ldview({handler: {
      "node-name": function(node) { ... }
    });
    var globalNode = globalView.get("global-name");


Basically `Scope` and `Prefix` are mutual exclusive; with `scope` you don't have to prefix since only you can access `ld` elements within this scope.


## Configurations

Construct a ldview object with one (or more) configuration object with following fields:

 * `root` - view root
 * `handler` - object containing name / handler pairs.
   - name will be used when querying DOM in `ld` attribute.
   - handler accept an object as argument:
   - node: the target node
 * `action` - action handler. object containing event names such as click, mousemove, etc.
   - each member contains a handler object similar to the root handler.
   - example:

    action: {
      click: {
        buy: ({node, evt}) -> ...
      }
      change: {
        name: ({node, evt}) -> ...
        title: ({node, evt}) -> ...
      }

 * `prefix` - prefix name for this view. view will be global if scope name is not defined.
   this should be used along with the scope pug mixin.
 * `initRender` - if set to true, ldview automatically calls render immediately after initialized. default true
 * `global` - set true to use `pd` and `pd-each` for access nodes globally beyond ld-scope. default false.
 * `ctx` - default data accessible with in handler functions. can be set later with `setContext` api.
   - `context` is used as `ctx` before `0.1.0`, and it's now `ctx`.
 * `template` - template DOM for replacing root content. It's for supporting recursive views.
 * `ctxs` and `baseViews` - these config are used internally. Don't use this unless you know what's your doing.


## API

 * new ldview({root, handler , ...})
   handler: hash with node-names as key and function as value.
   - function: ({node}) which node is the element matched with this node-name.
 * view.getAll("node-name") - return a list of nodes in the name of node-name.
 * view.get("node-name") - return the first node with the name of node-name. shorthand for getAll(...)[0]
 * view.init(cfg) - return a Promise that resolves after all init resolves.
 * view.render(cfg)
 * view.ctx(v) - set a custom context object for using in handler functions.
   - return current context if `v` is not defined.
   - `setCtx()` is used before `2.0.0`. use `ctx()` now.
   - `setContext()` is used before `0.1.0`. use `ctx()` now.
 * view.bindEachNode({container, name, node, idx})
   - ldview keeps track of nodes once they are created as in ld-each.
     If for some reason we need a node to be removed from ld-each list but use in other place ( e.g.,
     when dragging outside we need the dragged node to exist for better user experience ), we can
     unbind it and rebind it later.
   - while node is removed from / inserted into ld-each node list, these functions wont update data.
     User should update data themselves otherwise inserted node will be deleted / removed node will
     be re-created in the next render call.
   - parameters:
     - container: container of these ld-each nodes.
     - idx: index to insert this node.
     - node: node to be inserted.
     - name: name of ld-each.
 * view.unbindEachNode({container, name, node, idx})
   - counterpart of bindEachNode.
   - parameters:
     - container: container of these ld-each nodes.
     - idx: if provided, remove node in this position and return it.
     - node: if idx is not provided, user can use the node itself to hint ldview.
     - name: name of ld-each.


## Handler Parameters

When handlers for each ld node is called, it contains following parameters:

 * `node` - current node
 * `names` - all name in ld/pd for current node, space separated.
 * `name` - matched name for current handler of this node.
 * `idx` - index of current node, if this rule matches multiple times.
 * `local` - local data for storing information along with the node, in its life cycle.
 * `ctx` - view-wise data, set via `setCtx` API. default null.
   - `context` is used before 0.1.0. use `ctx` now.
 * `data` - only for `ld-each` node. bound data for this node.
 * `evt` - event object if this handler is an event handler.
 * `evts` - hash for listing all bound events.
 * `ctxs` - contexts in all parent view when using nested view feature.
 * `views` - list of views (including views built recursively) for invoking this handler
   - `views[0]` is always the current view. larger number gets ancestor views.


## Recursive Views and Template

It's possible to define view recursively - simply refer a view config in itself:

    viewcfg = {}
    viewcfg.handler = someDirective:
      list: -> ...
      view: viewcfg

Please note that the first `viewcfg = {}` is necessary since cfg won't be available for recursive definition when we initialize it, such as:

    viewcfg = handler: someDirective: {
      list: -> ...
      # incorrect: cfg is not available here.
      view: viewcfg
    }

Additionally, we need also a recursively defined DOM, which is only possible with `template` option:

    div(data-name="template"): ...
    script(type="text/livescript").
      cfg = {}
      new ldview cfg <<< {
        template: document.querySelector('div[data-name=template]')
        handler: someDirective: {
          list: ({ctx}) -> ...
          view: cfg
        }
      }

In this case, the div named `template` will be cloned, attached and used as inner DOM of this view, recursively applied according to the return content of `list`. For a working example, check `web/src/pug/recurse/index.ls`.

Also please note that `ctx` should not be defined in the reused `cfg`, otherwise it may cause infinite recursive calls, leading to maximal callstack exceeded exception. Following is a correct example:

    viewcfg = {}
    viewcfg.handler = myselector: view: viewcfg
    rootcfg = ldview.merge({ctx: mydata}, viewcfg)

or
    viewcfg = {}
    rootcfg = {ctx: mydata} <<< viewcfg <<< handler: myselector: view: viewcfg


A workable, complete example with both JS and HTML (written in Pug) is as below:

    //- HTML
    .template #[div(ld="title")]#[div(ld-each="child")]
    #root

    # JS - DATA
    ctx = name: "root", list: [
    * name: "entry1", list: [{name: "sub entry 1.1"}]
    * name: "entry2", list: [{name: "sub entry 2.1"}, {name: "sub entry 2.2"}]
    * name: "entry3", list: [{name: "sub entry 3.1"}, {name: "sub entry 3.2"}]
    ]
    # JS - View Code
    cfg = {}
    cfg <<<
      text: title: ({ctx}) -> ctx.name
      handler: child:
        view: cfg
        list: ({ctx}) -> ctx.list or []
    view = new ldview({root: root, ctx: -> list} <<< cfg)


## Nested Views and Template

As described above, it's possible to nest a view in a selector:

    new ldview({
      handler: localView:
        handler: ...
    });

And we use `ld-scope` to prevent selectors inside localView to be accessed by parent view:

    div(ld-scope,ld="localView"): ...


It can also be accomplished via `template`, which is by default scoped:

    new ldview({
      handler: localView:
        template: ...
        handler: ...
    });

You can also define a ctx function, with parent ctx in its parameter:

    new ldview({
      ctx: -> { node: { name: "something" }}
      handler: localView:
        template: ...
        ctx: ({ctx}) -> ctx.node
        handler: ...
    });

    
check `web/src/pug/scope/index.ls` for a working example of template-based local views.


## Class API

 - `merge(a, b, ...)`: merge view config objects and returns the merged result.


## License

MIT

