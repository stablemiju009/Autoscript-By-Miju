#!/bin/bash

echo "🛠 Applying mobile-only access and bot blocking NGINX template..."

BLOCK_TEMPLATE_PATH="/usr/local/hestia/data/templates/web/nginx/opmij_block.tpl"

cat <<EOF > $BLOCK_TEMPLATE_PATH
server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% www.%domain_idn%;
    access_log  /var/log/%web_system%/domains/%domain%.log combined;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    location / {
        set $ua $http_user_agent;
        set $accept $http_accept;

        if ($http_accept !~ "text/html") {
            proxy_pass      http://%ip%:%web_port%;
            include         /etc/nginx/proxy_params;
            break;
        }

        if ($ua ~* "(googlebot|bingbot|slurp|duckduckbot|baiduspider|yandex|sogou|exabot|facebot|ia_archiver|python|curl|wget|headless|phantomjs)") {
            return 200 '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Access Denied</title>
  <style>
    body {
      background-color: #000;
      color: #fff;
      font-family: Arial, sans-serif;
      text-align: center;
      padding-top: 100px;
    }
    h1 {
      font-size: 28px;
    }
    p {
      font-size: 16px;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <h1>🤧 Access Denied 🤧</h1>
  <p>🦜 OpMij Web‑SerVer 🦜</p>
</body>
</html>';
        }

        if ($ua !~* "(mobile|android|iphone|ipad|phone)") {
            return 200 '<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Access Denied</title>
  <style>
    body {
      background-color: #000;
      color: #fff;
      font-family: Arial, sans-serif;
      text-align: center;
      padding-top: 100px;
    }
    h1 {
      font-size: 28px;
    }
    p {
      font-size: 16px;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <h1>🤧 Access Denied 🤧</h1>
  <p>🦜 OpMij Web‑SerVer 🦜</p>
</body>
</html>';
        }

        proxy_pass      http://%ip%:%web_port%;
        include         /etc/nginx/proxy_params;
    }

    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;
    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
EOF

echo "✅ Template updated: $BLOCK_TEMPLATE_PATH"
echo "➡️  Apply this template to your domain via HestiaCP panel."