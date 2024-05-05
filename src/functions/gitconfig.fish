function _declair_gitconfig
  argparse --stop-nonopt -- $argv

  if functions --query _declair_gitconfig_$argv[1]
    _declair_gitconfig_$argv[1] $argv[2..]
  else
    _declair_gitconfig_help
  end
end

function _declair_gitconfig_help
  echo "\
Usage: declair gitconfig subcommand

Subcommands:
  push
  pull
"
end

function  _declair_gitconfig_push
  set --function pm_file $__fish_config_dir/declair.json

  yq -oj -i ".git.config = {}" $pm_file
  for conf in (git config --global --list)
    set -l key (echo $conf | cut -d= -f1)
    set -l val (echo $conf | cut -d= -f2)
    yq -oj -i ".git.config[\"$key\"] = \"$val\"" $pm_file
  end
end

function  _declair_gitconfig_pull
  set --function pm_file $__fish_config_dir/declair.json

  for conf in (git config --global --list | cut -d= -f1)
    git config --global --unset-all $conf
  end

  for conf in (yq -oy '.git.config | keys | .[]' $pm_file)
    set -l val (yq -oy ".git.config[\"$conf\"]" $pm_file)
    git config --global "$conf" "$val"
  end
end
