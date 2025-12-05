vcl 4.1;
    import std;
    import directors;

    backend crest {
        .host = "crest";
        .port = "80";
    }

    sub vcl_init {
        new cluster = directors.hash();
        cluster.add_backend(crest, 1);
    }

    sub vcl_recv {

        # Rewrite api-v5.0 paths to api-v6.0
        if (req.url ~ "^/api-v5\.0/") {
            set req.url = regsub(req.url, "^/api-v5\.0/", "/api-v6.0/");
        }

        if (req.url == "/") {
          return (synth(301,"https://cern.ch/"));
        }
        
        if (req.method != "GET" && req.method != "HEAD") {
            return (pipe);
        }
    }

    sub vcl_synth {
        if (resp.status == 301) {
            set resp.http.location = resp.reason;
            set resp.reason = "Moved";
            return (deliver);
        }
    }
