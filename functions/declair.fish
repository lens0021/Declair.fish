function declair
    argparse --stop-nonopt -- $argv

    if functions --query _declair_$argv[1]
        _declair_$argv[1] $argv[2..]
    else
        _declair_help
    end
end

function _declair_help
    echo "\
Usage: declair subcommand

Subcommands:
    update
    pm
"
end

function _declair_update_rc
    set -f last_updated $_declair_last_updated
    if test -n $last_updated
        and test (math $last_updated + '60*60*12') -lt (date +%s)

        read -lP 'The last updated date is too old. Check the updates? ' do_update
        switch $do_update
            case Y y yes
                _declair_update
                set -U _declair_last_updated (date +%s)
        end
    end
end

function _declair_update
    if functions -q fisher
        fisher update
    end
    _declair_update_git_repositories
end

function _declair_update_git_repositories
    if test -z $_declair_target_repositories
        echo _declair_target_repositories is empty. Please set.
        return
    end

    echo Updating repositories...
    for repo in (string split ' ' $_declair_target_repositories)
        echo  updating $repo
        git -C $repo checkout main
        git -C $repo pull
    end
end
function _declair_pm
  argparse --stop-nonopt -- $argv

  if functions --query _declair_pm_$argv[1]
    _declair_pm_$argv[1] $argv[2..]
  else
    _declair_pm_help
  end
end


function _declair_pm_help
  echo "\
Usage: declair pm subcommand

Subcommands:
  install
  remove
  update
  upgrade
"
end

function  _declair_pm_update
  argparse --stop-nonopt -- $argv
  rpm --query --all | read -az pkg_installeds
  set -f pkg_desireds (_declair_pm_list)
  for desired in $pkg_desireds
    set -l is_installed false
    for installed in $pkg_installeds
      if string match --quiet --entire $desired $installed
        set is_installed true
        # $desired is already installed
        break
      end
    end
    if [ $is_installed = 'false' ]
      echo TODO install $desired
    end
    # _declair_pm_install $desired
  end
end

function  _declair_pm_install
  argparse --stop-nonopt -- $argv
  set -f pkg_name $argv[1]

  if dnf -Cq list $pkg_name >/dev/null
    echo $pkg_name seems to be already installed.

    set -f pkg_version (rpm --query $pkg_name --queryformat "%{VERSION}")
    _declair_pm_add_json $pkg_name $pkg_version
    # _declair_pm_add_json --lock $pkg_name $pkg_version
  else
    sudo dnf install -y $argv[1..]
  end
end

function  _declair_pm_remove
  argparse --stop-nonopt -- $argv
  sudo dnf remove $argv[1]
end

function  _declair_pm_upgrade
  argparse --stop-nonopt -- $argv
  sudo dnf upgrade $argv[1]
end

function _declair_pm_add_json
  argparse --stop-nonopt 'l/lock' -- $argv
  if set -q _flag_lock
    set --function pm_file $__fish_config_dir/declair.lock
  else
    set --function pm_file $__fish_config_dir/declair.json
  end

  if [ ! -e $pm_file ]
    echo '{}' > $pm_file
  end

  if ! yq -e .version $pm_file 1>/dev/null 2>/dev/null
    yq -i '.version = 1' $pm_file 1>/dev/null 2>/dev/null
  end

  yq -i ".rpm[\"$argv[1]\"] = \"$argv[2]\"" $pm_file 1>/dev/null 2>/dev/null
end

function _declair_pm_list
  yq -oy '.rpm | keys | .[]' ~/.config/fish/declair.json
end
