
$(document).ready(function() {

  Trek.map = new OpenLayers.Map("map");
  Trek.map.addLayer(new OpenLayers.Layer.OSM());


  /* Bwah, does not work ... yet
   * Should discuss with sly around a beer
   * someday ... */
  /*
  Trek.map.addLayer(new OpenLayers.Layer.TMS(
                          "Sly's hiking",
                          ["http://beta.letuffe.org/tiles/renderer.py/hiking/"],
                          {
                            type:'jpeg',
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
                            displayOutsideMaxExtent: true
                          },
                          { 'buffer':0 }
                    )
  );
  */

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
        projection: new OpenLayers.Projection("EPSG:4326")
    });

    Trek.gpx_layer.events.register("loadend", Trek.gpx_layer.events, Trek.loadingFinished);
    Trek.map.addLayer(Trek.gpx_layer);
  }
  Trek.map.zoomTo(3);

});

