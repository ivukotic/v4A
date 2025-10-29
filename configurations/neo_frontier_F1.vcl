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
    }
}

sub vcl_backend_fetch {
    if (bereq.backend == neo_1) {
        set bereq.http.Host = "v4f.cern.ch";
    } else if (bereq.backend == neo_2) {
        set bereq.http.Host = "v4fb.cern.ch";
    }    
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

  if (std.healthy(neo_1)) {
      set req.backend_hint = neo_1;
  } else {
      set req.backend_hint = neo_2;
  }

}
