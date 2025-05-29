vcl 4.1;
import std;
import directors;

backend neo_frontier_1 {
  .host = "188.184.89.135";
  .port = "80";
}
backend neo_frontier_2 {
  .host = "188.184.89.135";
  .port = "80";
}


sub vcl_init {
  new vdir = directors.round_robin();
  vdir.add_backend(neo_frontier_1);
  vdir.add_backend(neo_frontier_2);
}

sub vcl_recv {
  set req.backend_hint = vdir.backend();        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
