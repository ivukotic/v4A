# v4A

Varnish for ATLAS

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.

We support use of Varnish for Frontier accesses and for CVMFS accesses. Being a reverse proxy, it can't serve both from a single instance. Instructions and code for the Frontier accesses can be found in branch [frontier](https://github.com/ivukotic/v4A/tree/frontier), while instructions for CVMFS accesses are in [cvmfs](https://github.com/ivukotic/v4A/tree/cvmfs).

## Flux deployments of CERN based Frontiers and Varnishes (main branch)

The `main` branch contains [Flux](https://fluxcd.io/) (GitOps) deployments of the CERN based Frontier servers and the Varnish caches in front of them. Flux watches this branch and reconciles the Kubernetes cluster to match the manifests found here, so changes are deployed by committing them to `main`.

Each cluster has its own directory under [frontier/](frontier/), which Flux points at as a Kustomize entry point. There are currently three cluster deployments:

| Directory | Contents | Varnish `SITE` | Exposed as |
|-----------|----------|----------------|------------|
| [frontier-a/](frontier/frontier-a/) | Frontier servers + Varnish | `FRONTIER-A` | `v4f-a.cern.ch` (TLS via cert-manager / Let's Encrypt) |
| [frontier-b/](frontier/frontier-b/) | Frontier servers + Varnish | `FRONTIER-B` | `v4f-b.cern.ch` (TLS via cert-manager / Let's Encrypt) |
| [cern-local/](frontier/cern-local/) | Varnish only | `CERN` | Ingress by IP, plain HTTP |

```
frontier/
├── tnsnames.ora                    # Oracle connection info, shared by frontier-a and frontier-b
├── frontier-a/                     # Frontier + Varnish deployment A
│   ├── kustomization.yaml          # Kustomize entry point (resources + frontier-config ConfigMap)
│   ├── frontier-a.yaml             # Frontier server Deployment (registry.cern.ch/crest/frontier-service)
│   ├── varnish-a.yaml              # Varnish Deployment (ivukotic/v4a) caching Frontier responses
│   ├── services.yaml               # Services for Varnish (v4f) and Frontier (frontier-service)
│   ├── ingress-a.yaml              # Ingress exposing Varnish
│   └── context-secret-sealed.yaml  # SealedSecret with the Frontier DB context (context.xml)
├── frontier-b/                     # Frontier + Varnish deployment B (same layout as frontier-a)
│   └── ...
└── cern-local/                     # Varnish-only deployment
    ├── kustomization.yaml          # Kustomize entry point
    ├── varnish.yaml                # Varnish Deployment (ivukotic/v4a)
    ├── service.yaml                # Service for Varnish (v4f)
    └── ingress.yaml                # Ingress exposing Varnish (no host rule, clients use the IP)
```

In `frontier-a` and `frontier-b`, clients reach Varnish through the Ingress; Varnish serves cached responses from RAM and forwards cache misses to the Frontier servers running in the same cluster, which query the Oracle database. The Frontier DB credentials are committed only in encrypted form as [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), which the controller in each cluster decrypts into the `context-secret` Secret. The `tnsnames.ora` file is turned into the `frontier-config` ConfigMap by Kustomize.

`cern-local` runs only the Varnish cache; it has no Frontier servers of its own.
