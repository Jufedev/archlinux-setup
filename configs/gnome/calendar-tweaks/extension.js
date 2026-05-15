import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import GLib from 'gi://GLib';

export default class CalendarTweaks extends Extension {
    enable() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        this._messageList = dateMenu._messageList;
        this._box = this._messageList.get_parent();
        if (!this._box) return;

        this._msgIndex = this._box.get_children().indexOf(this._messageList);
        this._origXExpand = this._messageList.x_expand;
        this._messageList.x_expand = false;
        this._box.remove_child(this._messageList);

        const bin = this._box.get_parent();
        if (bin?.layout_manager?.frozen !== undefined)
            bin.layout_manager.frozen = false;

        this._openId = dateMenu.menu.connect('open-state-changed', (_menu, isOpen) => {
            if (!isOpen) return;
            if (bin?.layout_manager?.frozen !== undefined)
                bin.layout_manager.frozen = false;
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
                this._centerPopup();
                return GLib.SOURCE_REMOVE;
            });
        });
        this._dateMenu = dateMenu;
    }

    _centerPopup() {
        const bp = this._dateMenu.menu._boxPointer;
        if (!bp) return;
        const clock = this._dateMenu._clockDisplay;
        const [cx] = clock.get_transformed_position();
        const center = cx + clock.width / 2;
        const mon = Main.layoutManager.primaryMonitor;
        const x = Math.max(mon.x,
            Math.min(Math.round(center - bp.width / 2),
                     mon.x + mon.width - bp.width));
        bp.set_position(x, bp.y);
    }

    disable() {
        if (this._openId) {
            this._dateMenu.menu.disconnect(this._openId);
            this._openId = null;
        }
        if (this._box && this._messageList) {
            this._messageList.x_expand = this._origXExpand;
            const idx = Math.min(this._msgIndex, this._box.get_n_children());
            this._box.insert_child_at_index(this._messageList, idx);
        }
        this._messageList = null;
        this._box = null;
        this._dateMenu = null;
    }
}
