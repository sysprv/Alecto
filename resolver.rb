# vim:set ts=8 sts=4 sw=4 et ai:
require 'rules'

class Resolver
    def Resolver.resolve(shimrequest)
        req = shimrequest
        resp = ShimResponse.new(500, 'UTF-8', { 'Content-Type' => 'text/xml;charset=UTF-8' }, "<xml>No matchers for request</xml>\r\n")
        
        # go through each function, and return the response from the first one that matches.
	rules = Rules.instance.rules

        rules.keys.sort.each do |rulenum|
            # for each rule in rules, in order, call the lambda
            matchresult = rules[rulenum].call(req)
            if not matchresult.nil? and matchresult.matched then
                resp = matchresult.shim_response
                break
            end
        end

        resp
    end
end

