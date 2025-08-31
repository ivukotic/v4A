vcl 4.1;
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
        .expected_response = 302;
        .host_header = "v4f.cern.ch";
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
        .expected_response = 302;
        .host_header = "v4fb.cern.ch";
    }
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

  if (std.healthy(neo_2)) {
      set req.backend_hint = neo_2;
  } else {
      set req.backend_hint = neo_1;
  }

}
