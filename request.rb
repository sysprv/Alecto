#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

require 'java'

# Used to hide implementation details of various http containers
# (Jetty, (Ruby) Rack, com.sun.net.httpserver etc.) from Alecto.
#
# Does not support streaming.
class Request
    # TODO: headers
    attr_reader :request_method, :query_string, :path_info, :body

    def initialize(request_method, query_string, path_info, body)
        @request_method = request_method
        @query_string = query_string
        @path_info = path_info
        @body = body
    end

    def Request.buffered_body_from_servlet_request(servlet_req)
        if servlet_req.getMethod().upcase() == 'POST' then
            req_content_length = servlet_req.getContentLength()
            if req_content_length.nil? then
                logger = Java::OrgSlf4j::LoggerFactory::getLogger(Request.name)
                logger.warning('No content length set in POST request')
            end

            io = servlet_req.getInputStream().to_io()
            # read the complete request body, and return it
            io.read()
        else
            nil
        end
    end

    def Request.fromServletRequest(servlet_request)
        body = Request.buffered_body_from_servlet_request(servlet_request)

        Request.new(servlet_request.getMethod().upcase(),
                    servlet_request.getQueryString(),
                    servlet_request.getPathInfo(),
                    body)
    end
end

