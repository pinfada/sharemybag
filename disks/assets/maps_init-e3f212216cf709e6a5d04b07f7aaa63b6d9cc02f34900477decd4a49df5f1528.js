// ========================================
// ShareMyBag - Maps Initialization
// ========================================
// Solution simplifiée pour Google Maps avec Turbolinks

(function() {
  'use strict';

  var MapsInit = {
    map: null,
    markers: [],
    markerClusterer: null,

    // Initialiser une carte Google Maps
    initMap: function(elementId, markersData) {
      var mapElement = document.getElementById(elementId);
      if (!mapElement) return;

      // Options par défaut de la carte
      var mapOptions = {
        zoom: 10,
        center: { lat: 48.8566, lng: 2.3522 }, // Paris par défaut
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true,
        zoomControl: true
      };

      // Créer la carte
      this.map = new google.maps.Map(mapElement, mapOptions);

      // Ajouter les marqueurs s'il y en a
      if (markersData && markersData.length > 0) {
        this.addMarkers(markersData);
        this.fitBounds();
      }
    },

    // Ajouter des marqueurs sur la carte
    addMarkers: function(markersData) {
      var self = this;
      var bounds = new google.maps.LatLngBounds();

      markersData.forEach(function(markerData) {
        if (markerData.lat && markerData.lng) {
          var marker = new google.maps.Marker({
            position: { lat: parseFloat(markerData.lat), lng: parseFloat(markerData.lng) },
            map: self.map,
            title: markerData.title || '',
            animation: google.maps.Animation.DROP
          });

          // Ajouter une infowindow si présente
          if (markerData.infowindow) {
            var infoWindow = new google.maps.InfoWindow({
              content: markerData.infowindow
            });

            marker.addListener('click', function() {
              infoWindow.open(self.map, marker);
            });
          }

          self.markers.push(marker);
          bounds.extend(marker.getPosition());
        }
      });

      // Ajuster les limites de la carte
      if (self.markers.length > 0) {
        self.map.fitBounds(bounds);

        // Ajuster le zoom selon le nombre de marqueurs
        google.maps.event.addListenerOnce(self.map, 'bounds_changed', function() {
          if (self.markers.length === 1) {
            self.map.setZoom(14);
          } else if (self.map.getZoom() > 16) {
            self.map.setZoom(16);
          }
        });

        // Ajouter le clustering si beaucoup de marqueurs
        if (self.markers.length > 10) {
          self.addMarkerClusterer();
        }
      }
    },

    // Ajouter le clustering de marqueurs
    addMarkerClusterer: function() {
      if (typeof MarkerClusterer !== 'undefined' && this.markers.length > 0) {
        this.markerClusterer = new MarkerClusterer(this.map, this.markers, {
          imagePath: 'https://developers.google.com/maps/documentation/javascript/examples/markerclusterer/m',
          maxZoom: 15,
          gridSize: 50
        });
      }
    },

    // Ajuster les limites de la carte aux marqueurs
    fitBounds: function() {
      if (this.markers.length === 0) {
        this.map.setZoom(2);
        return;
      }

      var bounds = new google.maps.LatLngBounds();
      this.markers.forEach(function(marker) {
        bounds.extend(marker.getPosition());
      });
      this.map.fitBounds(bounds);
    },

    // Nettoyer la carte
    clearMap: function() {
      // Supprimer tous les marqueurs
      if (this.markers) {
        this.markers.forEach(function(marker) {
          marker.setMap(null);
        });
        this.markers = [];
      }

      // Supprimer le clusterer
      if (this.markerClusterer) {
        this.markerClusterer.clearMarkers();
        this.markerClusterer = null;
      }
    },

    // Détruire la carte
    destroy: function() {
      this.clearMap();
      this.map = null;
    }
  };

  // Fonction globale pour l'initialisation (callback Google Maps)
  window.initMapCallback = function() {
    var mapElement = document.getElementById('map-canvas');
    if (mapElement && mapElement.dataset.markers) {
      try {
        var markersData = JSON.parse(mapElement.dataset.markers);
        MapsInit.initMap('map-canvas', markersData);
      } catch (e) {
        console.error('Error parsing markers data:', e);
      }
    }
  };

  // Gérer Turbolinks
  document.addEventListener('turbolinks:load', function() {
    // Si Google Maps est déjà chargé et qu'il y a une carte à afficher
    if (typeof google !== 'undefined' && google.maps) {
      initMapCallback();
    } else {
      // Charger Google Maps si nécessaire
      var mapElement = document.getElementById('map-canvas');
      if (mapElement && !document.querySelector('script[src*="maps.googleapis.com"]')) {
        var apiKey = mapElement.dataset.apiKey || '';
        if (apiKey) {
          var script = document.createElement('script');
          script.src = 'https://maps.googleapis.com/maps/api/js?key=' + apiKey +
                      '&callback=initMapCallback&loading=async';
          script.async = true;
          script.defer = true;
          document.head.appendChild(script);

          // Charger aussi MarkerClusterer
          var clusterScript = document.createElement('script');
          clusterScript.src = 'https://unpkg.com/@googlemaps/markerclustererplus/dist/index.min.js';
          clusterScript.async = true;
          document.head.appendChild(clusterScript);
        }
      }
    }
  });

  // Nettoyer avant le cache Turbolinks
  document.addEventListener('turbolinks:before-cache', function() {
    if (MapsInit.map) {
      MapsInit.destroy();
      var mapElement = document.getElementById('map-canvas');
      if (mapElement) {
        mapElement.innerHTML = '';
      }
    }
  });

  // Exposer MapsInit globalement si nécessaire
  window.MapsInit = MapsInit;
})();
