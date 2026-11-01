"""A GTK window at (1500, 50), 300x300, that drags a file's URI (XDND, text/uri-list): dragsource.py <file>. Prints READY when shown."""
import sys, gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
from pathlib import Path
uri = Path(sys.argv[1]).resolve().as_uri()
w = Gtk.Window(title='dragsource')
w.set_default_size(300, 300)
w.move(1500, 50)
box = Gtk.EventBox()
box.add(Gtk.Label(label='drag me'))
w.add(box)
box.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, [Gtk.TargetEntry.new('text/uri-list', 0, 0)], Gdk.DragAction.COPY)
def get(widget, ctx, data, info, time):
    data.set_uris([uri])
box.connect('drag-data-get', get)
box.connect('drag-end', lambda *a: (print('DRAGEND', flush=True), GLib.timeout_add(300, Gtk.main_quit)))
w.connect('destroy', Gtk.main_quit)
w.show_all()
GLib.timeout_add(500, lambda: print('READY', flush=True) and False)
GLib.timeout_add(20000, Gtk.main_quit)
Gtk.main()
