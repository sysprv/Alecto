# vim:set ts=8 sts=4 sw=4 ai et:

require 'pp'
require 'java'
# require './lib/slf4j-api-1.6.4.jar'
require './lib/slf4j-simple-1.6.4.jar'
# require './lib/logback-core-1.0.3.jar'
require './lib/servlet-api-3.0.jar'
require './lib/jetty-all-8.1.3.v20120416.jar'
java_import 'org.eclipse.jetty.server.Server'
java_import 'org.eclipse.jetty.server.handler.AbstractHandler'
java_import 'org.eclipse.jetty.server.handler.ResourceHandler'
java_import 'org.eclipse.jetty.server.handler.HandlerList'
java_import 'org.eclipse.jetty.server.handler.RequestLogHandler'
java_import 'org.eclipse.jetty.server.NCSARequestLog'

require 'rules'
require 'resolver'
require 'shimrequest'
require 'samplerequests'
require 'ruleloader'

class ShimHandler < org.eclipse.jetty.server.handler.AbstractHandler
    def set_servlet_response(status_code, content_encoding, headers, body, servlet_response)
        servlet_response.setStatus(status_code)
        headers.each do |k, v|
            servlet_response.setHeader(k, v)
        end
        body_s = if body.class == String
            body
        elsif not body.nil?
            body.to_s
        else
            nil
        end

        if not body_s.nil? then
            servlet_response.getOutputStream.write(body_s.to_java_bytes)
        else
            $stderr.puts "null body, not writing"
        end
    end

    def string_remainder(str, prefix_to_remove)
        idx = str.index(prefix_to_remove)
        if idx.nil? then
            return str
        else
            rmidx = idx + prefix_to_remove.length - 1
            return str[rmidx + 1, str.length - rmidx]
        end
    end

    def handle(target, req, servlet_req, servlet_resp)
        method = servlet_req.getMethod().upcase()
        path_info = servlet_req.getPathInfo()
        req_char_encoding = servlet_req.getCharacterEncoding()
        if req_char_encoding.nil? then
            req_char_encoding = 'UTF-8'
        end

        if method == 'POST' then
            req_content_length = servlet_req.getContentLength()
            if req_content_length.nil? then
                $stderr.puts 'No content length set'
            end

            io = servlet_req.getInputStream().to_io()
            request_body = io.read
        else
            request_body = nil
        end

        # decide
        status_code, content_encoding, headers, body = \
        *if method == 'GET' and path_info == '/shim/rules' then
            [ 200,
              'UTF-8',
              {},
              Rules.instance.rules_as_json_string.to_s + "\r\n" ]
        elsif method == 'POST' and path_info.start_with?('/shim/rules/') then
            [ 200,
              'UTF-8',
              {},
              Rules.instance.add_or_update(request_body).to_s + "\r\n" ]
        elsif method == 'DELETE' and path_info.start_with?('/shim/rules/') then
            [ 200,
              'UTF-8',
              {},
              Rules.instance.delete(string_remainder(path_info, '/shim/rules/')) ]
        elsif method == 'POST' and path_info.start_with?('/shim/run/') then
            shimreq = ShimRequest.fromServletRequest(servlet_req, request_body)
            shimresp = Resolver.resolve(shimreq)
            [ shimresp.status, shimresp.content_encoding, shimresp.headers, shimresp.body ]
        elsif method == 'GET' and path_info == '/shim/hello' then
            [ 200,
              'UTF-8',
              {},
              'Hello!' ]
        elsif method == 'GET' and path_info == '/sample_requests/allrefs' then
            [ 200, 'UTF-8', {}, SampleRequests.allrefs ]
        elsif method == 'GET' and path_info.start_with?('/sample_requests/ref/') then
            ref = string_remainder(path_info, '/sample_requests/ref/')
            [ 200, 'UTF-8', {}, SampleRequests.ref(ref) ]
        else
            [ 400, 'UTF-8', {}, "No route matches request.\r\n" ]
        end

        set_servlet_response(status_code, content_encoding, headers, body, servlet_resp)
        req.setHandled(true)
    end
end


RuleLoader.instance.start_monitoring

# For logging
ncsa_log_handler = NCSARequestLog.new('jetty-yyyy_mm_dd.request.log')
ncsa_log_handler.retain_days = 7;
ncsa_log_handler.append = true;
ncsa_log_handler.extended = true;
ncsa_log_handler.log_time_zone = 'GMT'

request_log_handler = RequestLogHandler.new
request_log_handler.request_log = ncsa_log_handler

# For serving things from the filesystem
resource_handler = ResourceHandler.new
resource_handler.setDirectoriesListed(true)
resource_handler.setWelcomeFiles([ 'index.html', 'default.htm', 'index.htm' ].to_java(:string))
resource_handler.setResourceBase('../content')

handlers = HandlerList.new
handlers.setHandlers([ request_log_handler, resource_handler, ShimHandler.new ])

server = Server.new(4567)
server.handler = handlers
server.start
server.join
