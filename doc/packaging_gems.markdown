http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar explains
how to bundle rubygems in jar files so that they will be accessible
to JRuby.

Example: Packaging the htmlentities gem

	mkdir _gems
	java -jar ../jruby-complete-1.6.7.2.jar -S gem install -i _gems htmlentities --no-rdoc --no-ri
	jar cvf alecto-gems.jar -C _gems .
	rm -rf _gems/
	mv alecto-gems.jar lib/

