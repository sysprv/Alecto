# vim:set ts=8 sts=4 sw=4 et ai:
#

require 'java'
require 'singleton'
require 'rulesupport'
require 'rule'
require 'pp'
require 'json'
require 'mimeheaders'

# An object to handle the current set of rules we are working with.
# Supports adding/removing rules.
# The dispatcher ties the various methods in this class to http paths
# starting at /rules/.
#
# Note that this class is a singleton. Use `Rules.instance' to get
# a reference to the singleton.
#
class Rules
    include Singleton
    include RuleSupport

    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(Rules.name)

    attr_reader :rules, :rule_numbers

    def initialize
        @rules_lock = java.lang.Object.new # .synchronized only works with Java objects.
        @rules = {} # not an array, but a hash, where the key is the rule number.
        @rule_numbers = [] # keep the rule numbers in an array, sorted.
        @@logger.info("Rules singleton initialized")
    end

    # TODO: batch update - many rules in one request.
    def add_or_update_batch(str)
        if str[0, 1] != '{' then
            raise 'Only JSON is supported so far'
        end

        json_hash = JSON.parse(str)
        rulesspec = json_hash
        if not rulesspec['rules'] then
            raise 'Rules are not valid - no "rules" element found'
        end

        rulesspec['rules'].each do |rulespec|
            valid, reason = *valid_json_rulespec(rulespec)
            if not valid then
                @@logger.error("Invalid rulespec: {}", JSON.pretty_generate(rulespec))
                raise 'Invalid rule found: ' + reason
            end
        end

        rulesspec['rules'].each do |rulespec|
            rule = Rule.new(rulespec)
            @rules_lock.synchronized do
                @rules[rulespec['number']] = rule
                @rule_numbers = @rules.keys.sort
            end
        end

        true
    end

    def add_or_update(str)
        if str.nil? or str[0, 1] != '{' then
            return [ 417, MimeHeaders.text_plain_utf8, "Invalid input." +
                " A rule number (/rules/<integer>) and valid JSON body are required.\n" ]
        end

        json_hash = JSON.parse(str)
        rulespec = json_hash

        # all that went well...
        valid, reason = *valid_json_rulespec(rulespec)
        if not valid then
            return [ 417, MimeHeaders.text_plain_utf8, "Rule is invalid: " + reason + "\n" ]
        end

        rule = Rule.new(rulespec, str)

        @rules_lock.synchronized do
            @rules[rulespec['number']] = rule
            @rule_numbers = @rules.keys.sort
        end

        [ 200, MimeHeaders.text_plain_utf8, "Rule added/updated.\n" ]
    end

    def delete(param)
        @@logger.info('Deleting rules with spec: {}', param)
        if param.nil? then
            return [ 417, MimeHeaders.text_plain_utf8,
                "Invalid data - call with /rules/<integer>\n" ]
        end

        ret = nil
        if param =~ /^-?[0-9]+$/ then
            num = param.to_i
            @rules_lock.synchronized do
                if @rules.has_key?(num) then
                    @rules.delete(num)
                    @rule_numbers = @rules.keys.sort
                    ret = [ 200, MimeHeaders.text_plain_utf8, "Rule deleted\n" ]
                end
            end
        elsif param.downcase ==  'all' then
            @rules_lock.synchronized do
                @rules.clear
                @rule_numbers = []
            end
            ret = [ 200, MimeHeaders.text_plain_utf8, " All rules deleted\n" ]
        end

        ret
    end

    def rules_as_json_string(param)
        # TODO: return 404 if rule not found
        rulespecs = []

        if not param.nil? and param =~ /^-?[1-9][0-9]*$/ then
            num = param.to_i
            if @rules.has_key?(num) then
                rulespecs << @rules[num].rulespec
            end
        elsif param.nil? or param == '' or param.downcase == 'all' then
            @rules_lock.synchronized do
                @rule_numbers.each do |rln|
                    rulespecs << @rules[rln].rulespec
                end
            end
        end

        ret = { 'rules' => rulespecs }
        
        [ 200, MimeHeaders.application_json_utf8, JSON.pretty_generate(ret) ]
    end
end

