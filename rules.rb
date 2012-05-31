# vim:set ts=8 sts=4 sw=4 et ai:
#

require 'singleton'
require 'rulesupport'
require 'java'
require 'rubygems'
require 'json'
require 'hashie/mash'
require 'pp'

class Rules
    include Singleton
    include RuleSupport

    def initialize
        @rules_lock = java.lang.Object.new # .synchronized only works with Java objects.
        @rules = {} # not an array, but a hash, where the key is the rule number.
        @rules_source = {} # for storing the source code of the rule
    end

    # TODO: batch update - many rules in one request.
    def add_or_update_batch(str)
        if str[0, 1] != '{' then
            raise 'Only JSON is supported so far'
        end

        json_hash = JSON.parse(str)
        rulesspec = Hashie::Mash.new(json_hash)
        if not rulesspec['rules'] then
            raise 'Rules are not valid - no "rules" element found'
        end

        rulesspec.rules.each do |rulespec|
            valid, reason = *valid_json_rulespec(rulespec)
            if not valid then
                STDERR.puts "Invalid rulespec: " + JSON.generate(rulespec)
                raise 'Invalid rule found: ' + reason
            end
        end

        rulesspec.rules.each do |rulespec|
            rule = rule_from_json(rulespec, JSON.generate(rulespec))
            @rules_lock.synchronized do
                @rules[rulespec.number] = rule
                @rules_source[rulespec.number] = JSON.generate(rulespec)
            end
        end

        true
    end

    def add_or_update(str)
        if str[0, 1] != '{' then
            raise 'Only JSON is supported so far'
        end

        json_hash = JSON.parse(str)
        rulespec = Hashie::Mash.new(json_hash)

        # all that went well...
        valid, reason = *valid_json_rulespec(rulespec)
        if not valid then
            raise 'Rule is invalid - ' + reason
        end

        rule = rule_from_json(rulespec, str)

        @rules_lock.synchronized do
            @rules[rulespec.number] = rule
            @rules_source[rulespec.number] = json_hash # storing the structure, not the
                # real source (str).
        end

        true
    end

    def delete(num)
        ret = false
        pp "Deleting rule #{num}"
        if num.class != Fixnum then
            raise "Parameter `num' must be an integer"
        end

        @rules_lock.synchronized do
            if @rules_hash.has_key?(num) then
                @rules.delete(num)
                @rules_source.delete(num)
                ret = true
            end
        end

        ret
    end

    def rules
        @rules  # would it be wise to copy it here?
            # perhaps unnecessary. The obj returned from
            # this method must not be mutated.
    end

    def rules_as_json_string
        obj = { 'rules' => [] }
        @rules_lock.synchronized do
            @rules_source.keys.sort.each do |k|
                obj['rules'] << @rules_source[k]
            end
        end

        JSON.generate(obj)
    end
end

