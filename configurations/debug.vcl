vcl 4.1;
import std;
import dynamic;
import directors;

backend bnl_1 {
    .host = "192.12.15.180";
    .port = "8000";
}
backend fermilab_1 {
    .host = "131.225.189.138";
    .port = "8000";
}
backend bnl_2 {
    .host = "192.12.15.179";
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
        set req.backend_hint = bnl_1;
    }
    if (req.restarts == 1) {
        set req.backend_hint = fermilab_1;
    }
    if (req.restarts == 2) {
        set req.backend_hint = bnl_2;
    }
    if (req.restarts == 3) {
        set req.backend_hint = cern_1;
    }
}

sub vcl_backend_fetch {
    # this is needed for BNL CERN and some other backends
    unset bereq.http.host;
}

sub vcl_backend_response {
    # Don't cache 404 responses
    if ( beresp.status == 404 ) {
        std.log(">>>>>>>>>>>>>>>> got 404 <<<<<<<<<<");
        # std.log(bereq.retries);  this is always 0
        # std.log(req.restarts); req not visible here
        std.log(bereq.backend);
        std.log("-----------------------------------");
        if (bereq.backend != cern_1 ){
            set beresp.uncacheable = true;
            return (deliver);
        } else {
            set beresp.ttl = 3s;
            std.log(">>>>>>>>>>>>>>>> CACHING 404 <<<<<<<<<<<<<<<<<<<<<<<");
        }
    }
}

sub vcl_deliver {
    if (resp.status == 404) {
        std.log(obj.uncacheable);
        if (obj.uncacheable){
            std.log(">> force retry <<<");
            return(restart);
        }
    }
}