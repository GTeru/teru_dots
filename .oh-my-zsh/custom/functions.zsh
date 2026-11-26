# cd, then list the new directory. Only lists when attached to a terminal:
# eza waits on stdin when it isn't one, which hangs `cd` in scripts and tool shells.
cd_and_ls() { builtin cd "$@" || return; [[ -t 0 && -t 1 ]] && ls; return 0 }
