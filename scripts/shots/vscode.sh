#!/usr/bin/env bash
# Чистый VS Code для снимков курса: свой профиль, без расширений и настроек владельца компьютера.
#
#   scripts/shots/vscode.sh open <папка>          открыть папку в чистом окне (первый раз ставит Claude Code)
#   scripts/shots/vscode.sh prompt <файл.txt>     открыть новую вкладку Claude с этим текстом в поле ввода
#                                                 (не отправляет: отправляет человек)
#   scripts/shots/vscode.sh shot <часть-заголовка> <out.png>   снять только это окно, 1600 точек в ширину
#   scripts/shots/vscode.sh stop                  закрыть чистое окно
#
# Профиль — в ~/.vibewiki-vscode: путь короткий нарочно, длинный ломает сокет VS Code (предел 103 знака).
# Из терминала расширения VS Code переменные ELECTRON_RUN_AS_NODE и VSCODE_* запускают программу как Node —
# поэтому они снимаются. Claude Code в чистом профиле входит сам: вход общий для всего Mac (связка ключей).
# Свои настройки git и gh (GIT_CONFIG_GLOBAL, GH_CONFIG_DIR): в окне git без имени и входа, как на новом
# компьютере, а вход gh под учётной записью для демо не пропишется в общий ~/.gitconfig и не перехватит пуши
# владельца в его репозитории. Демо-папку открывать вне любого репозитория — иначе Claude сохранит в него.
# Перед публикацией снимка: блок «Recent» на стартовой странице показывает папки владельца — закрасить;
# вывод команд в разговоре может показать имя пользователя — закрасить.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$HOME/.vibewiki-vscode"
APP="/Applications/Visual Studio Code.app"
run() {
  env -u ELECTRON_RUN_AS_NODE -u VSCODE_IPC_HOOK -u VSCODE_IPC_HOOK_CLI -u VSCODE_PID -u VSCODE_CWD -u VSCODE_NLS_CONFIG \
    -u VSCODE_HANDLES_UNCAUGHT_ERRORS -u VSCODE_CRASH_REPORTER_PROCESS_TYPE -u VSCODE_ESM_ENTRYPOINT \
    -u VSCODE_CODE_CACHE_PATH -u VSCODE_NODE_COMPILE_CACHE_ROOT -u VSCODE_L \
    GIT_CONFIG_GLOBAL="$P/gitconfig" GH_CONFIG_DIR="$P/gh" \
    "$APP/Contents/MacOS/Code" --user-data-dir "$P/data" --extensions-dir "$P/ext" "$@"
}
case "${1:-}" in
  open)
    mkdir -p "$P/data/User" "$P/ext" "$P/gh"; touch "$P/gitconfig"
    [[ -f "$P/data/User/settings.json" ]] || cat > "$P/data/User/settings.json" <<'JSON'
{ "telemetry.telemetryLevel": "off", "update.mode": "none", "window.restoreWindows": "none",
  "workbench.colorTheme": "Default Light Modern", "extensions.ignoreRecommendations": true,
  "chat.disableAIFeatures": true, "workbench.secondarySideBar.defaultVisibility": "hidden", "workbench.tips.enabled": false }
JSON
    ls "$P/ext" | grep -q '^anthropic.claude-code' || ELECTRON_RUN_AS_NODE=1 "$APP/Contents/Resources/app/bin/code" \
      --user-data-dir "$P/data" --extensions-dir "$P/ext" --install-extension anthropic.claude-code
    nohup bash -c "$(declare -f run); P='$P'; APP='$APP'; run --new-window '$2'" >/dev/null 2>&1 &
    ;;
  prompt)
    # «+» в адресе расшифровывается дважды и становится пробелом — поэтому %2B кодируется ещё раз
    q=$(python3 -c "import sys,urllib.parse;print(urllib.parse.quote(open(sys.argv[1]).read().strip()).replace('%2B','%252B'))" "$2")
    run --open-url "vscode://anthropic.claude-code/open?prompt=$q" >/dev/null 2>&1
    ;;
  shot)
    id=$(swift "$HERE/winls.swift" | grep '^[0-9]* Code ' | grep -F -- "$2" | head -1 | cut -d' ' -f1)
    [[ -n "$id" ]] || { echo "окна с «$2» в заголовке нет" >&2; exit 1; }
    screencapture -x -o -l"$id" "$3" && sips --resampleWidth 1600 "$3" >/dev/null && echo "$3"
    ;;
  stop) pkill -f "$P/data" || true ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
