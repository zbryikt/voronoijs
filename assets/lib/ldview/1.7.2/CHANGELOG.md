# Change Logs

## v2.0.0 (TBD)

 - remove deprecated `ldView`
 - only update one of module or window
 - remove `setContext()` and `setCtx()`, in favor of `ctx()`.


## v1.7.2

 - fix bug: ctxs in ctx of nested view isn't correct


## v1.7.1

 - fix bug: ldview.merge doesn't work correctly when field to merge is false after converting to boolean


## v1.7.0

 - support Promise with render


## v1.6.0

 - support ctx in nested view with parameters as handlers


## v1.5.2

 - remove @loadingio/ldquery dependency
 - upgrade dependencies


## v1.5.1

 - fix typo in pug mixin `scope`


## v1.5.0

 - add `merge` class api
 - support multiple configuration in constructor arguments.


## v1.4.3

 - fix bug: `''` treated as undefined and thus can't be mapped to a node, causing node not found issue.


## v1.4.2

 - fix bug: incorrect variable used in checking `consumed`.


## v1.4.1

 - fix bug: duplicated keys in `ld-each` `list` may leave orphan nodes undeleted.
 - npm audit fix


## v1.4.0

 - by default update ctx via functional ctx before rendering


## v1.3.2

 - remove unnecessary log


## v1.3.1

 - fix bug: subview rendering should update `ctxs`
 - add internal `ctxs` api for updating `ctxs`
 - upgrade dependencies


## v1.3.0

 - support functional `ctx` parameter for returning customized context especially useful for nested views.


## v1.2.1

 - fix bug: `ctx()` should test argument's existence with `arguments.length`


## v1.2.0

 - add `ctx()` function to replace `setCtx()`.


## v1.1.1

 - fix bug: proc-each should return Promise, instead of list of Promises
 - fix bug: ensure correct initialization order by waiting for init Promise to resolve before render when `init-render` is enabled.
 - fix bug: nested view initialization should return Promise returned by its own init function call.


## v1.1.0

 - support promise in `init` ( but not yet support render after init resolve )
 - add `view.init`


## v1.0.0

 - upgrade dev modules
 - release with compact directory structure


## v0.2.8

 - use minimized dist file as main / browser default file
 - further minimize minimized file
 - upgrade modules


## v0.2.7

 - fix bug: nested ld-eachs are not proper scoped.
   - to proper fix this we may need a breaking changes with upgraded ldquery dependency.
   - we workaround this for now and expect to remove the workaround in next major release.
 - fix bug ( caused by 0.2.5 ): context for nested views from ld-each doesn't updated by its data


## v0.2.6

 - dont insert ld-each comment if host provided since we don't need pivot from comment.


## v0.2.5

 - support nested local view


## v0.2.4

 - support virtual container


## v0.2.3

 - fix main entry point file name


## v0.2.2

 - add `template` to support recursive views
 - prevent internal view from overwriting options provided by ldview logic 


## v0.2.1

 - support refering to view root with name `@`.
 - support multiple arguments in `render` function.


## v0.2.0

 - only check direct parent instead of ancestor to verify if ld-each node has been processed.


## v0.1.1

 - fix bug: ldview is not in window


## v0.1.0

 - add `ctxs` for nested views.
 - add `ctx` as `context` shorthand. deprecate `context` and expect it to be removed in future major update.
 - add `views` for nested views. views are passed with `baseViews` option.
 - tweak building script and output file names / paths
 - generate with `--no-header` and wrap code with -p in livescript compilation.


## v0.0.2

 - add `attr` and `style` directive. 
 - add `view` directive for nested view for `ld-each`.
