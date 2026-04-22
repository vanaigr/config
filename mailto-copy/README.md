
ln -s $HOME/gh/config/mailto-copy/mailto-handler.desktop $HOME/.local/share/applications/mailto-copy.desktop
xdg-mime default mailto-handler.desktop x-scheme-handler/mailto

test:

xdg-mime query default x-scheme-handler/mailto
