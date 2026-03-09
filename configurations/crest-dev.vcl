vcl 4.1;
    import std;
    import directors;

    backend crest {
        .host = "crest";
        .port = "80";
    }

    sub vcl_init {
        new cluster = directors.hash();
        cluster.add_backend(crest, 1);
    }

    

    sub vcl_recv {
        # Rewrite api-v5.0 paths to api-v6.0
        if (req.url ~ "^/api-v5\.0/") {
            set req.url = regsub(req.url, "^/api-v5\.0/", "/api-v6.0/");
        }

        # Store any client IMS header for debugging
        if (req.http.If-Modified-Since) {
            set req.http.X-Debug-IMS = req.http.If-Modified-Since;
        }        

        if (req.url == "/") {
          return (synth(301,"https://cern.ch/"));
        }
        
        if (req.method != "GET" && req.method != "HEAD") {
            return (pipe);
        }
    }


    # Store stale object info for later use
    sub vcl_hit {
        # Debug: mark that we had a cache hit
        set req.http.X-Had-Hit = "true";

        if (obj.ttl >= 0s) {
            # Object is fresh - serve it
            # Debug: store Last-Modified from cached object
            if (obj.http.Last-Modified) {
                set req.http.X-Cached-LM = obj.http.Last-Modified;
            } else {
                set req.http.X-Cached-LM = "NONE";
            }
            return (deliver);
        }

        # Object is stale - we need to do a conditional fetch from backend
        # Debug: mark stale hit
        set req.http.X-Stale-Hit = "true";

        # Store the Last-Modified from the stale object for revalidation
        # Set both the marker AND If-Modified-Since directly here
        if (obj.http.Last-Modified) {
            set req.http.X-Stale-Last-Modified = obj.http.Last-Modified;
            set req.http.If-Modified-Since = obj.http.Last-Modified;
        } else {
            # Debug: no Last-Modified in cached object
            set req.http.X-Stale-Last-Modified = "NO-LM-IN-CACHE";
        }

        # Use return(pass) - valid in VCL 4.1, preserves headers and goes to vcl_pass -> vcl_backend_fetch
        return (pass);
    }


    # Add conditional headers when fetching from backend (for cache misses)
    sub vcl_miss {
        # If we have a stale object's Last-Modified, use it for conditional request
        if (req.http.X-Stale-Last-Modified) {
            set req.http.If-Modified-Since = req.http.X-Stale-Last-Modified;
        }
    }

    # Handle pass requests (from vcl_hit when object is stale)
    sub vcl_pass {
        # In vcl_pass, only req is available (not bereq)
        # Headers set on req here will be copied to bereq for the backend fetch
        if (req.http.X-Stale-Last-Modified) {
            set req.http.If-Modified-Since = req.http.X-Stale-Last-Modified;
        }
    }

    # Set the If-Modified-Since header on the actual backend request
    sub vcl_backend_fetch {
        # Headers from req should be copied to bereq automatically
        # But explicitly set If-Modified-Since to be sure
        if (bereq.http.X-Stale-Last-Modified) {
            set bereq.http.If-Modified-Since = bereq.http.X-Stale-Last-Modified;
            set bereq.http.X-Varnish-Revalidate = "true";
        }
        # Also check if If-Modified-Since wasn't already set but we have the stale marker
        if (!bereq.http.If-Modified-Since && bereq.http.X-Stale-Last-Modified) {
            set bereq.http.If-Modified-Since = bereq.http.X-Stale-Last-Modified;
        }
    }

    sub vcl_backend_response {
        # Debug: capture backend's Last-Modified header
        if (beresp.http.Last-Modified) {
            set beresp.http.X-Backend-LM = beresp.http.Last-Modified;
        } else {
            set beresp.http.X-Backend-LM = "NONE";
        }

        # Handle 304 Not Modified from backend - refresh the cached object
        if (beresp.status == 304) {
            # Backend confirmed content unchanged - update TTL and return cached version
            # set beresp.ttl = 30s;
            set beresp.uncacheable = false;
            return (deliver);
        }

        # For normal responses, control caching behavior
        set beresp.keep = 1w;           # Keep objects for conditional requests
        # set beresp.ttl = 30s;           # Short TTL for testing
        set beresp.grace = 0s;          # Don't serve stale

        # Ensure we cache objects that have Last-Modified header
        if (beresp.http.Last-Modified) {
            set beresp.uncacheable = false;
        }

        # Pass through backend's Last-Modified
        # Don't add fake headers
    }

    sub vcl_deliver {
        # Add debugging headers to responses
        if (obj.hits > 0) {
            set resp.http.X-Cache-Hit = "HIT";
            set resp.http.X-Cache-Hits = obj.hits;
        } else {
            set resp.http.X-Cache-Hit = "MISS";
        }

        # Echo back the IMS header we received (if any)
        if (req.http.X-Debug-IMS) {
            set resp.http.X-Received-IMS = req.http.X-Debug-IMS;
        }

        # Show if this was a conditional request
        if (req.http.If-Modified-Since) {
            set resp.http.X-IMS-Request = "true";
        }

        # For 304 responses, indicate they came from Varnish
        if (resp.status == 304) {
            set resp.http.X-Varnish-304 = "true";
        }

        # Debug: show what IMS we sent to backend
        if (req.http.X-Stale-Last-Modified) {
            set resp.http.X-Sent-IMS = req.http.X-Stale-Last-Modified;
        }

        # Debug: show cached Last-Modified
        if (req.http.X-Cached-LM) {
            set resp.http.X-Cached-LM = req.http.X-Cached-LM;
        }

        # Debug: show if we had a stale hit
        if (req.http.X-Stale-Hit) {
            set resp.http.X-Stale-Hit = req.http.X-Stale-Hit;
        }

        # Debug: show if we had any cache hit
        if (req.http.X-Had-Hit) {
            set resp.http.X-Had-Hit = req.http.X-Had-Hit;
        }
    }

    sub vcl_synth {
        if (resp.status == 301) {
            set resp.http.location = resp.reason;
            set resp.reason = "Moved";
            return (deliver);
        }
    }