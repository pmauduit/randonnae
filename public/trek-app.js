
$(document).ready(function() {

  Trek.hover = function(lat, lon) {
    if ((lat === 'undefined') || (lon === 'undefined')) {
      return;
    }
    // Should not happen
    if (Trek.poi_layer === 'undefined') {
      return;
    }
    Trek.poi_layer.removeAllFeatures();
    newGeom = new OpenLayers.Geometry.Point(lon, lat);
    newGeom.transform(Trek.epsg4326, Trek.epsg900913);
    Trek.map.setCenter(new OpenLayers.LonLat(newGeom.x,newGeom.y));
    newFeat = new OpenLayers.Feature.Vector(newGeom);
    newFeat.style = {
      'pointRadius': 16,
      'graphicYOffset': -32,
      'externalGraphic': '/here.png'};
    Trek.poi_layer.addFeatures([newFeat]);

  }

  Trek.epsg4326 = new OpenLayers.Projection("EPSG:4326");
  Trek.epsg900913 = new OpenLayers.Projection("EPSG:900913");
  Trek.map = new OpenLayers.Map("map");


  /* Bwah, does not work ... yet
   * Should discuss with sly around a beer
   * someday ... */
  /*
  Trek.map.addLayer(new OpenLayers.Layer.TMS(
                          "Sly's hiking",
                          ["http://beta.letuffe.org/tiles/renderer.py/hiking/"],
                          {
                            type:'png',
                            getURL: function(bounds) {
                              var res = this.map.getResolution();
                              var x = Math.round ((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
                              var y = Math.round ((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
                              var z = this.map.getZoom();
                              var limit = Math.pow(2, z);

                              if (y < 0 || y >= limit) {
                                return null;
                              }
                              else {
                                return this.url + z + "/" + x + "/" + y + "." + this.type;
                              }
                            },
                            transitionEffect: 'resize',
                            projection: Trek.epsg900913,
                            displayOutsideMaxExtent: true
                          },
                          { 'buffer':0 }
                    )
  );
  */
  Trek.map.addLayer(new OpenLayers.Layer.OSM("Cycle map",
          ["http://a.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png",
           "http://b.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png",
           "http://c.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png"]));

  Trek.map.addLayer(new OpenLayers.Layer.OSM());
  Trek.poi_layer = new OpenLayers.Layer.Vector("Picture POIs");

  Trek.map.addControl(new OpenLayers.Control.LayerSwitcher());


  Trek.loadingFinished = function(obj) {
    if (Trek.gpx_layer.getDataExtent() == null) return;
    Trek.map.zoomToExtent(Trek.gpx_layer.getDataExtent(), false);
  }


  if (Trek.gpx) {

    Trek.gpx_layer = new OpenLayers.Layer.GML("Trek", Trek.gpx, {
        format: OpenLayers.Format.GPX,
        style: {
          strokeColor: "#c62828",
          strokeWidth: 4,
          strokeOpacity: 1
        },
        projection: new OpenLayers.Projection("EPSG:4326"),
        renderers: ['Canvas', 'SVG2', 'SVG']
    });

    Trek.gpx_layer.events.register("loadend", Trek.gpx_layer.events, Trek.loadingFinished);
    Trek.map.addLayer(Trek.gpx_layer);
  }
  Trek.map.zoomTo(3);
  Trek.map.addLayer(Trek.poi_layer);

  //loading gallery
  function carousel_getItemHTML(id,item) {
    return '<li><a href='+item.minimage+'>'
      +' <img id="gallery_item'+id+'"  onmouseover="javascript:Trek.hover('+item.lat
      + ',' + item.lon + ')" src="'
      + item.thumbnail + '" alt="" width="75" height="75" '
      +'/></a></li>';
  };

  function load_images(carousel, state) {
    if (state != 'init') return;

    $.getJSON(Trek.baseUrl + "/imgs", function(data) {
      Trek.images = [];

      $.each(data, function(key, val) {
        Trek.images.push(val);
      });

      for (i = 0; i < Trek.images.length ; i++) {
        carousel.add(i+1, carousel_getItemHTML(i, Trek.images[i]));
        // setting title
        imgTitle = Trek.images[i].filename;
        $('#gallery_item'+i).attr("title", imgTitle);
      }
      carousel.size(Trek.images.length);
      // Lightbox
      $(function() {
        $('#carousel a').lightBox({
          fixedNavigation:true
        });
      });
    });
  }

  $('#carousel').jcarousel({
    itemLoadCallback: load_images
  });

  // loading elevation graph
  Trek.eledatas = [];
  $.getJSON(Trek.baseUrl + "/details", function(data) {
    $.each(data, function(key, val) {
      Trek.eledatas.push([key, parseFloat(val.ele)]);
    });
    //Trek.eledatas = data;

    $.plot($('#trekgraph'), [{
      data: Trek.eledatas,
      show: true
    }]);
  });

});

