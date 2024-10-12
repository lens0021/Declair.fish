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

        echo "src: $src"
        echo "dist: $dist"
        if test ! -f $dist || test ! -s $dist
            mkdir -p (dirname $dist)
            ln -s $src $dist
        end
    end
end

function __declair_resolve_path
    argparse --stop-nonopt -- $argv
    set -f path $argv[1]
    set -f path (echo $path | sed "s?~?$HOME?")
    if test -e "$path"
        set -f path (realpath "$path")
    end
    echo $path
end
