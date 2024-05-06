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

    if test ! -f $dist || test ! -s $dist
      echo mkdir -p (dirname $dist)
      echo ln -s $src $dist
    end
  end
end
