# Alecto

A JRuby app to mock simple http services.

# Quick Start
You need to have Java installed. JRuby is included in this
repository for simplicity (lib/jruby-complete-1.7.0.preview2.jar).

Simply clone the repository, and run `run` on GNU/Linux or `run.cmd`
on Microsoft Windows.

Log messages will appear on the standard output and standard error
streams.


## Rules

Are loaded from the file "rules.json" in the current directory.

A background thread polls the modification time of rules.json
once a second, and loads the complete file when any changes
are detected.

 vim:set ts=8 sts=2 sw=2 noet ai ff=unix:
