# vim:set ts=8 sts=4 sw=4 et ai:

require 'java'
require 'thread'
require 'rules'

# This class works as a bridge, for loading rules specified
# in a "rules.json" file into the app.
#
# Keeps polling rules.json for changes, and when the file is
# detected as modified, loads the rules in the file, using
# the Rules object (rules.rb).
class RuleLoader
    include Singleton

    @@logger = Java::OrgSlf4j::LoggerFactory::getLogger(RuleLoader.name)

    @file_mtime = nil
    @stop_flag = false

    def start_monitoring
        @stop_flag = false
        @@logger.info("Starting rule change monitor thread")
        @fn = if (ENV['ALECTORULES'] and File.exists?(ENV['ALECTORULES'])) then
            ENV['ALECTORULES']
        elsif File.exists?('rules.json') then
            'rules.json'
        end

        Thread.new do
            java.lang.Thread.currentThread().setName(RuleLoader.name)
            monitor
        end
    end

    def stop_monitoring
        @stop_flag = true
    end

    def monitor
        loop do
            if @stop_flag then
                @@logger.info("got stop_flag")
                break
            end

            sleep 1

            if not @fn or not File.exists?(@fn) then
                @@logger.info("bad filename or file does not exist")
                next
            end

            file_mtime = File.stat(@fn).mtime

            if @file_mtime.nil? or file_mtime > @file_mtime then
                @@logger.info("Detected rule change - reloading")
                @file_mtime = file_mtime
                str = open(@fn, 'r:UTF-8').read
                begin
                    Rules.instance.add_or_update_batch(str)
                rescue Exception => e
                    stacktrace = e.message + "\n\n" + e.backtrace.join("\n") + "\n"
                    @@logger.error("Ruby exception while loading rules: {}", stacktrace)
                rescue java.lang.Exception => e
                    @@logger.error("Java exception while loading rules", e)
                end
            end
        end
    end
end
