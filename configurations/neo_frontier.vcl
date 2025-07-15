vcl 4.1;

backend default {
    .host = "v4f.cern.ch";
    .port = "80";
}

sub vcl_recv {
  set req.backend_hint = default;        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
