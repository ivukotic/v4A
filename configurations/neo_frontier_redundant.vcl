vcl 4.1;
# import directors;
import std;

backend neo_1 {
    .host = "v4f.cern.ch";
    .port = "80";    
    .probe = {
        .url = "/atlr";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }

}

backend neo_2 {
    .host = "v4fb.cern.ch";
    .port = "80";    
    .probe = {
        .url = "/atlr";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

sub vcl_init {
    new origin_hash = directors.hash();
    origin_hash.add_backend(neo_1);
    origin_hash.add_backend(neo_2);
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

    # Manual hash-based routing
    if (std.integer(std.hash(req.url) % 2) == 0) {
        if (neo_1.healthy) {
            set req.backend_hint = neo_1;
        } else {
            set req.backend_hint = neo_2;
        }
    } else {
        if (neo_2.healthy) {
            set req.backend_hint = neo_2;
        } else {
            set req.backend_hint = neo_1;
        }
    }

}
