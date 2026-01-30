// ========================================
// ShareMyBag - Google Maps Loader
// ========================================
// Gestion du chargement asynchrone de Google Maps avec Turbolinks

(function() {
  var GoogleMapsLoader = {
    apiKey: null,
    isLoaded: false,
    isLoading: false,
    callbacks: [],
    markers: [],

    // Initialisation avec la clé API
    init: function(apiKey) {
      this.apiKey = apiKey;
      this.setupTurbolinksEvents();
    },

    // Configuration des événements Turbolinks
    setupTurbolinksEvents: function() {
      var self = this;

      // Nettoyer avant de naviguer
      document.addEventListener('turbolinks:before-cache', function() {
        self.cleanupMap();
      });

      // Recharger après navigation
      document.addEventListener('turbolinks:load', function() {
        self.checkAndLoadMap();
      });
    },

    // Vérifier et charger la carte si nécessaire
    checkAndLoadMap: function() {
      var mapElement = document.getElementById('map-canvas');
      if (mapElement && mapElement.dataset.markers) {
        this.loadGoogleMaps(function() {
          GoogleMapsLoader.initializeMap(mapElement);
        });
      }
    },

    // Charger Google Maps de manière asynchrone
    loadGoogleMaps: function(callback) {
      if (this.isLoaded) {
        callback();
        return;
      }

      this.callbacks.push(callback);

      if (this.isLoading) {
        return;
      }

      this.isLoading = true;

      // Charger Google Maps
      var script = document.createElement('script');
      script.type = 'text/javascript';
      script.async = true;
      script.defer = true;
      script.src = 'https://maps.googleapis.com/maps/api/js?key=' + this.apiKey +
                   '&callback=GoogleMapsLoader.googleMapsCallback&loading=async';
      document.head.appendChild(script);

      // Charger MarkerClusterer
      var clusterScript = document.createElement('script');
      clusterScript.type = 'text/javascript';
      clusterScript.async = true;
      clusterScript.defer = true;
      clusterScript.src = 'https://unpkg.com/@googlemaps/markerclustererplus/dist/index.min.js';
      document.head.appendChild(clusterScript);
    },

    // Callback appelé quand Google Maps est chargé
    googleMapsCallback: function() {
      this.isLoaded = true;
      this.isLoading = false;

      // Attendre que MarkerClusterer soit aussi chargé
      var checkMarkerClusterer = setInterval(function() {
        if (typeof MarkerClustererPlus !== 'undefined') {
          clearInterval(checkMarkerClusterer);

          // Rendre MarkerClusterer disponible globalement pour gmaps4rails
          if (typeof MarkerClusterer === 'undefined') {
            window.MarkerClusterer = MarkerClustererPlus;
          }

          // Exécuter tous les callbacks en attente
          GoogleMapsLoader.callbacks.forEach(function(cb) {
            cb();
          });
          GoogleMapsLoader.callbacks = [];
        }
      }, 100);
    },

    // Initialiser la carte
    initializeMap: function(mapElement) {
      if (!mapElement || !window.google || !window.google.maps) {
        console.error('Google Maps not loaded properly');
        return;
      }

      try {
        var markersData = JSON.parse(mapElement.dataset.markers || '[]');

        // Utiliser gmaps4rails si disponible
        if (typeof Gmaps !== 'undefined' && Gmaps.build) {
          this.initWithGmaps4rails(mapElement, markersData);
        } else {
          // Fallback : utilisation directe de Google Maps
          this.initWithGoogleMaps(mapElement, markersData);
        }
      } catch (e) {
        console.error('Error initializing map:', e);
      }
    },

    // Initialisation avec gmaps4rails
    initWithGmaps4rails: function(mapElement, markersData) {
      var handler = Gmaps.build('Google');

      handler.buildMap({
        provider: {
          zoom: 10,
          center: { lat: 48.8566, lng: 2.3522 }, // Paris par défaut
          mapTypeControl: false,
          streetViewControl: false
        },
        internal: { id: mapElement.id }
      }, function() {
        if (markersData && markersData.length > 0) {
          var markers = handler.addMarkers(markersData);
          handler.bounds.extendWith(markers);
          handler.fitMapToBounds();

          if (markers.length == 1) {
            handler.getMap().setZoom(14);
          } else if (markers.length == 0) {
            handler.getMap().setZoom(2);
          }

          GoogleMapsLoader.markers = markers;
        }
      });
    },

    // Initialisation directe avec Google Maps (fallback)
    initWithGoogleMaps: function(mapElement, markersData) {
      var mapOptions = {
        zoom: 10,
        center: { lat: 48.8566, lng: 2.3522 },
        mapTypeControl: false,
        streetViewControl: false
      };

      var map = new google.maps.Map(mapElement, mapOptions);
      var bounds = new google.maps.LatLngBounds();
      var markers = [];

      // Ajouter les marqueurs
      markersData.forEach(function(markerData) {
        var marker = new google.maps.Marker({
          position: { lat: markerData.lat, lng: markerData.lng },
          map: map,
          title: markerData.infowindow || ''
        });

        if (markerData.infowindow) {
          var infoWindow = new google.maps.InfoWindow({
            content: markerData.infowindow
          });

          marker.addListener('click', function() {
            infoWindow.open(map, marker);
          });
        }

        markers.push(marker);
        bounds.extend(marker.getPosition());
      });

      // Ajuster la vue
      if (markers.length > 0) {
        map.fitBounds(bounds);

        if (markers.length === 1) {
          map.setZoom(14);
        }
      } else {
        map.setZoom(2);
      }

      // Clustering si beaucoup de marqueurs
      if (markers.length > 10 && typeof MarkerClusterer !== 'undefined') {
        new MarkerClusterer(map, markers, {
          imagePath: 'https://developers.google.com/maps/documentation/javascript/examples/markerclusterer/m'
        });
      }

      GoogleMapsLoader.markers = markers;
    },

    // Nettoyer la carte avant le cache Turbolinks
    cleanupMap: function() {
      // Supprimer les marqueurs
      if (this.markers && this.markers.length > 0) {
        this.markers.forEach(function(marker) {
          if (marker.setMap) {
            marker.setMap(null);
          }
        });
        this.markers = [];
      }

      // Nettoyer le contenu du div map
      var mapElement = document.getElementById('map-canvas');
      if (mapElement) {
        mapElement.innerHTML = '';
      }
    }
  };

  // Exposer GoogleMapsLoader globalement
  window.GoogleMapsLoader = GoogleMapsLoader;
})();
