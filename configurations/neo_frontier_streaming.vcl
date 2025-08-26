vcl 4.1;

backend default {
    .host = "v4f.cern.ch";
    .port = "80";
}

sub vcl_backend_fetch {
    set bereq.http.Host = "v4f.cern.ch";
}

sub vcl_backend_response {
    set beresp.do_stream = true;
}

sub vcl_recv {

  if (!req.http.X-frontier-id) {
      return (synth(403, "Forbidden: Missing required header"));
   }

  set req.backend_hint = default;        
  set req.http.X-frontier-id = "varnish";
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}

