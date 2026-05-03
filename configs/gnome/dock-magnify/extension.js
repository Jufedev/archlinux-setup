import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Graphene from 'gi://Graphene';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const MAX_SCALE = 1.5;
const SPREAD = 3;
const ANIM_MS = 150;

export default class DockMagnifyExtension extends Extension {
    enable() {
        this._itemSignals = [];
        this._boxSignals = [];
        this._origClip = [];
        this._dashBox = null;

        this._setupId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
            this._setupId = null;
            this._setup();
            return GLib.SOURCE_REMOVE;
        });
    }

    disable() {
        if (this._setupId) {
            GLib.source_remove(this._setupId);
            this._setupId = null;
        }
        this._cleanup();
    }

    _findDashBox() {
        const search = (actor, depth) => {
            if (depth > 20) return null;
            const children = actor.get_children();
            const items = children.filter(c =>
                (c.get_style_class_name?.() ?? '').includes('dash-item-container')
            );
            if (items.length >= 2) return actor;
            for (const child of children) {
                const found = search(child, depth + 1);
                if (found) return found;
            }
            return null;
        };
        return search(Main.uiGroup, 0);
    }

    _getItems() {
        if (!this._dashBox) return [];
        return this._dashBox.get_children().filter(c =>
            (c.get_style_class_name?.() ?? '').includes('dash-item-container')
        );
    }

    _setup() {
        this._dashBox = this._findDashBox();
        if (!this._dashBox) return;

        let parent = this._dashBox;
        for (let i = 0; i < 6 && parent; i++) {
            if (parent.clip_to_allocation) {
                this._origClip.push({actor: parent, value: true});
                parent.set_clip_to_allocation(false);
            }
            parent = parent.get_parent();
        }

        const addId = this._dashBox.connect('actor-added', () => {
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
                this._rehookItems();
                return GLib.SOURCE_REMOVE;
            });
        });
        const rmId = this._dashBox.connect('actor-removed', () => {
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
                this._rehookItems();
                return GLib.SOURCE_REMOVE;
            });
        });
        this._boxSignals = [{actor: this._dashBox, ids: [addId, rmId]}];

        this._hookItems();
    }

    _hookItems() {
        const items = this._getItems();
        const pivot = new Graphene.Point({x: 0.5, y: 1.0});

        for (const item of items) {
            item.pivot_point = pivot;

            const enterId = item.connect('enter-event', () => {
                const current = this._getItems();
                const idx = current.indexOf(item);
                if (idx >= 0) this._magnify(idx, current);
                return Clutter.EVENT_PROPAGATE;
            });

            const leaveId = item.connect('leave-event', () => {
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                    const anyHovered = this._getItems().some(it => it.hover);
                    if (!anyHovered) this._resetAll();
                    return GLib.SOURCE_REMOVE;
                });
                return Clutter.EVENT_PROPAGATE;
            });

            this._itemSignals.push({actor: item, ids: [enterId, leaveId]});
        }
    }

    _magnify(hoveredIdx, items) {
        if (!items?.length) return;
        const h = hoveredIdx;

        const scales = items.map((_, i) => {
            const d = Math.abs(i - h);
            if (d === 0) return MAX_SCALE;
            if (d <= SPREAD) {
                const t = d / SPREAD;
                return 1.0 + (MAX_SCALE - 1.0) * (1 - t) * (1 - t);
            }
            return 1.0;
        });

        items.forEach((item, i) => {
            let tx = 0;

            if (i > h) {
                tx = items[h].width * (scales[h] / 2 - 0.5);
                for (let j = h + 1; j < i; j++)
                    tx += items[j].width * (scales[j] - 1);
                tx += item.width * (scales[i] / 2 - 0.5);
            } else if (i < h) {
                tx = -(items[h].width * (scales[h] / 2 - 0.5));
                for (let j = i + 1; j < h; j++)
                    tx -= items[j].width * (scales[j] - 1);
                tx -= item.width * (scales[i] / 2 - 0.5);
            }

            item.ease({
                scale_x: scales[i],
                scale_y: scales[i],
                translation_x: tx,
                duration: ANIM_MS,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            });
        });
    }

    _resetAll() {
        for (const item of this._getItems()) {
            item.ease({
                scale_x: 1.0,
                scale_y: 1.0,
                translation_x: 0,
                duration: ANIM_MS * 2,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            });
        }
    }

    _rehookItems() {
        for (const sig of this._itemSignals) {
            for (const id of sig.ids) {
                try { sig.actor.disconnect(id); } catch {}
            }
        }
        this._itemSignals = [];
        this._hookItems();
    }

    _cleanup() {
        this._resetAll();

        for (const sig of this._itemSignals) {
            for (const id of sig.ids) {
                try { sig.actor.disconnect(id); } catch {}
            }
        }
        this._itemSignals = [];

        for (const sig of this._boxSignals) {
            for (const id of sig.ids) {
                try { sig.actor.disconnect(id); } catch {}
            }
        }
        this._boxSignals = [];

        for (const {actor, value} of this._origClip) {
            try { actor.set_clip_to_allocation(value); } catch {}
        }
        this._origClip = [];

        this._dashBox = null;
    }
}
