require 'matchresult'
require 'rulesupport'

# Represents a rule.
# Used to be implemented as a single Ruby lambda (closure/anonymous function),
# but it turned out to be natural to attach some data, like "rulespec" -
# the JSON representation of a rule - to this. Thus, it is a proper object now.
#
# Rules written in JSON have fixed behaviour, as to how various elements
# are matched, combined etc. When more complex/arbitrary behaviour is needed,
# it becomes natural to extend this class and write rules in Ruby.
#
class Rule
    # pull in various functions defined in the RuleSupport module
    include RuleSupport

    attr_reader :number, :description, :rulespec

    # class variable;
    @@no_match = MatchResult.new(false, nil, -1, nil, nil)

    def initialize(rulespec)
        @rulespec = rulespec
        @number = rulespec['number']
        @description = rulespec['description']
    end

    def process(
        req # Request
    ) # returns MatchResult
        if (not @rulespec.has_key?('service') and   # not a proxy rule...
            @rulespec.has_key?('path_info') and     # has path_info
            not req.path_info.end_with?(@rulespec['path_info'])) then   # that path_info doesn't match
            return @@no_match                                           # what we've got.
        end

        if (@rulespec['path_info'] and req.path_info.end_with?(@rulespec['path_info'])) or
           (@rulespec['query_strings'] and contains_in_order(req.query_string, *@rulespec['query_strings'])) or
           contains_in_order(req.body, *@rulespec['strings']) then
               response = process_request(@rulespec, req)
            # return
            MatchResult.new(true, response, @number, @description, nil)
        else
            @@no_match
        end
    end
end
