# specify the VCL syntax version to use
vcl 4.1;

# import vmod_dynamic for better backend name resolution
import dynamic;
import directors;

# backend backend1 {
#     .host = "atlasfrontier-ai.cern.ch";
#     .port = "8000";
# }

backend backend10 {
    .host = "2001:1458:201:e5::100:c1";
    .port = "8000";
}

backend backend11 {
    .host = "2001:1458:201:e5::100:5a";
    .port = "8000";
}

backend backend12 {
    .host = "188.184.29.207";
    .port = "8000";
}


backend backend2 {
    .host = "atlasfrontier1-ai.cern.ch";
    .port = "8000";
}

backend backend3 {
    .host = "atlasfrontier2-ai.cern.ch";
    .port = "8000";
}

sub vcl_init {
    
    new d = dynamic.director(port = "80");

    new vdir = directors.round_robin();
    vdir.add_backend(backend10);
    vdir.add_backend(backend11);
    vdir.add_backend(backend12);
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

    # return (lookup);
}

# # set up a dynamic director
# # for more info, see https://github.com/nigoroll/libvmod-dynamic/blob/master/src/vmod_dynamic.vcc
# sub vcl_init {
#         new d = dynamic.director(port = "80");
# }

# sub vcl_recv {
# 	# force the host header to match the backend (not all backends need it,
# 	# but example.com does)
# 	set req.http.host = "http://atlasfrontier-ai.cern.ch:8000/atlr)";
# 	# set the backend
# 	set req.backend_hint = d.backend("atlasfrontier-ai.cern.ch:8000/atlr)");
# }
