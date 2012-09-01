# vim:set ts=8 sts=4 sw=4 et ai:

require 'json'

# A small hack, to build up a small REST interface over a set of
# files on disk.
#
# dispatcher.rb takes care of "mounting" this over a http path
# like /sample_requests.
#
class SampleRequests
    # Where to look for files
    @@dir = 'sample_requests'

    # List all the .xml files in dir, turn it into a data structure, convert it into JSON
    # and return it.
    #
    # Example structure:
    #
    # {
    #   "allrefs": [
    #       "Test.xml",
    #       "Test2.xml",
    #       "Test3.xml",
    #       "Jabberwocky.xml",
    #       "Oz.xml"
    #   ]
    # }
    #
    def SampleRequests.allrefs
        JSON.pretty_generate({ 'allrefs' => Dir.glob(@@dir + '/**.xml').map { |fn| fn.sub(@@dir + '/', '') } })
    end


    # Given a "reference" (just a plain filename for now), return its contents
    # if it exists under the directory we're configured to use.
    def SampleRequests.ref(path)
        localpath = @@dir + '/' + path
        if File.exists?(localpath)
            open(localpath, 'r:UTF-8').read
        else
            nil
        end
    end
end
