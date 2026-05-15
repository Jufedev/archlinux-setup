import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        const ml = Main.panel.statusArea.dateMenu._messageList;
        this._ml = ml;
        this._origExpand = ml.x_expand;
        ml.x_expand = false;
    }

    disable() {
        if (this._ml)
            this._ml.x_expand = this._origExpand ?? true;
        this._ml = null;
    }
}
