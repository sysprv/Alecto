# vim:set ts=8 sts=4 sw=4 ai et:

require 'java'
java_import 'org.eclipse.jetty.server.Server'
java_import 'org.eclipse.jetty.server.handler.AbstractHandler'
java_import 'org.eclipse.jetty.server.handler.ResourceHandler'
java_import 'org.eclipse.jetty.server.handler.HandlerList'
java_import 'org.eclipse.jetty.server.handler.RequestLogHandler'
java_import 'org.eclipse.jetty.server.NCSARequestLog'

require 'ruleloader'
require 'jettyhandler'

# Main entrypoint. Sets up some Jetty handlers, and starts
# up Jetty. Then, waits for the Jetty thread to end.
def main
    logger = Java::OrgSlf4j::LoggerFactory::getLogger('main')

    RuleLoader.instance.start_monitoring

    # For logging
    logger.info('Creating Jetty access logger')
    ncsa_log_handler = NCSARequestLog.new('log/jetty-yyyy_mm_dd.request.log')
    ncsa_log_handler.retain_days = 7;
    ncsa_log_handler.append = true;
    ncsa_log_handler.extended = true;
    ncsa_log_handler.log_time_zone = 'GMT'

    request_log_handler = RequestLogHandler.new
    request_log_handler.request_log = ncsa_log_handler

    # A resource handler to serve static files.
    # Could be useful...
    # Without a context, the mapping will be as:
    # path -> <resourceBase>/path
    # For example, if the resourceBase is content,
    # A request for /test.txt will cause a lookup for
    # content/test.txt.
    # resource_handler = ResourceHandler.new
    # resource_handler.setDirectoriesListed(true)
    # resource_handler.setWelcomeFiles([ 'index.html', 'index.htm' ].to_java(:string))
    # resource_handler.setResourceBase('content')

    handlers = HandlerList.new
    handlers.setHandlers([ request_log_handler, JettyHandler.new ])

    port = 4567
    env_port = ENV['ALECTO_PORT']
    if not env_port.nil? and env_port =~ /^[1-9][0-9]*$/ then
        n_env_port = env_port.to_i
        if n_env_port > 0 and n_env_port < 65536 then
            port = n_env_port
        end
    end

    logger.info('Creating Jetty server instance')
    server = Server.new(port)
    server.handler = handlers
    logger.info('Starting server')
    server.start
    logger.info('Waiting for Jetty to exit')
    server.join
end

# well, let's get to it
main
