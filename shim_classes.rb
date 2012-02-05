#! jruby
# vim:set ts=8 sts=4 sw=4 ai et:

module ShimUtil
    # A utility method to check of a set of strings are present in
    # another string (where), in the order they are given to the
    # method.
    def contains_in_order(where, *what)
        return nil if where.nil?
        return nil if what.length < 1

        lastidx = 0
        what.each do |str|
            idx = where.index(str, lastidx)
            if idx.nil? then
                return false
            end
            lastidx = idx
        end

        return true
    end
end

class ShimRequest
    attr_reader :request_method, :query_string, :path_info, :body

    def initialize(sinatra_request)
        @request_method = sinatra_request.request_method
        @query_string = sinatra_request.query_string
        @path_info = sinatra_request.path_info
        @body = if @request_method == 'POST' and sinatra_request.content_length > '0' then
            sinatra_request.body.read
        else
            nil
        end
    end
end

class ShimResponse
    # status -> int
    # headers -> map
    # body -> string
    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
    end
end

class MatchResult
    attr_reader :matched, :shim_response

    def initialize(matched, shim_response)
        @matched = matched
        @shim_response = shim_response
    end
end

class Resolver
    # pull in utility functions
    include ShimUtil

    def initialize
        # list of matchers.
        # TODO - matchers should implement java.util.concurrent.Callable,
        # so they can be put onto a threadpool.
        # They should also have a rule number/description.
        @matchers = []

        # a matcher that won't match anything
        @matchers << lambda do |shimreq|
            MatchResult.new(false, ShimResponse.new(200, { 'X-Foo' => 'Bar' }, 'Quux'))
        end

        @matchers << lambda do |shimreq|
            body = shimreq.body
            p body
            if contains_in_order(body, "GetGameInformationRequest") then
                return MatchResult.new(true, ShimResponse.new(200, nil, "GetGameInformationResponse"))
            end
        end
    end

    def resolve(request)
        req = ShimRequest.new(request)
        resp = ShimResponse.new(500, nil, 'No matchers for request')
        
        # go through each function, and return the response from the first one that matches.
        @matchers.each do |matcher|
            matchresult = matcher.call(req)
            if not matchresult.nil? and matchresult.matched then
                resp = matchresult.shim_response
                break
            end
        end

        return resp
    end
end

