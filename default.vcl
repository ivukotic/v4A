# specify the VCL syntax version to use
vcl 4.1;

# import vmod_dynamic for better backend name resolution
import dynamic;
import directors;

backend backend1 {
    .host = "cvmfs-s1fnal.opensciencegrid.org";
    .port = "8000";
}

backend backend2 {
    .host = "cvmfs-s1bnl.opensciencegrid.org";
    .port = "8000";
}

backend backend3 {
    .host = "cvmfs-s1goc.opensciencegrid.org";
    .port = "8000";
}

sub vcl_init {
    
    new d = dynamic.director(port = "80");

    new vdir = directors.round_robin();
    vdir.add_backend(backend1);
    vdir.add_backend(backend2);
    vdir.add_backend(backend3);    
}

sub vcl_recv {
    set req.backend_hint = vdir.backend();
    
    set req.http.X-frontier-id = "varnish";
    
    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }
}
