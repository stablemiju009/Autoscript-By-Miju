#!/bin/bash

echo "📦 Adding mobile-only and bot-blocking rules to Hestia NGINX default templates..."

TEMPLATE_DIR="/usr/local/hestia/data/templates/web/nginx"
TEMPLATE1="$TEMPLATE_DIR/default.stpl"
TEMPLATE2="$TEMPLATE_DIR/default.tpl"

BLOCK_RULE=$(cat << 'EOF'
    # 🛑 Bots, desktop aur API requests ko block karne ka rule
    if ($http_user_agent ~* "(bot|crawl|slurp|spider|python|curl|wget|headless|phantomjs)") {
        return 403;
    }

    if ($http_user_agent !~* "mobile|android|iphone|ipad|phone") {
        return 403;
    }

    if ($http_accept !~* "text/html") {
        return 403;
    }

    error_page 403 /custom-denied.html;

    location = /custom-denied.html {
        default_type text/html;
        return 200 '<!DOCTYPE html>
<html>
  <head>
    <title>Access Denied</title>
    <style>
      @import url("https://fonts.googleapis.com/css2?family=Poppins:wght@400;700&display=swap");
      body {
        background-color: #000;
        color: #fff;
        font-family: "Poppins", sans-serif;
        text-align: center;
        padding-top: 100px;
      }
      h1 { font-size: 28px; }
      p { font-size: 16px; margin-top: 10px; }
    </style>
  </head>
  <body>
    <h1>🤧Access Denied🤧</h1>
    <p>🦜OpMij Web-SerVer 🦜</p>
  </body>
</html>';
    }
EOF
)

insert_block_if_needed() {
  local file="$1"
  if grep -q 'bot|crawl|slurp' "$file"; then
    echo "✅ Already patched: $file"
  else
    echo "🔧 Patching: $file"
    # Insert before location /
    sed -i "/location \/ {/i $BLOCK_RULE" "$file"
  fi
}

insert_block_if_needed "$TEMPLATE1"
insert_block_if_needed "$TEMPLATE2"

echo "🔁 Applying default template to all domains..."

for user in $(v-list-users plain | cut -f1); do
    domains=$(v-list-web-domains $user plain | cut -f1)
    for domain in $domains; do
        echo "➡️ $user → $domain"
        v-change-web-domain-tpl $user $domain default default >/dev/null 2>&1
    done
done

echo "♻️ Restarting nginx..."
systemctl restart nginx

echo "✅ All done! Mobile-only blocking live on all sites."
