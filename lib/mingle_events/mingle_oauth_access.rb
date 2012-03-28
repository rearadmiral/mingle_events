module MingleEvents 
  
  # Client for Mingle's experimental OAuth 2.0 support in 3.0
  #--
  # TODO: Update error handling and support of fetching response
  # objects to that of MingleBasicAuthAccess
  class MingleOauthAccess
    attr_reader :base_url
    
    def initialize(base_url, token)
      @base_url = base_url
      @token = token
    end

    def fetch_page(location)
      location  = @base_url + location if location[0..0] == '/' 
      Http.get(location, 'Authorization' => %{Token token="#{@token}"})
    end
  end
end
