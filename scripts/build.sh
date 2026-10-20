#!/usr/bin/env bash
# Сборка курса: проверка материалов -> dist/. Ничего не коммитит и не публикует.
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "1/2 Материалы"
python3 scripts/check.py

NOTEPUB_REF="${NOTEPUB_REF:-864920de7068737d5e95bc15b0e45dc1c3436da3}"
NOTEPUB_BIN="${NOTEPUB_BIN:-}"
if [[ -z "$NOTEPUB_BIN" ]]; then
  if [[ -x "$ROOT_DIR/.bin/notepub" ]]; then NOTEPUB_BIN="$ROOT_DIR/.bin/notepub"
  elif [[ -x "$ROOT_DIR/../site/.bin/notepub" ]]; then NOTEPUB_BIN="$ROOT_DIR/../site/.bin/notepub"
  elif command -v notepub >/dev/null 2>&1; then NOTEPUB_BIN="$(command -v notepub)"
  else
    command -v go >/dev/null 2>&1 || { echo "Ошибка: не найден notepub и не установлен Go." >&2; exit 1; }
    mkdir -p "$ROOT_DIR/.bin"
    GOBIN="$ROOT_DIR/.bin" go install "github.com/cookiespooky/notepub/cmd/notepub@${NOTEPUB_REF}"
    NOTEPUB_BIN="$ROOT_DIR/.bin/notepub"
  fi
fi

CONFIG="${CONFIG:-./config.yaml}"; DIST="${DIST:-./dist}"
echo "2/2 Сайт ($CONFIG -> $DIST)"
rm -rf "$DIST" .notepub
mkdir -p "$DIST"
"$NOTEPUB_BIN" validate --config "$CONFIG" --rules ./rules.yaml
"$NOTEPUB_BIN" index --config "$CONFIG" --rules ./rules.yaml
"$NOTEPUB_BIN" validate --config "$CONFIG" --rules ./rules.yaml --resolve ./.notepub/artifacts/resolve.json --links --markdown
"$NOTEPUB_BIN" build --config "$CONFIG" --rules ./rules.yaml --dist "$DIST" --artifacts ./.notepub/artifacts
# снимки экрана к материалам: в тексте — ![…](/media/shots/имя.png), движок выводит их от media_base_url
if [[ -d media ]]; then mkdir -p "$DIST/media"; cp -R media/. "$DIST/media/"; fi
touch "$DIST/.nojekyll"
echo "Готово: $DIST — не закоммичено и не опубликовано"
