# v4A

Varnish for ATLAS

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.

We support use of Varnish for Frontier accesses and for CVMFS accesses. Being a reverse proxy, it can't serve both from a single instance. Instructions and code for the Frontier accesses can be found in branch [frontier-no-snmp](https://github.com/ivukotic/v4A/tree/frontier-no-snmp), while instructions for CVMFS accesses are in [cvmfs-no-snmp](https://github.com/ivukotic/v4A/tree/cvmfs-no-snmp).
