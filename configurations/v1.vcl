vcl 4.1;
import std;
import directors;

backend frontier_1 {
  .host = "atlasfrontier1-ai.cern.ch";
  .port = "8000";
}
backend frontier_2 {
  .host = "atlasfrontier2-ai.cern.ch";
  .port = "8000";
}
backend frontier_3 {
  .host = "atlasfrontier3-ai.cern.ch";
  .port = "8000";
}
backend frontier_4 {
  .host = "atlasfrontier4-ai.cern.ch";
  .port = "8000";
}

sub vcl_init {
  new vdir = directors.round_robin();
  vdir.add_backend(frontier_1);
  vdir.add_backend(frontier_2);
  vdir.add_backend(frontier_3);
  vdir.add_backend(frontier_4);
}

sub vcl_recv {
  set req.backend_hint = vdir.backend();        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
