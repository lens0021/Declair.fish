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
