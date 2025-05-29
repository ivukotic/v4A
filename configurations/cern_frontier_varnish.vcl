vcl 4.1;
import std;
import dynamic;
import directors;

backend frontier {
    .host = "frontier-service";
    .port = "80";
}

sub vcl_init {
    new cluster = directors.hash();
    cluster.add_backend(frontier, 1);
}

sub vcl_recv {

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