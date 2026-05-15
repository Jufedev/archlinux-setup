import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class CalendarTweaks extends Extension {
    enable() {
        this._messageList = Main.panel.statusArea.dateMenu._messageList;
        this._messageList.hide();
    }

    disable() {
        this._messageList?.show();
        this._messageList = null;
    }
}
