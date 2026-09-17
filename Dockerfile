FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY en/ /usr/share/nginx/html/en/
COPY icons/ /usr/share/nginx/html/icons/
COPY downloads/ /usr/share/nginx/html/downloads/
COPY logo.png /usr/share/nginx/html/logo.png
COPY privacy/ /usr/share/nginx/html/privacy/
COPY terms/ /usr/share/nginx/html/terms/
COPY aup/ /usr/share/nginx/html/aup/
COPY copyright/ /usr/share/nginx/html/copyright/
COPY ar/ /usr/share/nginx/html/ar/
COPY light/ /usr/share/nginx/html/light/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
