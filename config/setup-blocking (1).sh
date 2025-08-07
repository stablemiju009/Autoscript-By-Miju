#!/bin/bash

echo "🛠 Creating & Applying strict mobile-only and bot-blocking NGINX template..."

BLOCK_TEMPLATE_PATH="/usr/local/hestia/data/templates/web/nginx/opmij_block.tpl"

cat <<EOF > $BLOCK_TEMPLATE_PATH
server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% www.%domain_idn%;
    access_log  /var/log/%web_system%/domains/%domain%.log combined;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    location / {
                # removed: set $ua $http_user_agent;
        # removed: set $accept $http_accept;

        # Allow only HTML requests
        if ($http_accept !~ "text/html") {
            proxy_pass      http://%ip%:%web_port%;
            include         /etc/nginx/proxy_params;
            break;
        }

        # Block bots
        if ($http_user_agent ~* "(googlebot|bingbot|slurp|duckduckbot|baiduspider|yandex|sogou|exabot|facebot|ia_archiver|python|curl|wget|headless|phantomjs)") {
            return 200 '<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Access Denied</title></head>
<body style="background:#000;color:#fff;text-align:center;padding-top:100px;font-family:Arial;">
<h1>🤧 Access Denied 🤧</h1><p>🦜 OpMij Web‑SerVer 🦜</p></body></html>';
        }

        # Strictly block known desktop OS platforms
        if ($http_user_agent ~* "(Windows NT|Macintosh|X11|Linux x86_64|WOW64)") {
            return 200 '<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Access Denied</title></head>
<body style="background:#000;color:#fff;text-align:center;padding-top:100px;font-family:Arial;">
<h1>🤧 Access Denied 🤧</h1><p>🦜 OpMij Web‑SerVer 🦜</p></body></html>';
        }

        proxy_pass      http://%ip%:%web_port%;
        include         /etc/nginx/proxy_params;
    }

    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;
    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
EOF

echo "✅ Template created: $BLOCK_TEMPLATE_PATH"
echo "➡️ Now go to HestiaCP > Web > Edit your domain and apply 'opmij_block' as NGINX template."
echo "🔄 After that, reload NGINX using: sudo systemctl reload nginx"
