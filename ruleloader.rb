# vim:set ts=8 sts=4 sw=4 et ai:
#

require 'thread'
require 'rules'

class RuleLoader
    include Singleton

    @file_mtime = nil
    @stop_flag = false

    def start_monitoring
        @stop_flag = false

        Thread.new do
            monitor
        end
    end

    def stop_monitoring
        @stop_flag = true
    end

    def monitor
        loop do
            if @stop_flag then
                break
            end

            fn = if (ENV['ALECTORULES'] and File.exists?(ENV['ALECTORULES'])) then
                ENV['ALECTORULES']
            elsif File.exists?('rules.json') then
                'rules.json'
            end

            if fn then
                file_mtime = File.stat(fn).mtime

                if @file_mtime.nil? or file_mtime > @file_mtime then
                    @file_mtime = file_mtime
                    str = open(fn, 'r:UTF-8').read
                    begin
                        puts 'Loading rules'
                        Rules.instance.add_or_update_batch(str)
                        puts 'Loaded rules'
                    rescue Exception => e
                        $stderr.puts e
                    end
                end
            end

            sleep(30)
        end
    end
end
