# specify the VCL syntax version to use
vcl 4.1;

# import vmod_dynamic for better backend name resolution
import dynamic;
import directors;

backend backend1 {
    .host = "cvmfs-s1fnal.opensciencegrid.org";
    .port = "8000";
}

backend backend21 {
    .host = "192.12.15.180";
    .port = "8000";
}

backend backend22 {
    .host = "192.12.15.179";
    .port = "8000";
}

backend backend3 {
    .host = "cvmfs-s1goc.opensciencegrid.org";
    .port = "8000";
}

acl local {
 "localhost"; /* myself */
 "192.168.0.0"/16; 
 "10.0.0.0"/8;
 "172.16.0.0"/12;
 "72.36.96.0"/24; 
 "149.165.224.0"/23; 
 "192.170.240.0"/23; 
}

sub vcl_init {
    
    # new d = dynamic.director(port = "80");

    new vdir = directors.round_robin();
    vdir.add_backend(backend1);
    vdir.add_backend(backend21);
    vdir.add_backend(backend22);
    vdir.add_backend(backend3);    
}

sub vcl_recv {
    set req.backend_hint = vdir.backend();
    
    set req.http.X-frontier-id = "varnish";
    
    if (!(client.ip ~ local)) {
        return (synth(405));
    } 

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }

}
