# vim:set ts=8 sts=4 sw=4 ai et:

require 'java'
require 'rules'
require 'resolver'
require 'request'
require 'samplerequests'
require 'mimeheaders'

# This class takes care of dispatching to various code paths
# depending on the input, which must be an instance of
# the Request class.
#
# This should make this class independent of the http container.
# F.ex. it should be trivial to make this run under
# the http server delivered with the JDK, com.sun.net.httpserver.
#
class Dispatcher
    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(Dispatcher.name)

    # Given a string and a prefix, remove that part of the
    # string that follows the prefix.
    # F.ex. string_remainder('abc', 'ab') -> 'c'
    def Dispatcher.string_remainder(str, prefix_to_remove)
        idx = str.index(prefix_to_remove)
        if idx.nil? then
            return str
        else
            rmidx = idx + prefix_to_remove.length - 1
            return str[rmidx + 1, str.length - rmidx]
        end
    end

    def Dispatcher.dispatch(request)
        method = request.request_method
        path_info = request.path_info
        @@logger.info('Processing request on {}, method == {}', path_info, method)

        # decide
        status_code, headers, body = \
        *if method == 'OPTIONS' then
            # if a client uses the OPTIONS method to check what's
            # allowed, respond by saying that everything is allowed
            # and nothing is forbidden.
            # http://en.wikipedia.org/wiki/Alamut_(1938_novel)
            [ 200, nil, nil ]
        elsif path_info.start_with?('/favicon.ico') then
            [ 204, nil, nil ] # 204 == no content
        elsif path_info.start_with?('/rules/') then
            if method == 'GET' then
                # ex.: GET /rules
                [ 200, MimeHeaders.application_json_utf8,
                    Rules.instance.rules_as_json_string(string_remainder(path_info, '/rules/')).to_s ]
            elsif method == 'POST' then
                # ex.: POST /rules
                [ 200, MimeHeaders.text_plain_utf8,
                    Rules.instance.add_or_update(request_body) ]
            elsif method == 'DELETE' then
                # ex.: DELETE /rules/10
                # or
                # DELETE /rules/all
                [ 200, MimeHeaders.text_plain_utf8,
                    Rules.instance.delete(string_remainder(path_info, '/rules/')) ]
            else
                [ 417, MimeHeaders.text_plain_utf8,
                    'Unsupported method; supported methods are GET, POST and DELETE' ]
            end
        elsif path_info.start_with?('/sample_requests') then
            if method != 'GET' then
                # Method Not Allowed
                [ 405, MimeHeaders.text_plain_utf8, 'Only GET is allowed on /sample_requests']
            elsif path_info == '/sample_requests/allrefs' then
                [ 200, MimeHeaders.application_json_utf8, SampleRequests.allrefs ]
            elsif path_info.start_with?('/sample_requests/ref/') then
                ref = string_remainder(path_info, '/sample_requests/ref/')
                data = SampleRequests.ref(ref)
                if not data.nil? then
                    [ 200, MimeHeaders.text_plain_utf8, data ]
                else
                    [ 404, MimeHeaders.text_plain_utf8, "Not found" ]
                end
            else
                # Not Acceptable
                [ 406, MimeHeaders.text_plain_utf8, 'Bad path.' +
                    ' Try GET on /sample_requests/allrefs or /sample_requests/ref/[id]' ]
            end
        elsif method == 'POST' or method == 'GET' then
            resp = Resolver.resolve(request)
            [ resp.status, resp.headers, resp.body ]
        else
            [ 417, MimeHeaders.text_plain_utf8, 'No route matched the request to ' + target ]
        end

        # return...
        Response.new(status_code, headers, body)
    end
end

