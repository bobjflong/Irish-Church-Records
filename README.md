Tiny Sinatra bridge for accessing results in the Irish Church Records site at http://churchrecords.irishgenealogy.ie/churchrecords/

This implementation requires memcached, so if you get Dalli errors it's because you haven't got memcached running.

To run:

bundle install
ruby site.rb

Then in your browser try something like:

http://localhost:4567/search?lname=murphy&offset=2
