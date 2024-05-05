
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
