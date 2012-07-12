# vim:set ts=8 sts=4 sw=4 et ai:

require 'java'
require 'rules'


class Resolver
    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(Resolver.name)

    @@default_error_response = ShimResponse.new(417, 'UTF-8', {
            'Content-Type' => 'application/xml;charset=UTF-8'
        }, "<xml>No matchers for request</xml>\r\n")

    def Resolver.resolve(shimrequest)
        req = shimrequest
        # go through each function, and return the response from the first one that matches.
	rules = Rules.instance.rules
        resp = nil

        rules.keys.sort.each do |rulenum|
            # for each rule in rules, in order, call the lambda
            @@logger.info("Checking request against rule number {}", rulenum)
            matchresult = rules[rulenum].call(req)
            if not matchresult.nil? and matchresult.matched then
                @@logger.info("Rule number {} matched", rulenum)
                resp = matchresult.shim_response
                break
            end
        end

        if resp.nil? then
            @@logger.info("No match found")
            resp = @@default_error_response
        end

        resp
    end
end

