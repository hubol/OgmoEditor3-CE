package features;

import js.lib.Promise;
import js.lib.Set;

interface IGroupable {
    public var groupName:String;
}

interface IGroupablesProvider<T:IGroupable> {
    public function getGroupables():Array<T>;
}

class DecalGroups {
    public static function groupOrUngroup<T:IGroupable>(groupables: Array<T>, destination: Array<T>) {
        final groupNameAnalysis = analyzeGroupNames(groupables);
        final groupNameToApply = _getGroupNameToApply(groupNameAnalysis, destination);

        final action = groupNameToApply == null ? "Clear group" : 'Set group to "${groupNameToApply}"';
        final description = '${action} for ${groupables.length} groupable(s)';
        trace(description);
        EDITOR.level.store(description);

        for (groupable in groupables) {
            groupable.groupName = groupNameToApply;
        }

        ensureConsecutiveGroups(destination);

        EDITOR.dirty();
    }

    public static function renameGroup<T:IGroupable>(groupables: Array<T>, previousGroupName: String, nextGroupName: String) {
        final description = 'Changed group name from ${previousGroupName} to ${nextGroupName}';
        trace(description);
        EDITOR.level.store(description);

        for (groupable in groupables) {
            if (groupable.groupName == previousGroupName) {
                groupable.groupName = nextGroupName;
            }
        }

        EDITOR.dirty();
    }

    static function _getGroupNameToApply<T:IGroupable>(analysis: GroupNameAnalysis, groupables: Array<T>) {
        if (analysis.uniqueGroupNamesCount == 0) {
            final groupNames = new Set([ for (groupable in groupables) if (groupable.groupName != null) groupable.groupName ]);

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

    public static function ensureConsecutiveGroups<T:IGroupable>(groupables: Array<T>) {
        final groupNamesToChunks = new Map<String,Array<T>>();
        final groupableChunks = new Array<Array<T>>();

        groupableChunks[0] = new Array();

        for (groupable in groupables) {
            if (groupable.groupName == null) {
                groupableChunks[groupableChunks.length - 1].push(groupable);
                continue;
            }

            var chunk = groupNamesToChunks.get(groupable.groupName);

            if (chunk == null) {
                chunk = new Array();
                groupNamesToChunks.set(groupable.groupName, chunk);
                groupableChunks.push(chunk);
                groupableChunks.push(new Array());
            }

            chunk.push(groupable);
        }

        groupables.resize(0);

        for (chunk in groupableChunks) {
            for (groupable in chunk) {
                groupables.push(groupable);
            }
        }
    }

    public static function analyzeGroupNames<T:IGroupable>(groupables: Array<T>): GroupNameAnalysis {
        final groupNameCounts = new Map<String,Int>();
        var topmostGroupName = null;
        var topmostGroupable = null;
        var nullGroupNamesCount = 0;

        var i = groupables.length - 1;
        while (i >= 0) {
            final groupable = groupables[i];
            i -= 1;

            if (topmostGroupable == null) {
                topmostGroupable = groupable;
            }

            if (groupable.groupName == null) {
                nullGroupNamesCount += 1;
                continue;
            } 

            if (topmostGroupName == null) {
                topmostGroupName = groupable.groupName;
            }
            
            final count = groupNameCounts.get(groupable.groupName);
            groupNameCounts.set(groupable.groupName, count == null ? 1 : count + 1);
        }

        return {
            topmostGroupable: topmostGroupable,
            topmostGroupName: topmostGroupName,
            nullGroupNamesCount: nullGroupNamesCount,
            uniqueGroupNamesCount: [for (key in groupNameCounts.keys()) key].length,
            groupNameCounts: groupNameCounts,
        }
    }
}

typedef GroupNameAnalysis = {
    final topmostGroupable:IGroupable;
    final topmostGroupName:String;
    final uniqueGroupNamesCount:Int;
    final nullGroupNamesCount:Int;
    final groupNameCounts:Map<String,Int>;
}

class UiGroupsList extends LayerEditorMainPanelElement {
    private final _rootEl = new JQuery('<div class="decal_groups_list"></div>');
    private final _titleEl = new JQuery('<div></div>');
    private final _listEl = new JQuery('<ul></ul>');

    private var _state: UiGroupsListState = { groups: [] };

    private final _onMouseEnter: (groupName:String) -> Void;
    private final _onMouseLeave: (groupName:String) -> Void;
    private final _onClick: (groupName:String) -> Void;
    private final _onRightClick: (groupName:String) -> Promise<Void>;

    public function new(
            onMouseEnter: (groupName:String) -> Void,
            onMouseLeave: (groupName:String) -> Void,
            onClick: (groupName:String) -> Void,
            onRightClick: (groupName:String) -> Promise<Void>) {
        super("<div />");
        this._el.append(this._rootEl);
        this._rootEl.append(this._titleEl, this._listEl);
        this._onMouseEnter = onMouseEnter;
        this._onMouseLeave = onMouseLeave;
        this._onClick = onClick;
        this._onRightClick = onRightClick;
    }

    public function update<T:IGroupable>(groupablesProvider: IGroupablesProvider<T>, selectedGroupables: Array<T>) {
        final nextState = _getState(groupablesProvider, selectedGroupables);

        if (_areStatesEqual(this._state, nextState)) {
            return;
        }

        this._state = nextState;

        this._rootEl.css("display", this._state.groups.length == 0 ? "none" : "");

        this._titleEl.text(this._state.groups.length == 1 ? '1 Group' : '${this._state.groups.length} Groups');
        this._listEl.empty();

        for (group in this._state.groups) {
            final itemEl = new JQuery('<li>${group.name}<count>(${group.count == 1 ? '1 object' : '${group.count} objects'})</count></li>');

            if (group.isTopmostSelected) {
                itemEl.attr('data-topmost_selected', 'true');
            }

            if (group.membersSelectedCount > 0) {
                itemEl.attr('data-selected', 'true');

                if (group.membersSelectedCount == group.count) {
                    itemEl.attr('data-all_members_selected', 'true');
                }
            }
            
            itemEl.on('mouseenter', () -> this._onMouseEnter(group.name));
            itemEl.on('mouseleave', () -> this._onMouseLeave(group.name));
            itemEl.on('click', () -> this._onClick(group.name));
            itemEl.on('contextmenu', () -> this._onRightClick(group.name));

            this._listEl.append(itemEl);
        }
    }

    private static function _areStatesEqual(state0: UiGroupsListState, state1: UiGroupsListState) {
        if (state0.groups.length != state1.groups.length) {
            return false;
        }

        for (i in 0...state0.groups.length) {
            final group0 = state0.groups[i];
            final group1 = state1.groups[i];

            if (group0.count != group1.count
                || group0.name != group1.name
                || group0.isTopmostSelected != group1.isTopmostSelected
                || group0.membersSelectedCount != group1.membersSelectedCount) {
                return false;
            }
        }

        return true;
    }

    private static function _getState<T:IGroupable>(groupablesProvider: IGroupablesProvider<T>, selectedGroupables: Array<T>): UiGroupsListState {
        final analysis = DecalGroups.analyzeGroupNames(selectedGroupables);

        final groups = new Map<String, Int>();
        for (groupable in groupablesProvider.getGroupables()) {
            if (groupable.groupName == null) {
                continue;
            }

            final value = groups.get(groupable.groupName);
            groups.set(groupable.groupName, value == null ? 1 : (value + 1));
        }

        final groupsArray = new Array<UiGroupsListStateGroups>();

        for (groupName in groups.keys()) {
            final name = groupName;
            final count = groups.get(groupName);
            final isTopmostSelected = analysis.topmostGroupName == groupName;
            final membersSelectedCount = analysis.groupNameCounts.get(groupName);
            groupsArray.push({ name: name, count: count, isTopmostSelected: isTopmostSelected, membersSelectedCount: membersSelectedCount == null ? 0 : membersSelectedCount });
        }

        return {
            groups: groupsArray,
        }
    }
}

typedef UiGroupsListStateGroups = {
    final name:String;
    final count:Int;
    final isTopmostSelected:Bool;
    final membersSelectedCount:Int;
}

typedef UiGroupsListState = {
    final groups:Array<UiGroupsListStateGroups>;
}