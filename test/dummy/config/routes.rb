Rails.application.routes.draw do

  mount BcmsGoogleMiniSearch::Engine => "/bcms_google_mini_search"
	mount_browsercms
end
