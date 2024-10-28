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
  sym
  gitconfig
"
end
function _declair_update_rc
    set -f last_updated $_declair_last_updated
    if test -n $last_updated
        and test (math $last_updated + '60*60*12') -lt (date +%s)

        read -lP 'The last updated date is too old. Check the updates? (s to skip) ' do_update
        switch $do_update
            case Y y yes
                _declair_update
                set -U _declair_last_updated (date +%s)
            case S s
                set -U _declair_last_updated (date +%s)
        end
    end
end

function _declair_update
    if functions -q fisher
        fisher update
    end
    _declair_update_git_repositories
    declair pm update
    declair sym update
    declair gitconfig pull
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

function _declair_gitconfig_push
    set --function pm_file $__fish_config_dir/declair.json

    yq -oj -i ".git.config = {}" $pm_file
    for conf in (git config --global --list)
        set -l key (echo $conf | cut -d= -f1)
        set -l val (echo $conf | cut -d= -f2)
        yq -oj -i ".git.config[\"$key\"] = \"$val\"" $pm_file
    end
end

function _declair_gitconfig_pull
    set --function pm_file $__fish_config_dir/declair.json

    for conf in (git config --global --list | cut -d= -f1)
        git config --global --unset-all $conf
    end

    for conf in (yq -oy '.git.config | keys | .[]' $pm_file)
        set -l val (yq -oy ".git.config[\"$conf\"]" $pm_file)
        git config --global "$conf" "$val"
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

function _declair_pm_install
    argparse --stop-nonopt -- $argv
    if type rpm >/dev/null
        _declair_pm_rpm_install
    end
end

function _declair_pm_remove
    argparse --stop-nonopt -- $argv
    if type rpm >/dev/null
        _declair_pm_rpm_remove
    end
end

function _declair_pm_update
    argparse --stop-nonopt -- $argv
    if type rpm >/dev/null
        _declair_pm_rpm_update
    end
end

function _declair_pm_upgrade
    argparse --stop-nonopt -- $argv
    if type rpm >/dev/null
        _declair_pm_rpm_upgrade
    end
end

function _declair_pm_rpm_update
    set -f pkg_installeds (rpm --query --all)
    set -f pkg_desireds (_declair_pm_list)
    for desired in $pkg_desireds
        set -l is_installed false
        if string match --quiet --entire " $desired-" " $pkg_installeds"
            set is_installed true
        end
        if [ $is_installed = false ]
            sudo dnf install -y $desired
            _declair_pm_add_json $pkg_name $pkg_version
        end
    end

    function _declair_pm_rpm_install
        argparse --stop-nonopt -- $argv
        set -f pkg_name $argv[1]

        if rpm --query $pkg_name >/dev/null
            echo $pkg_name seems to be already installed.

            set -f pkg_version (rpm --query $pkg_name --queryformat "%{VERSION}")
            _declair_pm_add_json $pkg_name $pkg_version
            # _declair_pm_add_json --lock $pkg_name $pkg_version
        else
            sudo dnf install -y $argv[1..]
        end
    end

    function _declair_pm_rpm_remove
        argparse --stop-nonopt -- $argv
        sudo dnf remove $argv[1]
    end

    function _declair_pm_rpm_upgrade
        argparse --stop-nonopt -- $argv
        sudo dnf upgrade $argv[1]
    end
end

function _declair_pm_add_json
    argparse --stop-nonopt l/lock -- $argv
    if set -q _flag_lock
        set --function pm_file $__fish_config_dir/declair.lock
    else
        set --function pm_file $__fish_config_dir/declair.json
    end

    if [ ! -e $pm_file ]
        echo '{}' >$pm_file
    end

    if ! yq -e .version $pm_file 1>/dev/null 2>/dev/null
        yq -i '.version = 1' $pm_file 1>/dev/null 2>/dev/null
    end

    yq -i ".rpm[\"$argv[1]\"] = \"$argv[2]\"" $pm_file 1>/dev/null 2>/dev/null
end

function _declair_pm_list
    yq -oy '.rpm | keys | .[]' ~/.config/fish/declair.json
end
function _declair_sym
    argparse --stop-nonopt -- $argv

    if functions --query _declair_sym_$argv[1]
        _declair_sym_$argv[1] $argv[2..]
    else
        _declair_sym_help
    end
end


function _declair_sym_help
    echo "\
Usage: declair sym subcommand

Subcommands:
  update
"
end

function _declair_sym_update
    set -f declair_file $__fish_config_dir/declair.json

    for src in (yq -oy '.sym | keys| .[]' $declair_file)
        set -l dist (yq -oy ".sym[\"$src\"]" $declair_file)
        set -l src (__declair_resolve_path "$src")
        set -l dist (__declair_resolve_path "$dist")

        if test ! -f "$dist"; or test ! -s "$dist"
            echo "-  $src"
            echo "-> $dist"
            mkdir -p (dirname $dist)
            ln -s $src $dist -f
        end
    end
end

function __declair_resolve_path
    argparse --stop-nonopt -- $argv
    set -l path $argv[1]
    set -l path (echo $path | sed "s?~?$HOME?")
    if test -e "$path"
        set -l path (realpath "$path")
    end
    echo $path
end
