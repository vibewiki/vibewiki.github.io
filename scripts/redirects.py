#!/usr/bin/env python3
"""Страницы-переходы со старого адреса курса — для репозитория vibewiki/vibecourse.

    python3 scripts/redirects.py <dist> <папка>

До 2026-10-23 курс жил по адресу https://vibewiki.github.io/vibecourse/ (репозиторий vibewiki/vibecourse), потом
переехал в корень домена — репозиторий переименован в vibewiki/vibewiki.github.io. GitHub не переводит Pages
переименованного репозитория, поэтому под старым именем заведён новый репозиторий, где на каждый адрес собранного
сайта лежит страница-переход: мгновенный meta refresh (поисковики считают его постоянным переходом), canonical на
новый адрес и скрипт, который сохраняет #якорь. Всё прочее под /vibecourse/ ловит 404.html — тем же скриптом.

Страницы берутся из собранного dist/ (вместе с черновиками — движок собирает и их, и на них ведут ссылки снаружи).
Новая страница в курсе — пересоберите и выложите переходы снова; без этого её старого адреса просто не было.
"""
import html
import sys
from pathlib import Path

NEW = "https://vibewiki.github.io"
DIST, OUT = Path(sys.argv[1]), Path(sys.argv[2])

PAGE = """<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Курс переехал</title>
<link rel="canonical" href="{url}">
<meta http-equiv="refresh" content="0; url={url}">
<script>location.replace({js} + location.search + location.hash);</script>
</head>
<body style="font: 16px/1.5 system-ui, sans-serif; margin: 40px 16px; color: #1b2128; background: #f5f6f7">
<p>Курс «Вайбкодинг с нуля» переехал: <a href="{url}">{url}</a></p>
</body>
</html>
"""

FALLBACK = """<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Курс переехал</title>
<script>location.replace("{new}" + location.pathname.replace(/^\\/vibecourse/, "") + location.search + location.hash);</script>
</head>
<body style="font: 16px/1.5 system-ui, sans-serif; margin: 40px 16px; color: #1b2128; background: #f5f6f7">
<p>Курс «Вайбкодинг с нуля» переехал: <a href="{new}/">{new}/</a></p>
</body>
</html>
"""


def stub(url):
    return PAGE.format(url=html.escape(url), js='"' + url.replace('"', '\\"') + '"')


def main():
    n = 0
    for f in sorted(DIST.rglob("index.html")):
        rel = f.parent.relative_to(DIST).as_posix()
        url = NEW + "/" + (rel + "/" if rel != "." else "")
        target = OUT / ("" if rel == "." else rel) / "index.html"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(stub(url), encoding="utf-8")
        n += 1
    (OUT / "404.html").write_text(FALLBACK.format(new=NEW), encoding="utf-8")
    (OUT / ".nojekyll").write_text("", encoding="utf-8")
    (OUT / "README.md").write_text(
        "# Курс переехал\n\nКурс «Вайбкодинг с нуля» теперь живёт по адресу https://vibewiki.github.io/ — "
        "репозиторий [vibewiki/vibewiki.github.io](https://github.com/vibewiki/vibewiki.github.io).\n\n"
        "Здесь только страницы-переходы со старых адресов `vibewiki.github.io/vibecourse/…`; их делает "
        "`scripts/redirects.py` в репозитории курса.\n", encoding="utf-8")
    print(f"переходов: {n} и 404.html → {OUT}")


if __name__ == "__main__":
    main()
