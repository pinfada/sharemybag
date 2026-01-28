RailsAdmin.config do |config|
  config.asset_source = :sprockets

  config.main_app_name = ["ShareMyBag", "Admin"]

  config.authenticate_with do
    redirect_to(main_app.root_path, alert: "Not authorized") unless current_user&.admin?
  end

  config.current_user_method(&:current_user)

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end
end
