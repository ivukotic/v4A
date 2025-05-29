    vcl 4.1;
    import std;
    import dynamic;
    import directors;
    
    backend fermilab {
        .host = "cvmfs-srv.fnal.gov";
        .port = "8000";
    }
    backend bnl_1 {
        .host = "192.12.15.239";
        .port = "8000";
    }
    backend bnl_2 {
        .host = "192.12.15.244";
        .port = "8000";
    }
    backend cern_1 {
        .host = "128.142.194.109";
        .port = "80";
    }

    sub vcl_recv {

        if (req.method != "GET" && req.method != "HEAD") {
            return (pipe);
        }
        if (req.restarts == 0) {
            set req.backend_hint = cern_1;
        }
        if (req.restarts == 1) {
            set req.backend_hint = bnl_1;
        }
        if (req.restarts == 2) {
            set req.backend_hint = bnl_2;
        }
        if (req.restarts == 3) {
            set req.backend_hint = fermilab;
        }
    }

    sub vcl_backend_fetch {
        # this is needed for BNL CERN and some other backends
        unset bereq.http.host;
    }

    sub vcl_backend_response {
        if ( beresp.status != 200 ) {
            
            if (bereq.backend != cern_1 ){
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