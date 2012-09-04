module HelpMap
    @@m = {
        '/' => 'help/index.html',
        '/rules' => 'help/rules.html'
    }

    def HelpMap.mappings
        @@m
    end
end
