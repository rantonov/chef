### BACKEND START ###
backend zendyhealthapi {
    .host = "127.0.0.1";
    .port = "8080";
        .probe = {
                        .url = "/zendyhealthapi/healthcheck";
                        .interval = 3s;
                        .window = 5;
                        .threshold = 2;
        }
}
### BACKEND END ###

### VCL_RECV START ###
if (req.url ~ "^/zendyhealthapi") {

        /* Set the correct backend based on the URI */
        set req.backend = zendyhealthapi;
        return (pipe);
}

### VCL_RECV END ###

### VCL_FETCH START ###
if (req.url ~ "^/zendyhealthapi") {

        /* Do not cache the following list of http status codes */
        if (beresp.status == 404 ||
                beresp.status == 400 ||
                beresp.status == 503 ||
                beresp.status == 500 ||
                beresp.status == 206) {
                        set beresp.http.X-Cacheable = "NO: beresp.status";
                        set beresp.http.X-Cacheable-status = beresp.status;
                        return (hit_for_pass);
        } else {
                /* Cache all other responses and set the object lifetime grace and ttl */
                set beresp.ttl = 120s;
                set beresp.grace = 24h;
                return (deliver);
        }
}
### VCL_FETCH END ###
