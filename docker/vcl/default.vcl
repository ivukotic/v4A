vcl 4.1;
import std;
import directors;

backend back01 {
  .host = "atlasfrontier1-ai.cern.ch";
  .port = "8000";
}
backend back02 {
  .host = "atlasfrontier2-ai.cern.ch";
  .port = "8000";
}

sub vcl_init {
  new vdir = directors.round_robin();
  vdir.add_backend(back01);
  vdir.add_backend(back02);
}

sub vcl_recv {
  set req.backend_hint = vdir.backend();        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
