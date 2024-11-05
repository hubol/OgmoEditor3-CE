package features;

import js.node.Path;
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

            final baseName = Path.parse(analysis.topmostDecal.texture.path).name + ' Group';
            var count = 0;
            var name = baseName;

            while (true) {
                if (!groupNames.has(name)) {
                    return name;
                }

                count += 1;
                name = baseName + ' ' + count;
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