# Session cookie durcie (HttpOnly, SameSite=Lax, Secure en production)
Rails.application.config.session_store :cookie_store,
                                       key: '_sharemybag_session',
                                       httponly: true,
                                       same_site: :lax,
                                       secure: Rails.env.production?
