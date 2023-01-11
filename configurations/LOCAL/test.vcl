vcl 4.1;
import std;
import dynamic;
import directors;

backend fermilab_2 {
    .host = "2620:6a:0:8421::244";
    .port = "8000";
}
backend bnl_1 {
    .host = "192.12.15.180";
    .port = "8000";
}
backend cern_2 {
    .host = "2001:1458:301:cd::100:41d";
    .port = "80";
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
        set req.backend_hint = fermilab_2;
    }
    if (req.restarts == 1) {
        set req.backend_hint = bnl_1;
    }
    if (req.restarts == 2) {
        set req.backend_hint = cern_2;
    }
    if (req.restarts == 3) {
        set req.backend_hint = fermilab_1;
    }
    if (req.restarts == 4) {
        set req.backend_hint = bnl_2;
    }
    if (req.restarts == 5) {
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
        if (bereq.retries < ({{$nindex}}-1) ){
            set beresp.uncacheable = true;
            return (deliver);
        } else {
            std.log(">> caching 404 <<");
        }
    }
}


sub vcl_deliver {
    if (resp.status == 404) {
        std.log(">> force retry <<<");
        return(restart);
    }
}
