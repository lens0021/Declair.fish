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
    update\
"
end

function _declair_update_rc
    set -l last_updated $_declair_last_updated
    if test -n $last_updated
        and test (math $last_updated + '60*60*8') -lt (date +%s)

        read -lP 'The last updated date is too old. Check the updates? ' do_update
        switch $do_update
            case Y y yes
                _declair_update
                set -Ux _declair_last_updated (date +%s)
        end
    end
end

function _declair_update
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
