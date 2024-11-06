package features;

import modules.decals.DecalLayer;
import js.lib.Set;
import modules.decals.Decal;

class DecalGroups {
    public static function groupOrUngroupDecals(decals: Array<Decal>, destination: Array<Decal>) {
        final groupNameAnalysis = _analyzeDecalGroupNames(decals);
        final groupNameToApply = _getGroupNameToApply(groupNameAnalysis, destination);

        final action = groupNameToApply == null ? "Clear group" : 'Set group to "${groupNameToApply}"';
        final description = '${action} for ${decals.length} decal(s)';
        trace(description);
        EDITOR.level.store(description);

        for (decal in decals) {
            decal.groupName = groupNameToApply;
        }

        ensureConsecutiveGroups(destination);

        EDITOR.dirty();
    }

    static function _getGroupNameToApply(analysis: DecalGroupNameAnalysis, decals: Array<Decal>) {
        if (analysis.uniqueGroupNamesCount == 0) {
            final groupNames = new Set([ for (decal in decals) if (decal.groupName != null) decal.groupName ]);

            final baseName = 'Group';
            var count = 0;
            var name = baseName;

            while (true) {
                count += 1;
                name = baseName + ' ' + count;

                if (!groupNames.has(name)) {
                    return name;
                }
            }
        }

        final shouldApplyTopmostGroupName = analysis.uniqueGroupNamesCount > 1 || analysis.nullGroupNamesCount > 0;

        return shouldApplyTopmostGroupName ? analysis.topmostGroupName : null;
    }

    public static function ensureConsecutiveGroups(decals: Array<Decal>) {
        final groupNamesToChunks = new Map<String,Array<Decal>>();
        final decalChunks = new Array<Array<Decal>>();

        decalChunks[0] = new Array();

        for (decal in decals) {
            if (decal.groupName == null) {
                decalChunks[decalChunks.length - 1].push(decal);
                continue;
            }

            var chunk = groupNamesToChunks.get(decal.groupName);

            if (chunk == null) {
                chunk = new Array();
                groupNamesToChunks.set(decal.groupName, chunk);
                decalChunks.push(chunk);
                decalChunks.push(new Array());
            }

            chunk.push(decal);
        }

        decals.resize(0);

        for (chunk in decalChunks) {
            for (decal in chunk) {
                decals.push(decal);
            }
        }
    }

    static function _analyzeDecalGroupNames(decals: Array<Decal>): DecalGroupNameAnalysis {
        final groupNames = new Set<String>();
        var topmostGroupName = null;
        var topmostDecal = null;
        var nullGroupNamesCount = 0;

        var i = decals.length - 1;
        while (i >= 0) {
            final decal = decals[i];
            i -= 1;

            if (topmostDecal == null) {
                topmostDecal = decal;
            }

            if (decal.groupName == null) {
                nullGroupNamesCount += 1;
                continue;
            } 

            if (topmostGroupName == null) {
                topmostGroupName = decal.groupName;
            }
            
            groupNames.add(decal.groupName);
        }

        return {
            topmostDecal: topmostDecal,
            topmostGroupName: topmostGroupName,
            nullGroupNamesCount: nullGroupNamesCount,
            uniqueGroupNamesCount: groupNames.size,
        }
    }
}

typedef DecalGroupNameAnalysis = {
    final topmostDecal:Decal;
    final topmostGroupName:String;
    final uniqueGroupNamesCount:Int;
    final nullGroupNamesCount:Int;
}

class UiDecalGroupsList extends LayerEditorMainPanelElement {
    private final _rootEl = new JQuery('<div class="decal_groups_list"></div>');
    private final _titleEl = new JQuery('<div></div>');
    private final _listEl = new JQuery('<ul></ul>');

    private var _state: UiDecalGroupsListState = { groups: [] };

    private final _onMouseEnter: (groupName:String) -> Void;
    private final _onMouseLeave: (groupName:String) -> Void;
    private final _onClick: (groupName:String) -> Void;

    public function new(
            onMouseEnter: (groupName:String) -> Void,
            onMouseLeave: (groupName:String) -> Void,
            onClick: (groupName:String) -> Void) {
        super("<div />");
        this._el.append(this._rootEl);
        this._rootEl.append(this._titleEl, this._listEl);
        this._onMouseEnter = onMouseEnter;
        this._onMouseLeave = onMouseLeave;
        this._onClick = onClick;
    }

    public function update(decalLayer: DecalLayer) {
        final nextState = _getState(decalLayer);

        if (_areStatesEqual(this._state, nextState)) {
            return;
        }

        this._state = nextState;

        this._rootEl.css("display", this._state.groups.length == 0 ? "none" : "");

        this._titleEl.text(this._state.groups.length == 1 ? '1 Group' : '${this._state.groups.length} Groups');
        this._listEl.empty();

        for (group in this._state.groups) {
            final itemEl = new JQuery('<li>${group.name}<count>(${group.count == 1 ? '1 decal' : '${group.count} decals'})</count></li>');
            itemEl.on('mouseenter', () -> this._onMouseEnter(group.name));
            itemEl.on('mouseleave', () -> this._onMouseLeave(group.name));
            itemEl.on('click', () -> this._onClick(group.name));

            this._listEl.append(itemEl);
        }
    }

    private static function _areStatesEqual(state0: UiDecalGroupsListState, state1: UiDecalGroupsListState) {
        if (state0.groups.length != state1.groups.length) {
            return false;
        }

        for (i in 0...state0.groups.length) {
            final group0 = state0.groups[i];
            final group1 = state1.groups[i];

            if (group0.count != group1.count || group0.name != group1.name) {
                return false;
            }
        }

        return true;
    }

    private static function _getState(layer: DecalLayer): UiDecalGroupsListState {
        final groups = new Map<String, Int>();
        for (decal in layer.decals) {
            if (decal.groupName == null) {
                continue;
            }

            final value = groups.get(decal.groupName);
            groups.set(decal.groupName, value == null ? 1 : (value + 1));
        }

        final groupsArray = new Array<{ name:String, count:Int }>();

        for (key in groups.keys()) {
            groupsArray.push({ name: key, count: groups.get(key) });
        }

        return {
            groups: groupsArray,
        }
    }
}

typedef UiDecalGroupsListState = {
    final groups:Array<{ name:String, count:Int }>;
}