#!/usr/bin/env python3
"""Проверка материалов до сборки — то, чего не проверит движок.

У каждого материала (type: article) должны быть подпись автора со ссылкой, ступень из списка и место в ней;
адреса не повторяются. Без зависимостей: frontmatter разбирается вручную. Выходит с кодом 1 и списком ошибок.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STEPS = [str(n) for n in range(1, 11)]          # ступени курса ("10" — «Показать людям», в меню 9-я); новая — ещё и в rules.yaml, и в sidebar.html
NEED = ("description", "step", "order", "author", "author_url")


def frontmatter(path):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    out = {}
    for line in text[3:end].splitlines():
        m = re.match(r"^([a-z_]+):\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return out


def main():
    errors, slugs, count = [], {}, 0
    for path in sorted((ROOT / "content").rglob("*.md")):
        name = path.relative_to(ROOT)
        fm = frontmatter(path)
        if fm is None:
            errors.append(f"{name}: нет шапки между строками ---")
            continue
        slug = fm.get("slug")
        if slug in slugs:
            errors.append(f"{name}: адрес «{slug}» уже занят файлом {slugs[slug]}")
        slugs[slug] = name
        if fm.get("type") != "article":
            continue
        count += 1
        for key in NEED:
            if not fm.get(key):
                errors.append(f"{name}: не заполнено поле {key}")
        if fm.get("step") and fm["step"] not in STEPS:
            errors.append(f"{name}: ступени «{fm['step']}» нет — есть {STEPS[0]}…{STEPS[-1]}")
        if fm.get("author_url") and not fm["author_url"].startswith(("https://", "http://")):
            errors.append(f"{name}: author_url должен быть полным адресом")
    for e in errors:
        print("ошибка:", e, file=sys.stderr)
    print(f"материалов {count}, ошибок {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
