#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

require 'net/http'
require 'uri'
require 'pp'
require 'shimutil'

class ShimRequest
    # TODO: headers
    attr_reader :request_method, :query_string, :path_info, :body

    def initialize(request_method, query_string, path_info, body)
        @request_method = request_method
        @query_string = query_string
        @path_info = path_info
        @body = body
    end

    def ShimRequest.fromSinatraRequest(sinatra_request)
        body = if sinatra_request.request_method.upcase == 'POST' and
            defined?(sinatra_request.content_length) and sinatra_request.content_length > '0' then
            sinatra_request.body.read
        else
            nil
        end

        ShimRequest.new(sinatra_request.request_method,
            sinatra_request.query_string,
            sinatra_request.path_info,
            body)
    end

    def ShimRequest.fromServletRequest(sr, body)
        ShimRequest.new(sr.getMethod(),
            sr.getQueryString(),
            sr.getPathInfo(),
            body)
    end
end

