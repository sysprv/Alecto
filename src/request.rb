#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

require 'json'
require 'ioutilities'

# Used to hide implementation details of various http containers
# (Jetty, (Ruby) Rack, com.sun.net.httpserver etc.) from Alecto.
#
# Does not support streaming.
class Request
    include IoUtilities

    # TODO: headers
    attr_reader :request_method, :query_string, :path_info,
        :content_type, :character_encoding, :body

    def initialize(servlet_request)
        @request_method = servlet_request.getMethod().upcase()
        @query_string = servlet_request.getQueryString()
        @path_info = servlet_request.getPathInfo()
        @content_type = servlet_request.getContentType()
        @character_encoding = servlet_request.getCharacterEncoding() || 'UTF-8'
        @body = body_from_servlet_request(servlet_request)
    end

    def summary
        ret = {
            :request_method => @request_method,
            :query_string => @query_string,
            :path_info => @path_info,
            :content_type => @content_type,
            :character_encoding => @character_encoding,
            :body_nil? => body.nil?.to_s,
            :body_length => if not body.nil? then
                body.length
            else
                0
            end
        }

        JSON.pretty_generate(ret)
    end
end

