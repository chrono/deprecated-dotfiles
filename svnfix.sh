#!/bin/sh
# This script creates the symlinks in the home dir, pointing to the actual versioned files

DIR=dotfiles.git
#DIR=dotfiles
cd
ln -s $DIR/.vimrc
ln -s $DIR/.vim
ln -s $DIR/.zshrc
ln -s $DIR/.zsh
ln -s $DIR/.screenrc
ln -s $DIR/.irssi
ln -s $DIR/.mutt
ln -s $DIR/.muttrc
ln -s $DIR/.signature
ln -s $DIR/.Xresources
