
$(document).ready(function() {

  Trek.map = new OpenLayers.Map("map");
  Trek.map.addLayer(new OpenLayers.Layer.OSM());

  Trek.map.addLayer(new OpenLayers.Layer.XYZ("fake", "/img/blank.gif"));
  Trek.map.addControl(new OpenLayers.Control.LayerSwitcher());


  Trek.loadingFinished = function(obj) {
    if (Trek.gpx_layer.getDataExtent() == null) return;
    Trek.map.zoomToExtent(Trek.gpx_layer.getDataExtent(), false);
  }


  if (Trek.gpx) {

    Trek.gpx_layer = new OpenLayers.Layer.GML("Trek", Trek.gpx, {
        format: OpenLayers.Format.GPX,
        style: {
          strokeColor: "black",
          strokeWidth: 4,
          strokeOpacity: 1
        },
        projection: new OpenLayers.Projection("EPSG:4326")
    });

    Trek.gpx_layer.events.register("loadend", Trek.gpx_layer.events, Trek.loadingFinished);
    Trek.map.addLayer(Trek.gpx_layer);
  }
  Trek.map.zoomToMaxExtent();

});

