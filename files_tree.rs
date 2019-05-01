use std::collections::HashMap;

use std::{rc::Rc, cell::RefCell};
use gtk::{self, prelude::*};
use gdk::enums::key;

// https://github.com/daa84/neovim-gtk/blob/master/src/file_browser.rs
// https://github.com/jonathanBieler/GtkIDE.jl/blob/master/src/sidepanels/FilesPanel.jl
// https://gitlab.gnome.org/GNOME/shotwell/blob/master/src/sidebar/Tree.vala
// https://github.com/teejee2008/polo/blob/master/src/Gtk/FileViewList.vala

pub struct FilesTree {}
