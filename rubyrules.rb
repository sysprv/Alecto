# vim:set ts=8 sts=4 sw=4 et ai:
#

require 'nokogiri'

class RubyRules
    include Singleton

    def initialize
        @rules = []

    end
end

__END__

GetGameInformation

phase 1?
GN<gameno+_>+_FGI_<fromgameinstance>+_TGI_<togameinstance>_FDt_fromDate(0,10)_UDt_untilDate(0,10)_RF_


