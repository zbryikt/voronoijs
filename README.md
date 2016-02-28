Voronoi.js
----------

![Voronoi Treemap Example](http://zbryikt.github.io/voronoijs/img/example.png)

Voronoi.js is a Voronoi treemap generator in JavaScript. [Demonstration](http://zbryikt.github.io/voronoijs/)


Usage
==========

Include [voronoi.min.js](http://raw.githubusercontent.com/zbryikt/voronoijs/master/dist/voronoi.min.js):

    <script type="text/javascript" src="voronoi.min.js"></script>

then, prepare your data:

    var data = {
      children: [
        {value: 100},
        {value: 200},
        {value: 300}
      ],
    };

and initialize a voronoi treemap instance:

    var width = 800, height = 600;
    var treemap = new Voronoi.Treemap(data, Polygon.create(width, height, 100), width, height);

compute and render your treemap as your wish:
 
    setInterval(function() {
      treemap.compute();
      render();
    }, 100);

    function render() {
      var polygons = treemap.getPolygons(); /* Polygons for treemap */
      var sites = treemap.getSites(); /* correspond to every data node */
    }

here we have polygons as point array, for example, a triangle:

    [{x: 0, y: 0}, {x: 100, y: 100}, {x: 200, y: 100}]


and coordinates in data nodes:

    {value: 100, x: 23.4849230, y: 123: 12671238, lv: 0}, ...

You can use _lv_ to determine depth of the node.


License
==========
[MIT License.](http://raw.githubusercontent.com/zbryikt/voronoijs/master/LICENSE)
