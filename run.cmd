@echo off
set CLASSPATH="src;jarlib\*"

echo Starting...
java -cp %CLASSPATH% -Xms256m -Xmx256m -noverify -client -Dorg.eclipse.jetty.http.LEVEL=DEBUG org.jruby.Main src\_main.rb
