 #!/bin/bash

 pane_width=$(tmux display-message -p "#{pane_width}")
 window_width=$(tmux display-message -p "#{window_width}")

 if [ "$pane_width" -lt "$window_width" ]; then
     # Currently side-by-side → go stacked
     tmux move-pane -v -t '{last}'
 else
     # Currently stacked → go side-by-side
     tmux move-pane -h -t '{last}'
 fi
