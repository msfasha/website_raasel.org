# Deploying to Contabo (production)

`raasel.org` is a static site (nginx serving prebuilt HTML — see
`Dockerfile`), hosted on a Contabo VPS. It used to be served from GitHub
Pages; this doc replaces that.

This doc is self-contained: it doesn't assume you have access to any other
repo on this machine. If you're reading it after this repo has been split
out on its own, everything below still applies as-is.

## Server details

- Host: `173.212.231.7`.
- User: `root` (or whatever deploy user was set up — check with whoever
  provisioned the box).
- The repo lives at `/opt/raasel.org` on the server.
- The site sits behind a shared nginx reverse proxy that also fronts other
  apps on the same box (e.g. `bayanat.dev`). That proxy is a separate
  project (`rproxy_nginx_gh`, typically at
  `/opt/supporting-services/rproxy_nginx_gh` on Contabo) — this repo does
  not own it, just attaches to its Docker network.

## How the site is deployed

1. `Dockerfile` builds an `nginx:alpine` image and copies the static
   files in (`index.html`, `en/`, `ar/`, `light/`, `assets/` → served as
   `/icons/`, `privacy/`, `terms/`, `aup/`, `copyright/`, `logo.png`), with
   routing rules in `nginx/default.conf`.
2. `docker-compose.yml` builds and runs that image as container
   `raasel-website`, aliased as `raasel-nginx` on the external Docker
   network `rproxy_nginx_gh_app-network`. It does **not** publish any port
   to the host — only the reverse proxy talks to it, over that network.
3. The reverse proxy's nginx has a server block for `raasel.org` (and
   `www.raasel.org`) that proxies to `http://raasel-nginx:80`.

## One-time setup

### 1. Clone and start the site container
```bash
ssh root@173.212.231.7
mkdir -p /opt/raasel.org
git clone https://github.com/msfasha/website_raasel.org.git /opt/raasel.org
cd /opt/raasel.org
docker compose up --build -d
```
This alone does nothing publicly reachable yet — the reverse proxy doesn't
know about it until step 2.

### 2. Add the reverse-proxy server block
On Contabo, in the reverse proxy's `nginx/conf.d/` (e.g.
`/opt/supporting-services/rproxy_nginx_gh/nginx/conf.d/raasel-org.conf`):

```nginx
server {
    listen 80;
    server_name raasel.org www.raasel.org;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name raasel.org www.raasel.org;

    ssl_certificate     /etc/letsencrypt/live/raasel.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/raasel.org/privkey.pem;

    location / {
        resolver 127.0.0.11 valid=30s;
        set $upstream_raasel_org http://raasel-nginx:80;
        proxy_pass $upstream_raasel_org;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Don't reload nginx yet — it will refuse to start referencing a cert that
doesn't exist. Issue the cert first (step 4), then reload.

### 3. Point DNS at Contabo
In the registrar (GoDaddy) for `raasel.org`:

| Type | Name | Value |
|---|---|---|
| A | `@` | `173.212.231.7` |
| A | `www` | `173.212.231.7` |

Remove the old GitHub Pages records (four `A` records on `@`, and a
`CNAME`/`A` on `www`). Wait for propagation (`dig raasel.org` should show
the Contabo IP) before issuing the cert — Let's Encrypt's HTTP-01 challenge
needs DNS already pointing here.

### 4. Issue the TLS certificate
Give `raasel.org` its own certificate (don't fold it into another app's
bundle — see the reverse proxy's own README on why: one bad domain in a
shared cert request fails the whole request). On Contabo, in the reverse
proxy's directory:

```bash
docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email admin@bayanat.dev \
  --agree-tos --no-eff-email \
  -d raasel.org -d www.raasel.org \
  --cert-name raasel.org
```

Then reload:
```bash
docker compose exec nginx nginx -t && docker compose exec nginx nginx -s reload
```
Certbot's existing renewal cron on that box picks this cert up
automatically going forward — no extra renewal setup needed.

### 5. Verify, then turn off GitHub Pages
- Confirm `https://raasel.org` and `https://www.raasel.org` load correctly
  and the cert is valid.
- Only then disable GitHub Pages: repo `msfasha/website_raasel.org` →
  Settings → Pages → Unpublish site (or `gh api -X DELETE
  repos/msfasha/website_raasel.org/pages`). Doing this before DNS has
  cut over takes the site offline — always do it last.

## Redeploying after a change

No CI is set up yet. Until it is, deploy by hand:
```bash
ssh root@173.212.231.7
cd /opt/raasel.org
git pull
docker compose up --build -d
```

A GitHub Actions workflow (SSH in + `git pull && docker compose up --build
-d` on push to `main`, mirroring how Bayanat deploys) can be added later if
wanted — not set up yet.
