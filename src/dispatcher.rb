# vim:set ts=8 sts=4 sw=4 ai et:

require 'java'
require 'rules'
require 'resolver'
require 'request'
require 'samplerequests'
require 'mimeheaders'
require 'helpmap'

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
        if prefix_to_remove.length > str.length then
            return nil
        end
        idx = str.index(prefix_to_remove)
        if idx.nil? then
            return nil
        else
            rmidx = idx + prefix_to_remove.length - 1
            return str[rmidx + 1, str.length - rmidx]
        end
    end

    def Dispatcher.dispatch(request)
        method = request.request_method
        path_info = request.path_info
        @@logger.info('Processing request {}', request.summary)

        # decide
        status_code, headers, body = \
        *if method == 'OPTIONS' then
            # if a client uses the OPTIONS method to check what's
            # allowed, respond by saying that everything is allowed
            # and nothing is forbidden.
            # http://en.wikipedia.org/wiki/Alamut_(1938_novel)
            [ 200, nil, nil ]
        elsif HelpMap.mappings.has_key?(path_info) and method == 'GET' then
            # If this path_info should serve a help message from disk,
            # do that...
            begin
                data = nil
                open(HelpMap.mappings[path_info], 'r:UTF-8') do |help_f|
                    data = help_f.read
                end
                if data.nil? or data.length == 0 then
                    data = '(No data found)'
                end
                [ 200, MimeHeaders.text_html_utf8, data ]
            rescue Exception => e
                [ 500, MimeHeaders.text_plain_utf8, "Oops.. Something went wrong.\n" +
                    e.message + "\n" + e.backtrace.join("\n") + "\n" ]
            end
        elsif path_info.start_with?('/favicon.ico') then
            [ 204, nil, nil ] # 204 == no content
        elsif path_info.start_with?('/rules') then
            if method == 'GET' then
                # ex.: GET /rules
                Rules.instance.rules_as_json_string(string_remainder(path_info, '/rules/'))
            elsif method == 'POST' then
                # ex.: POST /rules
                Rules.instance.add_or_update(request.body)
            elsif method == 'DELETE' then
                # ex.: DELETE /rules/10
                # or
                # DELETE /rules/all
                Rules.instance.delete(string_remainder(path_info, '/rules/'))
            else
                [ 417, MimeHeaders.text_plain_utf8,
                    "Unsupported method; supported methods are GET, POST and DELETE\n" ]
            end
        elsif path_info.start_with?('/sample_requests') then
            if method != 'GET' then
                # Method Not Allowed
                [ 405, MimeHeaders.text_plain_utf8, "Only GET is allowed on /sample_requests\n" ]
            elsif path_info == '/sample_requests/allrefs' then
                [ 200, MimeHeaders.application_json_utf8, SampleRequests.allrefs ]
            elsif path_info.start_with?('/sample_requests/ref/') then
                ref = string_remainder(path_info, '/sample_requests/ref/')
                data = SampleRequests.ref(ref)
                if not data.nil? then
                    [ 200, MimeHeaders.text_plain_utf8, data ]
                else
                    [ 404, MimeHeaders.text_plain_utf8, "Not found\n" ]
                end
            else
                # Not Acceptable
                [ 406, MimeHeaders.text_plain_utf8, "Bad path." +
                    " Try GET on /sample_requests/allrefs or /sample_requests/ref/[id]\n" ]
            end
        elsif method == 'POST' or method == 'GET' then
            resp = Resolver.resolve(request)
            [ resp.status, resp.headers, resp.body ]
        else
            [ 417, MimeHeaders.text_plain_utf8,
                "No route matched the #{request.request_method}, to #{request.path_info}\n" ]
        end

        # set some default cache headers
        if method == 'GET' and status_code == 200 and not headers.has_key?('Cache-Control') then
            headers['Cache-Control'] = 'max-age=30'
        end

        # return...
        Response.new(status_code, headers, body)
    end
end

