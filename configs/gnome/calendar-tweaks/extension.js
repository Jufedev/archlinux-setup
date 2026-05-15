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

        this._origBoxStyle = this._box.get_style();
        this._box.set_style('min-width: 0;');

        this._menuBox = dateMenu.menu.box;
        this._origMenuBoxStyle = this._menuBox.get_style();
        this._menuBox.set_style('min-width: 0;');
    }

    disable() {
        if (this._box) {
            this._box.set_style(this._origBoxStyle || '');
            if (this._separator)
                this._box.add_child(this._separator);
            if (this._messageList)
                this._box.add_child(this._messageList);
        }
        if (this._menuBox)
            this._menuBox.set_style(this._origMenuBoxStyle || '');
        this._messageList = null;
        this._separator = null;
        this._box = null;
        this._menuBox = null;
    }
}
