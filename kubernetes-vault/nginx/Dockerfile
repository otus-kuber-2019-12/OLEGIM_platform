FROM nginx:alpine
RUN mkdir app
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./index.html /app/index.html
WORKDIR /app
USER 1001
EXPOSE 8443/tcp
CMD ["nginx", "-g", "daemon off;"]