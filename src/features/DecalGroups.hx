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
        if (analysis.groupNames.size == 0) {
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

        final shouldApplyTopmostGroupName = analysis.groupNames.size > 1 || analysis.nullGroupNamesCount > 0;

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
            groupNames: groupNames,
        }
    }

    static function _extractDecals(decalsToExtract: Array<Decal>, from: Array<Decal>) {
        final decalsToExtractSet = new Set(decalsToExtract);
        final extractedDecals = new Array<Decal>();

        var i = 0;
        while (i < from.length) {
            final decal = from[i];

            if (decalsToExtractSet.has(decal)) {
                from.splice(i, 1);
                extractedDecals.push(decal);
                continue;
            }

            i += 1;
        }

        return extractedDecals;
    }
}

typedef DecalGroupNameAnalysis = {
    final topmostDecal:Decal;
    final topmostGroupName:String;
    final groupNames:Set<String>;
    final nullGroupNamesCount:Int;
}