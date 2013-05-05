
$(document).ready(function() {

  Trek.unknown_location = function() {
    if (Trek.poi_layer === 'undefined') {
      return;
    }
    Trek.poi_layer.removeAllFeatures();
  }

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

  // loading elevation graph
  Trek.eledatas = [];
  $.getJSON(Trek.baseUrl + "/details", function(data) {
    $.each(data, function(key, val) {
      Trek.eledatas.push([key, parseFloat(val.ele)]);
    });

    $.plot($('#trekgraph'), [{
      data: Trek.eledatas,
      show: true
    }]);
  });

});

$(document).ready(function() {
  $('#carousel').jcarousel({
    'list': '.jcarousel-list'
  });
    // Lightbox
    $(function() {
      $('#carousel a').lightBox({
        fixedNavigation:true
      });
    });
});

