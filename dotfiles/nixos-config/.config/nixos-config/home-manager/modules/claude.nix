{ pkgs, lib, ... }:
let
  # Merged into the files on every switch instead of linking them: Claude Code keeps
  # writing both (/config, permissions, its own state), so they must stay writable.
  # ~/.claude/settings.json: user settings.
  settings = {
    theme = "auto";
  };
  # ~/.claude.json: Claude's global state (login, projects, caches). Some options live
  # only here, not in settings.json.
  globalConfig = {
    # Open the agents view (background sessions list) when `claude` starts.
    defaultToAgentsView = true;
  };

  merge = pkgs.writeShellScript "claude-config-merge" ''
    set -eu
    # $1: file, $2: JSON to merge in. Keeps every other key and the file's mode.
    file=$1
    # A dangling link (e.g. an old stow link) would make the write below land in its target.
    if [ -L "$file" ] && [ ! -e "$file" ]; then rm "$file"; fi
    mkdir -p "$(dirname "$file")"
    [ -s "$file" ] || { (umask 077; echo '{}' > "$file"); }
    tmp=$(mktemp "$file.XXXXXX")
    if ${lib.getExe pkgs.jq} --argjson add "$2" '. * $add' "$file" > "$tmp"; then
      chmod --reference="$file" "$tmp" && mv "$tmp" "$file"
    else
      rm -f "$tmp"; exit 1
    fi
  '';
in
{
  home.activation.claudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${merge} "$HOME/.claude/settings.json" ${lib.escapeShellArg (builtins.toJSON settings)} \
      || warnEcho "claude: failed to update ~/.claude/settings.json, skipping"
    run ${merge} "$HOME/.claude.json" ${lib.escapeShellArg (builtins.toJSON globalConfig)} \
      || warnEcho "claude: failed to update ~/.claude.json, skipping"
  '';
}
