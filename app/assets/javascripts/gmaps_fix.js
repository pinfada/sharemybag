// ========================================
// ShareMyBag - Gmaps4Rails Fix
// ========================================
// Correctifs pour la compatibilité gmaps4rails avec Turbolinks

(function() {
  'use strict';

  // S'assurer que google est défini avant gmaps4rails
  if (typeof Gmaps !== 'undefined' && Gmaps.Google) {
    var originalPrimitives = Gmaps.Google.Primitives;

    Gmaps.Google.Primitives = function() {
      // Attendre que Google Maps soit chargé
      if (typeof google === 'undefined' || !google.maps) {
        console.warn('Google Maps not yet loaded, delaying gmaps4rails initialization');
        return;
      }

      // Attendre MarkerClusterer si nécessaire
      if (typeof MarkerClusterer === 'undefined' && typeof MarkerClustererPlus !== 'undefined') {
        window.MarkerClusterer = MarkerClustererPlus;
      }

      // Si MarkerClusterer n'est toujours pas disponible, le créer en placeholder
      if (typeof MarkerClusterer === 'undefined') {
        window.MarkerClusterer = function() {
          console.warn('MarkerClusterer not available, clustering disabled');
          return {
            addMarker: function() {},
            clearMarkers: function() {},
            getMarkers: function() { return []; }
          };
        };
      }

      // Appeler la fonction originale
      if (originalPrimitives) {
        return originalPrimitives.apply(this, arguments);
      }
    };
  }

  // Gérer le rechargement avec Turbolinks
  document.addEventListener('turbolinks:load', function() {
    // Réinitialiser gmaps4rails si nécessaire
    if (typeof Gmaps !== 'undefined' && Gmaps.loadMaps) {
      // Vérifier si Google Maps est chargé
      if (typeof google !== 'undefined' && google.maps) {
        // Recharger les cartes gmaps4rails
        Gmaps.loadMaps();
      }
    }
  });

  // Nettoyer avant le cache Turbolinks
  document.addEventListener('turbolinks:before-cache', function() {
    // Nettoyer les cartes gmaps4rails
    if (typeof Gmaps !== 'undefined' && Gmaps.maps) {
      for (var mapId in Gmaps.maps) {
        if (Gmaps.maps.hasOwnProperty(mapId)) {
          var map = Gmaps.maps[mapId];
          if (map && map.cleanup) {
            map.cleanup();
          }
        }
      }
      Gmaps.maps = {};
    }
  });

  // Helper pour charger Google Maps de manière asynchrone
  window.loadGoogleMapsAPI = function(apiKey, callback) {
    if (typeof google !== 'undefined' && google.maps) {
      if (callback) callback();
      return;
    }

    // Créer la callback globale
    window.googleMapsCallback = function() {
      // Charger MarkerClusterer après Google Maps
      var clusterScript = document.createElement('script');
      clusterScript.src = 'https://unpkg.com/@googlemaps/markerclustererplus/dist/index.min.js';
      clusterScript.onload = function() {
        if (typeof MarkerClustererPlus !== 'undefined') {
          window.MarkerClusterer = MarkerClustererPlus;
        }
        if (callback) callback();
      };
      document.head.appendChild(clusterScript);
    };

    // Charger Google Maps
    var script = document.createElement('script');
    script.src = 'https://maps.googleapis.com/maps/api/js?key=' + apiKey +
                 '&callback=googleMapsCallback&loading=async';
    script.async = true;
    script.defer = true;
    document.head.appendChild(script);
  };

})();