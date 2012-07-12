# vim:set ts=8 sts=4 sw=4 ai et:

require 'net/http'
require 'uri'
require 'pp'

module ShimUtil
    # A utility method to check of a set of strings are present in
    # another string (where), in the order they are given to the
    # method.
    def contains_in_order(where, *what)
        ret = nil
        return ret if where.nil?
        return ret if what.length < 1

        lastidx = 0
        what.each do |str|
            needle = if str.start_with?("file:") then
                open(str[5, str.length - 1]).read.strip
            else
                str
            end

            idx = where.index(needle, lastidx)
            if idx.nil? then
                ret = false
                break
            else
                ret = true
            end
            lastidx = idx + 1
        end

        return ret
    end

    # TODO: use Apache HttpClient
    def POST(uri, headers, data)
        parsed_uri = URI.parse(uri)
        http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
        resp = http.post(parsed_uri.path, data, headers)

        if resp.code == '200' then
            [ resp.code.to_i, resp.body, resp ]
        else
            [ resp.code.to_i, nil, resp ]
        end
    end

    def passthrough(headers, body, target_url)
        if not headers.key?('User-Agent') then
            headers['User-Agent'] = 'Alecto'
        end

        POST(target_url, headers, body)
    end


    def valid_json_rulespec(rule)
        if rule.nil? then
            $stderr.puts "ERROR: null rule"
            return false
        end

        if rule['number'].nil? or rule['description'].nil? then
            $stderr.puts "ERROR: rule must have a number and a description"
            return false
        end

        if rule['strings'].length < 1 then
            $stderr.puts "ERROR: Rule #{rule.number}/#{rule.description} does not define any words to check for"
            return false
        end

        if rule.key?('response') then
            return false if rule['response'].class != String
            return false if rule['response'].length < 1
        elsif rule.key?('file') then
            if not File.exists?(rule['file']) then
                $stderr.puts "WARNING: Response file #{rule['response']} used by rule #{rule['number']}/#{rule['description']} not on disk (yet)"
                # return true
            end
        elsif rule.key?('service') then
            true
        else
            return false # no action specified
        end

        return true
    end

    def process_shim_request(rule, shimreq)
        ret_data = nil
        ret_headers = {}
        ret_code = 500
        if rule['response'] then
            ret_data = rule['response']
            ret_headers['Content-Type'] = rule['content_type'];
            ret_code = 200
        elsif rule['file'] then
            ret_data = open(rule.file, 'r:UTF-8').read()
            ret_headers['Content-Type'] = rule['content_type'];
            ret_code = 200
        elsif rule['service'] then
            ret_code, ret_data, http_resp = *passthrough({}, shimreq.body, rule['service'])
            tmp = http_resp.to_hash
            # now tmp is like:
            # {"server"=>["Sun GlassFish Enterprise Server v2.1 Patch02"],
            #  "content-type"=>["application/xml;charset=UTF-8"],
            #  "content-length"=>["898"],
            #  "date"=>["Thu, 09 Feb 2012 14:30:43 GMT"],
            # "connection"=>["close"]}
            http_resp.to_hash.map do |k, v|
                ret_headers['X-Backend-' + k] = v[0]
            end

            # ret_headers.delete('server')
            # ret_headers.delete('content-length')
            # ret_headers.delete('date')
        end

        succeeded = if ret_code == 200 then true else false end
        MatchResult.new(succeeded, ShimResponse.new(ret_code, ret_headers, ret_data))
    end

    # Load simple rules from a text file, and generate lambdas
    def make_matchers
        matchers = []

        return matchers if not ENV['ALECTORULES']
        json_str = open(ENV['ALECTORULES'], 'r:UTF-8') do |r|
            r.read
        end

        return [] if not json_str or json_str.length < 2

        obj = JSON.parse(json_str)
        obj['rules'].each do |rule|
            # some simple checks
            next if not valid_json_rulespec(rule)

            matcher = lambda do |shimreq|
                # TODO: rule.number, rule.description should be embedded.

                # if path_info is specified in the rule, it must match what the client sent.
                if rule.key?('path_info') and not shimreq.path_info.end_with?(rule.path_info) then
                    return nil
                end

                if contains_in_order(shimreq.body, *rule.strings) or
                    ( rule['strings'].length > 0 and rule['strings'][0].downcase == 'default' ) then
                    process_shim_request(rule, shimreq)
                end
            end

            matchers << matcher
        end
        # return
        matchers
    end
end


