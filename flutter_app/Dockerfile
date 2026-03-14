# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Removed the obsolete libgconf-2-4 and lib32stdc++6, added xz-utils
RUN apt-get update && apt-get install -y \
    curl git wget unzip xz-utils gdb libstdc++6 libglu1-mesa fonts-droid-fallback python3

WORKDIR /usr/local
RUN git clone https://github.com/flutter/flutter.git -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter doctor -v

WORKDIR /app
COPY . .

# Pass the base URL so the container knows where the API is
RUN flutter build web --dart-define=API_BASE_URL=http://localhost:4000

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]