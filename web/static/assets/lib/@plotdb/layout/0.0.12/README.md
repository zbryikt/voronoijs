# @plotdb/layout

Compute chart layout by HTML/CSS.


# Usage

We will need 3 elements:

 - root node: containing layout and render node. should set with `pdl-layout` class.
 - layout node: provide layout information with `div.pdl-cell` for `g.pdl-cell` with the same `data-name` attr.
 - render node: containing `g.pdl-cell` element corresponding to `pdl-cell` in layout node.

A sample DOM structure in Pug:
 
    #my-chart.pdl-layout
      div(data-type="layout")
        .pdl-cell(data-name="yaxis")
        .pdl-cell(data-name="view")
        .pdl-cell
        .pdl-cell(data-name="xaxis")
      div(data-type="render")
        svg
          g.pdl-cell(data-name="yaxis")
          g.pdl-cell(data-name="view"): rect(ld-each="data")
          g
          g.pdl-cell(data-name="xaxis")


then, init with JS:

    mylayout = new layout({root: '#my-chart'})
    mylayout.on \render, ->
      d3.select('g.pdl-cell[data-name=view]').call ->
        /* get corresponding node and related size (box{x,y,width,height}) information */
        @layout{node, box}
      @get-box('name') # get bounding box with given name
      @get-node('name') # get DOM node with given name
      @get-group('name') # get `g` (group) with given name
    mylayout.init -> ... /* initializing ... */


when the layout object is no longer needed, one should destroy it:

    mylayout.destroy!


## Configuration

 - `autoSvg`: true if automatically create corresponding `svg` and `g` element. default true
   - even with `autoSvg` enabled, user can still prepare partial svg / g elements. `@plotdb/layout` will fill the missing parts automatically.
 - `watchResize`: true if automatically calls `update` when container resized. default true.
   - by disabling this you will have to manually call `update` when you want to update layout.
 - `round`: set true to automatically round dimensions. default true.


## API

 - `init(cb)`: initialize layout. optional `cb` callback function.
   - `cb()`: a function called before `update` but after groups are prepared.
     - run with the context of the inited layout object.
     - if it returns a promise, `@plotdb/layout` waits until it resolves before calling `update`
 - `root()`: get root node
 - `getNode(name)`: get layout node by `name`
 - `getNodes`: get all layout nodes in an object, hashed by names
 - `getGroup(name)`: get render `g` by `name`
 - `getGroups`: get all render `g` in an object, hashed by names
 - `getBox(name,cached)`: -> get bounding client rect or node by `name`.
   - `cached`: return cached version if true. default false ( computed in realtime )
 - `update(opt)`: update layout. ( update position of all groups )
   - fire rendering event if `opt` is `true`. default false.
 - `destroy()`: destroy function
 - `on(n,cb)`: handle `n` event with `cb` callback function.
 - `fire(n, ...v)`: fire `n` event with parameters in v.

## SVG styling

when rendering text manually with SVG, one should be aware of following settings:

 - `line-height` should be `1em` in HTML layout.
 - `dominant-baseline` should be `hanging` in SVG text.


## License

MIT
