# specify the VCL syntax version to use
vcl 4.1;

# import vmod_dynamic for better backend name resolution
import dynamic;
import directors;

# CVMFS_REPOSITORIES
# atlas-condb.cern.ch CHECK
# atlas-nightlies.cern.ch NIGHTLIES 179, 180
# atlas.cern.ch CHECK
# cms.cern.ch CHECK
# geant4.cern.ch CHECK
# grid.cern.ch CHECK
# oasis.opensciencegrid.org CHECK
# sft.cern.ch CHECK
# unpacked.cern.ch CHECK

# 2ms cvmfs-s1fnal.opensciencegrid.org
# backend fermilab1 {
#     .host = "131.225.189.138";
#     .port = "8000";
# }
# backend fermilab2 {
#     .host = "2620:6a:0:8421::244";
#     .port = "8000";
# }

#25ms cvmfs-reverse2.sdcc.bnl.gov
backend bnl1 { 
    .host = "192.12.15.180";
    .port = "8000";
}
# 25ms cvmfs-reverse1.sdcc.bnl.gov
backend bnl2 {
    .host = "192.12.15.179";
    .port = "8000";
}

# backend testStratum1 {
#     .host ="oasis-replica-itb.opensciencegrid.org";
#     .port = "8000";
# }

# 17ms
# backend goc {
#     .host = "cvmfs-s1goc.opensciencegrid.org";
#     .port = "8000";
# }

# backend squid {
#     .host = "uct2-slate.mwt2.org";
#     .port = "32200";
# }

acl local {
 "localhost"; /* myself */
 "72.36.96.0"/24; 
 "149.165.224.0"/23; 
 "192.170.240.0"/23;
}

sub vcl_init {
    
    new vdir = directors.round_robin();
    # vdir.add_backend(fermilab1);
    # vdir.add_backend(fermilab2);
    vdir.add_backend(bnl1);
    vdir.add_backend(bnl2);
    # vdir.add_backend(goc);  
    # vdir.add_backend(squid);   
    # vdir.add_backend(testStratum1);    
}

# sub vcl_backend_fetch {
#     unset bereq.http.X-Varnish;
# }

# sub vcl_miss {
#     unset bereq.http.X-Varnish;
# }

sub vcl_recv {
    set req.backend_hint = vdir.backend();

    # set req.http.X-frontier-id = "varnish";
    
    if (!(client.ip ~ local)) {
        return (synth(405));
    } 

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }

}
