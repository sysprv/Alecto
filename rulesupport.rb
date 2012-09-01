# vim:set ts=8 sts=4 sw=4 et ai:

require 'java'
require 'net/http'
require 'uri'
require 'base64'
require 'matchresult'
require 'response'

# Not a class, but a module - a collection of functions
# useful when executing rules.
# This module is meant to be "included" by other modules
# or classes, thereby "mixing-in" this functionality.
#
# See rule.rb and rules.rb for cases where this happens.
#
module RuleSupport
    # Checks the string `where' for each of the strings
    # in the array `what', in order.
    def contains_in_order(where, *what)
        ret = nil
        return ret if where.nil?
        return ret if what.length < 1

        last_idx = 0
        what.each do |needle|
            idx = where.index(needle, last_idx)
            if idx.nil? then # needle not found
                ret = false
                break
            else
                ret = true
            end
            last_idx += 1
        end

        ret
    end

    # Do a http POST on the given URI
    # TODO: Replace Ruby's net/http with
    # Apache HttpComponents
    def POST(uri, headers, body)
        parsed_uri = URI.parse(uri)
        http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
        resp = http.post(parsed_uri.path, body, headers)

        # TODO: handle redirects
        if resp.code == '200' then
            [ resp.code.to_i, resp.body, resp ]
        else
            [ resp.code.to_i, nil, resp ]
        end
    end

    def GET(uri, headers)
        parsed_uri = URI.parse(uri)
        http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
        resp = http.get(parsed_uri.path)
        [ resp.code.to_i, resp.body, resp ]
    end

    # TODO: support other http methods for tunnel mode

    def process_request(rule, req)
        logger = Java::OrgSlf4j::LoggerFactory::getLogger('process_request')
        ret_data = nil
        ret_headers = {}
        ret_code = 500

        content_encoding = if rule.has_key?('content_encoding') then
            rule['content_encoding']
        else
            'UTF-8'
        end

        content_type = if defined?(rule['content_type']) then
            rule['content_type']
        else
            'application/xml; charset=' + content_encoding
        end

        if rule['response'] then
            if rule['response'].class == String then
                ret_data = rule['response']
            elsif rule['response'].class == Array then
                ret_data = rule['response'].join('')
            end

            ret_code = 200
        elsif rule['file'] then
            begin
                # TODO: binary?
                ret_data = open(rule['file'], 'r:binary').read()
                ret_code = 200
            rescue Exception => e
                ret_code = 404
                stacktrace = e.message + "\n\n" + e.backtrace.join("\n")
                logger.warn("Error while reading fata from file {}, exception: {}", rule['file'], stacktrace)
                msg = 'Error while reading from file ' + rule['file'] + "\n\n" + stacktrace
                ret_data = msg
                ret_headers['Content-Type'] = 'text/plain; charset=us-ascii'
                ret_headers['X-Alecto-Error'] = e.message
            end
        elsif rule['response_base64'] then
            _ret = if rule['response'].class == String then
                rule['response']
            elsif rule['response'].class == Array then
                rule['response'].join('')
            end
            ret_data = Base64.decode64(_ret)
            ret_code = 200
            # TODO - implement gzip support;
            # base64 decode, wrap in StringIO, send to Zlib::GzipReader
        elsif rule['service'] then
            uri = rule['service']
            if not req.query_string.nil? then
                uri = uri + req.query_string
            end
            ret_code, ret_data, http_resp = *if req.request_method == 'POST' then
                logger.info('Making POST request to {}', uri)
                POST(uri, {}, req.body)
            elsif req.request_method == 'GET' then
                logger.info('Making GET request to {}', uri)
                GET(uri, {})
            else
                logger.info('Unsupported request method {}', req.request_method)
                [ 405, nil, nil ]
            end

            # now tmp is like:
            # {"server"=>["Sun GlassFish Enterprise Server v2.1 Patch02"],
            #  "content-type"=>["application/xml;charset=UTF-8"],
            #  "content-length"=>["898"],
            #  "date"=>["Thu, 09 Feb 2012 14:30:43 GMT"],
            # "connection"=>["close"]}
            #
            # add the headers from the backend
            # TODO: handle duplicated headers from backend?
            http_resp.to_hash.map do |k, v|
                ret_headers['X-Alecto-Backend-' + k] = v[0]
            end
        end

        if not ret_headers.has_key?('Content-Type') then
            ret_headers['Content-Type'] = content_type
        end
        Response.new(ret_code, ret_headers, ret_data)
    end


    def valid_json_rulespec(rule)
        if rule.nil? then
            return [ false, 'Null rulespec' ]
        end

        if not rule.has_key?('number') then
            return [ false, 'Rule has no number' ]
        end

        if rule['number'].class != Fixnum then
            return [ false, 'Rule number must be an integer' ]
        end

        if not rule.has_key?('description') then
            return [ false, 'Rule has no description' ]
        end

        if not rule.has_key?('strings') and not rule.has_key?('query_strings') then
            return [ false, 'Rule has no strings' ]
        end

        if rule.has_key?('strings') then
            if rule['strings'].class != Array then
                return [ false, 'strings is not an Array' ]
            end
            if rule['strings'].length == 0 then
                return [ false, 'strings is empty' ]
            end
        end

        if rule.has_key?('query_strings') then
            if rule['query_strings'].class != Array then
                return [ false, 'query_strings is not an Array' ]
            end
            if rule['query_strings'].length == 0 then
                return [ false, 'query_strings is empty' ]
            end
        end

        if (not rule.has_key?('response')) and
           (not rule.has_key?('response_base64')) and
           (not rule.has_key?('file')) and
           (not rule.has_key?('service')) then
            return [ false, 'Rule has no response/file/service' ]
        end

        if rule.has_key?('service') and not rule.has_key?('path_info') then
            return [ false, 'In proxy mode, path_info is required' ]
        end

        if rule.has_key?('service') then
            if rule['strings'].length != 1 or rule['strings'][0] != 'default' then
                return [ false, 'In proxy mode, "strings" must be [ "default" ]' ]
            end
        end

        return [ true, 'Rule looks ok' ]
    end
end
