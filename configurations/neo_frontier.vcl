vcl 4.1;
import std;
import directors;

backend neo_frontier {
  .host = "v4f.cern.ch";
  .port = "80";
}

sub vcl_init {
  new vdir = directors.round_robin();
  vdir.add_backend(neo_frontier);
}

sub vcl_recv {
  set req.backend_hint = vdir.backend();        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
