# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_bcms_google_mini_search_session',
  :secret      => '964dce06fe6abb6e84410b19c08e8ca1c8d4aa76b19afa6d19efae8d64b9325f0745d9e36f773970316b055e805d152965dbce5510f49ef32bdc86400b05f5af'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
