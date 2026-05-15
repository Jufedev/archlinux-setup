import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

export default class PanelTweaks extends Extension {
    enable() {
        this._qs = Main.panel.statusArea.quickSettings;
        this._moved = [];

        this._moveToBox(this._qs, Main.panel._leftBox, 0);
        this._addArchIcon();
        this._hideSystemIndicator();

        this._setupId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
            this._setupId = null;
            this._reorderIndicators();
            this._arrangeCenter();
            this._moveDateToRight();
            return GLib.SOURCE_REMOVE;
        });
    }

    disable() {
        if (this._setupId) {
            GLib.source_remove(this._setupId);
            this._setupId = null;
        }

        if (this._archIcon) {
            this._archIcon.get_parent()?.remove_child(this._archIcon);
            this._archIcon.destroy();
            this._archIcon = null;
        }

        if (this._qs?._system)
            this._qs._system.visible = true;

        for (const {container, origParent, origIndex} of [...this._moved].reverse()) {
            container.get_parent()?.remove_child(container);
            origParent.insert_child_at_index(
                container,
                Math.min(origIndex, origParent.get_n_children())
            );
        }

        this._moved = [];
        this._qs = null;
    }

    _moveToBox(indicator, box, index = -1) {
        const container = indicator.container;
        const origParent = container.get_parent();
        if (!origParent) return;

        const origIndex = origParent.get_children().indexOf(container);
        this._moved.push({container, origParent, origIndex});

        origParent.remove_child(container);
        if (index >= 0)
            box.insert_child_at_index(container, index);
        else
            box.add_child(container);
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

    _reorderIndicators() {
        const ind = this._qs._indicators;

        if (this._qs._volumeOutput && ind.contains(this._qs._volumeOutput)) {
            ind.remove_child(this._qs._volumeOutput);
            ind.insert_child_at_index(this._qs._volumeOutput, 1);
        }

        if (this._qs._network && ind.contains(this._qs._network)) {
            ind.remove_child(this._qs._network);
            ind.insert_child_at_index(this._qs._network, 2);
        }
    }

    _arrangeCenter() {
        const center = Main.panel._centerBox;

        const clipboard = this._findIndicator('clipboard');
        if (clipboard)
            this._moveToBox(clipboard, center, 0);

        const vitals = this._findIndicator('vitals');
        if (vitals)
            this._moveToBox(vitals, center);
    }

    _moveDateToRight() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        if (dateMenu)
            this._moveToBox(dateMenu, Main.panel._rightBox);
    }

    _findIndicator(pattern) {
        const lc = pattern.toLowerCase();
        for (const [key, val] of Object.entries(Main.panel.statusArea)) {
            if (key.toLowerCase().includes(lc))
                return val;
        }
        return null;
    }
}
