module MingleEvents 
  
  # Supports fetching of Mingle resources using HTTP basic auth.
  # Please only use this class to access resources over HTTPS so
  # as not to send credentials over plain-text connections.
  class MingleBasicAuthAccess
    
    attr_reader :base_url

    def initialize(base_url, username, password)
      @base_url = base_url
      @username = username
      @password = password
    end
    
    def fetch_page(location)
      location = @base_url + location if location[0..0] == '/' 
      Http.get(location, 'authorization' => Http.basic_encode(@username, @password))
    end
  end
end
