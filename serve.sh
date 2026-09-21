#!/usr/bin/env bash
# Піднімає локальний HTTPS-сервер, щоб відкрити ParanoicCrypt з телефона
# (iPhone не запускає локальні HTML-файли — потрібна саме адреса https://).
# Запуск:  ./serve.sh      Зупинка: Ctrl+C
set -e
cd "$(dirname "$0")"
PORT="${1:-8443}"
CERT="$HOME/.cache/paranoiccrypt-cert.pem"

if [ ! -f "$CERT" ]; then
  echo "Створюю самопідписаний сертифікат (одноразово)..."
  mkdir -p "$(dirname "$CERT")"
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$CERT" -out "$CERT" \
    -days 825 -subj "/CN=ParanoicCrypt" >/dev/null 2>&1
fi

IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
[ -z "$IP" ] && IP=$(hostname -I | awk '{print $1}')

echo
echo "  Відкрий на телефоні (той самий Wi-Fi):"
echo
echo "     https://$IP:$PORT/index.html"
echo
echo "  Safari попередить про сертифікат — це нормально для домашнього сервера:"
echo "  «Подробиці» → «Відвідати цей сайт» → «Відвідати»."
echo "  Зупинити: Ctrl+C"
echo

python3 - "$PORT" "$CERT" <<'PY'
import http.server, ssl, sys, functools
port=int(sys.argv[1]); cert=sys.argv[2]
ctx=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.load_cert_chain(cert)
handler=functools.partial(http.server.SimpleHTTPRequestHandler)
srv=http.server.ThreadingHTTPServer(("0.0.0.0",port), handler)
srv.socket=ctx.wrap_socket(srv.socket, server_side=True)
try: srv.serve_forever()
except KeyboardInterrupt: print("\nСервер зупинено.")
PY
