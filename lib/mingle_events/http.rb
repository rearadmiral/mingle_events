module MingleEvents
  module Http
    extend self
    
    BASIC_AUTH_HTTP_WARNING = %{     
WARNING!!!
It looks like you are using basic authentication over a plain-text HTTP connection. 
We HIGHLY recommend AGAINST this practice. You should only use basic authentication over
a secure HTTPS connection. Instructions for enabling HTTPS/SSL in Mingle can be found at
<http://www.thoughtworks-studios.com/mingle/3.3/help/advanced_mingle_configuration.html>
WARNING!!
}
    MAX_RETRY_TIMES = 5

    def get(url, header={}, retry_count=0)
      rsp = fetch_page_response(url, header)
      case rsp
      when Net::HTTPSuccess
        rsp.body
      when Net::HTTPUnauthorized
        raise HttpError.new(rsp, url, %{
If you think you are passing correct credentials, please check 
that you have enabled Mingle for basic authentication. 
See <http://www.thoughtworks-studios.com/mingle/3.3/help/configuring_mingle_authentication.html>.})
      when Net::HTTPBadGateway, Net::HTTPServiceUnavailable, Net::HTTPGatewayTimeOut
        raise HttpError.new(rsp, url) if retry_count >= MAX_RETRY_TIMES
        cooldown = retry_count * 2
        MingleEvents.log.info "Getting service error when get page at #{url}, retry after #{cooldown}s..."
        sleep cooldown
        get(url, header, retry_count + 1)
      else
        raise HttpError.new(rsp, url) 
      end     
    end

    def basic_encode(account, password)
      'Basic ' + ["#{account}:#{password}"].pack('m').delete("\r\n")
    end

    private
    def fetch_page_response(url, header)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      path = uri.request_uri
      
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        MingleEvents.log.warn BASIC_AUTH_HTTP_WARNING
      end

      MingleEvents.log.info "Fetching page at #{path}..."
      
      start = Time.now
      req = Net::HTTP::Get.new(path)
      header.each do |key, value|
        req[key] = value
      end
      rsp = http.request(req)
      MingleEvents.log.info "...#{path} fetched in #{Time.now - start} seconds."
      rsp

    end
  end
end
