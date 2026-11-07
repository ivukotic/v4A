# v4A

Varnish for ATLAS

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.

We support use of Varnish for Frontier accesses and for CVMFS accesses. Being a reverse proxy, it can't serve both from a single instance. Instructions and code for the Frontier accesses can be found in branch [frontier](https://github.com/ivukotic/v4A/tree/frontier), while instructions for CVMFS accesses are in [cvmfs](https://github.com/ivukotic/v4A/tree/cvmfs).

## Flux deployments of CERN based Frontiers and Varnishes (main branch)

The `main` branch contains [Flux](https://fluxcd.io/) (GitOps) deployments of the CERN based Frontier servers and the Varnish caches in front of them. Flux watches this branch and reconciles the Kubernetes cluster to match the manifests found here, so changes are deployed by committing them to `main`.

Each deployment lives in its own directory under [frontier/](frontier/):

```
frontier/
├── frontier-b/                 # one Frontier + Varnish deployment
│   ├── kustomization-b.yaml    # Kustomize entry point (resources, ConfigMap and Secret generators)
│   ├── frontier-b.yaml         # Frontier server Deployment (registry.cern.ch/crest/frontier-service)
│   ├── varnish-b.yaml          # Varnish Deployment (ivukotic/v4a) caching Frontier responses
│   ├── services.yaml           # Services for Varnish (v4f) and Frontier (frontier-service)
│   └── ingress-b.yaml          # Ingress exposing Varnish
└── secrets/                    # NOT committed (git-ignored)
    ├── tnsnames.ora            # Oracle connection info -> ConfigMap frontier-config
    └── context.xml             # Frontier DB context/credentials -> Secret context-secret
```

Clients reach Varnish through the Ingress; Varnish serves cached responses from RAM and forwards cache misses to the Frontier servers, which query the Oracle database.
