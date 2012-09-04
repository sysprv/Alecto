# vim:set ts=8 sts=4 sw=4 ai et:

require 'java'
require 'dispatcher'

# This class is a Jetty Handler.
# Depending on how handlers are set up in the Jetty configuration,
# jetty invokes handler methods to process requests.
# For more information, see http://wiki.eclipse.org/Jetty/Tutorial/Embedding_Jetty#Writing_Handlers
#
class JettyHandler < org.eclipse.jetty.server.handler.AbstractHandler
    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(JettyHandler.name)

    # Transform our internal response object to a ServletResponse for Jetty to handle
    def set_servlet_response(response, servlet_response)
        servlet_response.setStatus(response.status)
        if not response.headers.nil? then
            response.headers.keys.sort.each do |k|
                servlet_response.setHeader(k, response.headers[k])
            end
        end

        body_s = if response.body.class == String
            response.body
        elsif not response.body.nil?
            response.body.to_s
        else
            nil
        end

        if not body_s.nil? then
            servlet_response.getOutputStream.write(body_s.to_java_bytes)
        end
    end

    #
    # This method is inherited from AbstractHandler, and takes care of
    # transforming between ServletRequest/ServletResponse from Jetty
    # and Request and Response objects.
    #
    def handle(target, base_req, servlet_req, servlet_resp)
        request = Request.new(servlet_req)
        response = Dispatcher.dispatch(request)
        set_servlet_response(response, servlet_resp)
        base_req.setHandled(true)
    end
end

