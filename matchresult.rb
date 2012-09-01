# vim:set ts=8 sts=4 sw=4 et ai:

# The result of running a rule against a request.
class MatchResult
    attr_reader :matched, :response, :rule_number, :rule_description, :rule_source

    def initialize(matched, response, rule_number, rule_description, rule_source)
        @matched = matched
        @response = response
        @rule_number = rule_number
        @rule_description = rule_description
        @rule_source = rule_source
    end
end

