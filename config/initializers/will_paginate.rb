# Configuration pour will_paginate avec Bootstrap 5
# La gem will_paginate-bootstrap-style gère automatiquement l'intégration avec Bootstrap

if defined?(WillPaginate)
  module WillPaginate
    module ActiveRecord
      module RelationMethods
        def per(value = nil) per_page(value) end
        def total_count() count end
        def first_page?() self == first end
        def last_page?() self == last end
      end
    end
    module CollectionMethods
      alias_method :num_pages, :total_pages
    end
  end

  # Configuration des labels par défaut pour Bootstrap
  WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&laquo; Précédent'
  WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Suivant &raquo;'

  # Nombre d'éléments par page par défaut
  WillPaginate.per_page = 10
end