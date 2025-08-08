vcl 4.1;

backend default {
    .host = "v4f.cern.ch";
    .port = "80";
}

sub vcl_backend_fetch {
    set bereq.http.Host = "v4f.cern.ch";
    if (bereq.http.X-Frontier-Id ~ "\[([^\]]+)\]") {
      set bereq.http.X-Frontier-Id = regsub(bereq.http.X-Frontier-Id, ".*\[(.*?)\].*", "\1");
    } else {
      set bereq.http.X-Frontier-Id = "varnish"; 
    }
}

sub vcl_recv {

  if (!req.http.X-frontier-id) {
      return (synth(403, "Forbidden: Missing required header"));
   }

  set req.backend_hint = default;        
  if (req.method != "GET" && req.method != "HEAD") {
    return (pipe);
  }
}
