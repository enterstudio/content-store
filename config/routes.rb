Rails.application.routes.draw do
  scope format: false do
    # The /api/content route is used for requests via the public API
    get "/api/content(/*base_path_without_root)" => "content_items#show", :as => :content_item_api, :public_api_request => true

    get "/content(/*base_path_without_root)" => "content_items#show", :as => :content_item
    put "/content(/*base_path_without_root)" => "content_items#update"
    delete "/content(/*base_path_without_root)" => "content_items#destroy"

    get "/incoming-links(/*base_path_without_root)" => "linked_items#incoming_links"
    get "/api/incoming-links(/*base_path_without_root)" => "linked_items#incoming_links", :public_api_request => true

    get "/publish-intent(/*base_path_without_root)" => "publish_intents#show"
    put "/publish-intent(/*base_path_without_root)" => "publish_intents#update"
    delete "/publish-intent(/*base_path_without_root)" => "publish_intents#destroy"
  end

  get "/healthcheck", :to => proc { [200, {}, ["OK"]] }
  get "/debug/taggings-per-app" => "debug#taggings_per_app"
end
