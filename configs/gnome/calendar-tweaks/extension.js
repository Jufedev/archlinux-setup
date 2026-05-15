import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        this._messageList = dateMenu._messageList;
        this._box = this._messageList.get_parent();
        if (!this._box) return;

        const children = this._box.get_children();
        const msgIdx = children.indexOf(this._messageList);
        this._separator = msgIdx > 0 ? children[msgIdx - 1] : null;
        if (this._separator?.get_n_children?.() > 0)
            this._separator = null;

        if (this._separator)
            this._box.remove_child(this._separator);
        this._box.remove_child(this._messageList);

        this._styledActors = [];
        let actor = this._box;
        while (actor) {
            if (actor.add_style_class_name) {
                actor.add_style_class_name('ct-compact');
                this._styledActors.push(actor);
            }
            if (actor.has_style_class_name?.('popup-menu-boxpointer'))
                break;
            actor = actor.get_parent();
        }
    }

    disable() {
        for (const a of this._styledActors || [])
            a.remove_style_class_name('ct-compact');
        if (this._box) {
            if (this._separator)
                this._box.add_child(this._separator);
            if (this._messageList)
                this._box.add_child(this._messageList);
        }
        this._messageList = null;
        this._separator = null;
        this._box = null;
        this._styledActors = null;
    }
}
