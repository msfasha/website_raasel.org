# raasel_com_website

## Deployment Note: Static Assets Path on raasel.com

Important: On the public domain `raasel.com`, the reverse proxy reserves `/assets` for MAS/OIDC routes.

Because of that, website images must not be served from `/assets/...` in page HTML. If you reference `/assets/...`, the public proxy may route those requests to MAS and return `404`, even if files exist in the website container.

Use this convention instead:

- Keep source media files in the local project folder `assets/`.
- In the website container, publish them under `/icons/...`.
- In HTML, reference media as `/icons/...` (for example `/icons/raasel-logo.png`, `/icons/screen_shots/1.jpg`).

### Why this exists

- `https://raasel.com/assets/*` is handled by MAS proxy paths.
- `https://raasel.com/icons/*` is handled by the website backend (`raasel-nginx`).

### Current Docker mapping

`Dockerfile` maps:

- `COPY assets/ /usr/share/nginx/html/icons/`

This keeps authoring assets in the `assets/` folder while safely serving them via `/icons` in production.