import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        this._messageList = Main.panel.statusArea.dateMenu._messageList;
        this._parent = this._messageList.get_parent();
        if (this._parent)
            this._parent.remove_child(this._messageList);
    }

    disable() {
        if (this._messageList && this._parent)
            this._parent.insert_child_at_index(this._messageList, 0);
        this._messageList = null;
        this._parent = null;
    }
}
