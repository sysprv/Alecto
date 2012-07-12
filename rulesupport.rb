# vim:set ts=8 sts=4 sw=4 et ai:

require 'java'
require 'base64'
require 'matchresult'
require 'shimresponse'

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

    def process_shim_request(rule, shimreq)
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

            ret_headers['Content-Type'] = content_type
            ret_code = 200
        elsif rule['file'] then
            begin
                ret_data = open(rule['file'], 'r:' + content_encoding).read()
                ret_headers['Content-Type'] = content_type
                ret_code = 200
            rescue Exception => e
                ret_code = 500
                ret_data = e.to_s + "\r\n\r\n" + e.backtrace.join("\n") + "\r\n"
                ret_headers['X-Alecto-Error'] = e.message
                # TODO: handle error
                STDERR.puts e
            end
        elsif rule['response_base64'] then
            _ret = if rule['response'].class == String then
                rule['response']
            elsif rule['response'].class == Array then
                rule['response'].join('')
            end
            ret_data = Base64.decode64(_ret)
            ret_headers['Content-Type'] = content_type
            ret_code = 200
        # TODO - implement gzip support;
        # base64 decode, wrap in StringIO, send to Zlib::GzipReader
        elsif rule['service'] or rule['tunnel'] then
            uri = rule['service'] || rule['tunnel']
            ret_code, ret_data, http_resp = *passthrough({}, shimreq.body, uri)
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

        ShimResponse.new(ret_code, content_encoding, ret_headers, ret_data)
    end


    def valid_json_rulespec(rule)
        # TODO - improve this
        if rule.nil? then
            return [ false, 'Null rulespec' ]
        end

        if not rule.has_key?('number') then
            return [ false, 'Rule has no number' ]
        end

        if not rule.has_key?('description') then
            return [ false, 'Rule has no description' ]
        end

        if not rule.has_key?('strings') then
            return [ false, 'Rule has no strings' ]
        end

        if rule['strings'].class != Array then
            return [ false, 'strings is not an Array' ]
        end

        if rule['strings'].length == 0 then
            return [ false, 'strings is empty' ]
        end

        if (not rule.has_key?('response')) and
           (not rule.has_key?('response_base64')) and
           (not rule.has_key?('file')) and
           (not rule.has_key?('service')) then
           return [ false, 'Rule has no response/file/service' ]
        end

        return [ true, 'Rule looks ok' ]
    end


    # Make a lambda that from a JSON object
    def rule_from_json(rule, rule_str)
        # Make a lambda that can apply this rule to a shim request.
        # Rule is passed in as a mash object (hashie/mash).
        rn = rule['number']
        rd = rule['description']
        rs = rule_str
        # Should return a ShimResponse.
        rule_lambda = lambda do |shimreq|

            ret = MatchResult.new(false, nil, rn, rd, rs)

            if rule['path_info'] and (rule['service'] or rule['tunnel']) and
                (not shimreq.path_info.end_with?(rule.path_info)) then

                # This rule is for fetching the real response from a backend
                # service, but there was no path info in the http request.
                # This rule can't do anything.

                return ret
            end

            if rule['path_info'] and shimreq.path_info.end_with?(rule['path_info']) then
                shimresp = process_shim_request(rule, shimreq)
                ret = MatchResult.new(true, shimresp, rn, rd, rs)
            elsif rule['strings'] and contains_in_order(shimreq.body, *(rule['strings'])) then
                shimresp = process_shim_request(rule, shimreq)
                ret = MatchResult.new(true, shimresp, rn, rd, rs)
            end

            ret
        end

        rule_lambda
    end
end
