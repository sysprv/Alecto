class MatchResult
    attr_reader :matched, :shim_response, :rule_number, :rule_description, :rule_source

    def initialize(matched, shim_response, rule_number, rule_description, rule_source)
        @matched = matched
        @shim_response = shim_response
        @rule_number = rule_number
        @rule_description = rule_description
        @rule_source = rule_source
    end
end

