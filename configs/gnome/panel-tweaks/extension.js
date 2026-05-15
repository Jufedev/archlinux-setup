import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

export default class PanelTweaks extends Extension {
    enable() {
        this._qs = Main.panel.statusArea.quickSettings;
        this._dateMenu = Main.panel.statusArea.dateMenu;

        this._qsOrigParent = this._qs.container.get_parent();
        this._qsOrigIndex = this._childIndex(this._qs.container);
        this._dateOrigParent = this._dateMenu.container.get_parent();
        this._dateOrigIndex = this._childIndex(this._dateMenu.container);

        this._addArchIcon();
        this._hideSystemIndicator();

        this._qsOrigParent.remove_child(this._qs.container);
        Main.panel._leftBox.insert_child_at_index(this._qs.container, 0);

        this._dateOrigParent.remove_child(this._dateMenu.container);
        Main.panel._rightBox.add_child(this._dateMenu.container);
    }

    disable() {
        if (this._archIcon) {
            this._archIcon.get_parent()?.remove_child(this._archIcon);
            this._archIcon.destroy();
            this._archIcon = null;
        }

        if (this._qs._system)
            this._qs._system.visible = true;

        this._dateMenu.container.get_parent()?.remove_child(this._dateMenu.container);
        this._dateOrigParent.insert_child_at_index(
            this._dateMenu.container,
            Math.min(this._dateOrigIndex, this._dateOrigParent.get_n_children())
        );

        this._qs.container.get_parent()?.remove_child(this._qs.container);
        this._qsOrigParent.insert_child_at_index(
            this._qs.container,
            Math.min(this._qsOrigIndex, this._qsOrigParent.get_n_children())
        );

        this._qs = null;
        this._dateMenu = null;
    }

    _addArchIcon() {
        this._archIcon = new St.Icon({
            style_class: 'system-status-icon',
            gicon: Gio.icon_new_for_string(
                GLib.build_filenamev([this.path, 'icons', 'arch-symbolic.svg'])
            ),
        });
        this._qs._indicators.insert_child_at_index(this._archIcon, 0);
    }

    _hideSystemIndicator() {
        if (this._qs._system)
            this._qs._system.visible = false;
    }

    _childIndex(actor) {
        const parent = actor.get_parent();
        return parent ? parent.get_children().indexOf(actor) : 0;
    }
}
