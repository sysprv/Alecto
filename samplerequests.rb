# vim:set ts=8 sts=4 sw=4 et ai:

require 'rubygems'
require 'json'

class SampleRequests
    @dir = 'sample_requests'

    def SampleRequests.allrefs
        # strip out fs dir before returning
        JSON.generate({ 'allrefs' => Dir.glob(@dir + '/**.xml').map { |fn| fn.sub(@dir + '/', '') } })
    end

    def SampleRequests.ref(path)
        # add fs dir
        localpath = @dir + '/' + path
        if File.exists?(localpath)
            open(localpath, 'r:UTF-8').read
        else
            ''
        end
    end
end
