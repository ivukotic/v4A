    vcl 4.1;
    import std;
    import directors;

    backend arbutus {
        .host = "cvmfs-s1-arbutus.computecanada.ca";
        .port = "8000";
    }
    backend beluga {
        .host = "cvmfs-s1-beluga.computecanada.ca";
        .port = "8000";
    }
    backend east {
        .host = "cvmfs-s1-east.computecanada.ca";
        .port = "8000";
    }

    sub vcl_recv {

        if (req.method != "GET" && req.method != "HEAD") {
            return (pipe);
        }
        if (req.restarts == 0) {
            set req.backend_hint = arbutus;
        }
        if (req.restarts == 1) {
            set req.backend_hint = beluga;
        }
        if (req.restarts == 2) {
            set req.backend_hint = east;
        }
    }

    sub vcl_backend_fetch {
        # this is needed for BNL CERN and some other backends
        unset bereq.http.host;
    }

    sub vcl_backend_response {
        set beresp.do_stream = true;
        if ( beresp.status != 200 ) {
            
            if (bereq.backend != east ){
                # unless this is a last of backends don't cache it so 
                # other backends can be tried
                set beresp.uncacheable = true;
                return (deliver);
            } else {
                std.log(">> caching Response <<");
                set beresp.ttl = 180s;
            }
        }
    }

    sub vcl_deliver {
        if (resp.status != 200) {
            if (obj.uncacheable){
                # not all the backends were tried yet
                std.log(">> force restart <<<");
                return(restart);
            }
        }
    }