import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        const dateMenu = Main.panel.statusArea.dateMenu;
        this._messageList = dateMenu._messageList;
        this._box = this._messageList.get_parent();
        if (!this._box) return;

        this._separator = null;
        for (const child of this._box.get_children()) {
            if (child !== this._messageList &&
                child.has_style_class_name?.('calendar-vertical-separator')) {
                this._separator = child;
                break;
            }
        }

        if (this._separator)
            this._box.remove_child(this._separator);
        this._box.remove_child(this._messageList);
    }

    disable() {
        if (this._box) {
            if (this._separator)
                this._box.add_child(this._separator);
            if (this._messageList)
                this._box.add_child(this._messageList);
        }
        this._messageList = null;
        this._separator = null;
        this._box = null;
    }
}
