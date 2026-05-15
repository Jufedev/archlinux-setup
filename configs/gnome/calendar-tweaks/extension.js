import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        this._messageList = dateMenu._messageList;
        this._box = this._messageList.get_parent();
        if (!this._box) return;

        this._box.remove_child(this._messageList);

        this._bin = this._box.get_parent();
        if (this._bin?.layout_manager?.frozen !== undefined)
            this._bin.layout_manager.frozen = false;

        this._forceRelayout();

        this._openId = dateMenu.menu.connect('open-state-changed', (_menu, isOpen) => {
            if (!isOpen) return;
            if (this._bin?.layout_manager?.frozen !== undefined)
                this._bin.layout_manager.frozen = false;
            this._forceRelayout();
        });
        this._dateMenu = dateMenu;
    }

    _forceRelayout() {
        let actor = this._box;
        while (actor) {
            if (actor.queue_relayout)
                actor.queue_relayout();
            actor = actor.get_parent();
        }
    }

    disable() {
        if (this._openId) {
            this._dateMenu.menu.disconnect(this._openId);
            this._openId = null;
        }
        if (this._box && this._messageList)
            this._box.insert_child_at_index(this._messageList, 0);
        this._messageList = null;
        this._box = null;
        this._bin = null;
        this._dateMenu = null;
    }
}
