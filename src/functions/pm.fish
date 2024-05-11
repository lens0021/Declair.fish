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

function _declair_pm_update
    argparse --stop-nonopt -- $argv
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
end

function _declair_pm_install
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

function _declair_pm_remove
    argparse --stop-nonopt -- $argv
    sudo dnf remove $argv[1]
end

function _declair_pm_upgrade
    argparse --stop-nonopt -- $argv
    sudo dnf upgrade $argv[1]
end
