# 1. Use Nginx (Alpine version is tiny, like 5MB)
FROM nginx:alpine

# 2. Copy the built web files into the Nginx server directory
# This takes the files you just built in Step 1
COPY build/web /usr/share/nginx/html

# 3. Expose Port 80 (Standard Web Port)
EXPOSE 80

# 4. Start Nginx
CMD ["nginx", "-g", "daemon off;"]