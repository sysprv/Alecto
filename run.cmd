@echo off
set CLASSPATH=".;lib\*"

echo Starting...
java -cp %CLASSPATH% -Xms256m -Xmx256m -noverify -client -Dorg.eclipse.jetty.http.LEVEL=DEBUG org.jruby.Main _main.rb
