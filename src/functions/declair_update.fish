function _declair_update_rc
    set -f last_updated $_declair_last_updated
    if test -n $last_updated
        and test (math $last_updated + '60*60*12') -lt (date +%s)

        read -lP 'The last updated date is too old. Check the updates? (s to skip)' do_update
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
