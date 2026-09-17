# raasel_org_website

## Deployment Note: Static Assets Path

Website images are served under `/icons/...`, not `/assets/...`:

- Keep source media files in the local project folder `assets/`.
- In the website container, publish them under `/icons/...`.
- In HTML, reference media as `/icons/...` (for example `/icons/raasel-logo.png`, `/icons/screen_shots/1.jpg`).

This convention dates from when the site shared a host with a separate MAS/OIDC
service that reserved `/assets`. That service is gone, so `raasel.org`'s proxy
no longer reserves `/assets` for anything — but the `/icons` convention is
kept for consistency with existing links/assets rather than churned for no
reason.

### Current Docker mapping

`Dockerfile` maps:

- `COPY assets/ /usr/share/nginx/html/icons/`

This keeps authoring assets in the `assets/` folder while safely serving them via `/icons` in production.