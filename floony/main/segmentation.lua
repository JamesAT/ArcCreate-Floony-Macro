require "floony.lib.macroUtil"
require "floony.lib.utils"

------------------------------------\
-- // ARCS MANIPULATION v2? // --    |
------------------------------------/
addFolderWithIcon("floony", "floony.segmentation", "e1a0", "- Arcs Segmentation -")

-----------------------------
--- /// SETTINGS /// ---
-----------------------------
    -- Defaults
local forceHeightLines = false
local stasisArcs = false
local stasisTrace = false
local stasisOption = 1
local riceMultiplier = 0.5

    -- // SETTINGS // --
local function aestheticBoolean(value)
    if value then
        return "<color=#20AA20>True</color>"
    else
        return "<color=#FF7070>False</color>"
    end
end

function updateSettings(self)
    local dialogRequest = DialogInput.withTitle("Segmentation Setting").requestInput(
        {
            DialogField.create("force")
                .setLabel("Force Lines")
                .setTooltip("Force segmented arcs to have height lines, regardless of their real height.\n(This applies to ALL segmentation)")
                .checkbox(),
                
            DialogField.create("stasisDesc")
                .description("<b>Stasis / Rice config</b>"),
                
            DialogField.create("stasis")
                .setLabel("Type")
                .defaultTo(stasisOption)
                .setTooltip("1 = Disable | 2 = None | 3 = Add Trace")
                .textField(FieldConstraint.create().integer().gEqual(1).lEqual(3)),
                
            DialogField.create("ricemult")
                .setLabel("Multiplier")
                .setTooltip("How much to shorten each segment when converting an arc to rice arcs.")
                .defaultTo(riceMultiplier)
                .textField(FieldConstraint.create().float().greater(0).lEqual(1)),

            DialogField.create("currentState")
                .description(
                    "Force lines = " .. aestheticBoolean(forceHeightLines) ..
                    "\nStasis arc = " .. aestheticBoolean(stasisArcs) .. " | With Trace = " .. aestheticBoolean(stasisTrace) ..
                    "\nRice Multiplier = " .. riceMultiplier
                )
        }
    )
    coroutine.yield()
    forceHeightLines = dialogRequest.result["force"]
    riceMultiplier = dialogRequest.result["ricemult"]
    stasisOption = dialogRequest.result["stasis"]
    
    if stasisOption == "2" then
        stasisArcs = true
        stasisTrace = false
    elseif stasisOption == "3" then
        stasisArcs = true
        stasisTrace = true
    else
        stasisArcs = false
        stasisTrace = false
    end
end

-- // ARCS SEGMENTATION FUNCTIONS // --
--[[
s: Start
m: midPos
e: End
t0: startTiming | t1: endTiming
--]]

function arcGenerator(typ, spliceTime)
    return function(cmd)
        local arcA = Request.arc("Select dominant arc")
        local arcB = Request.arc("Select target arc")
        
        if not (arcA.isVoid and arcB.isVoid) then
            if arcA.timing ~= arcB.timing then
                notify("Both arcs must start at the same time."); return false
            end
            if arcA.endTiming ~= arcB.endTiming then
                notify("Both arcs must end at the same time."); return false
            end
            if arcA.color ~= arcB.color then
                notify("Both arcs must have the same color."); return false
            end
            if arcA.isVoid ~= arcB.isVoid then
                notify("Both arcs must be void or not."); return false
            end
            if arcA.timingGroup ~= arcB.timingGroup then
                notify("Both arcs must be in the same timing group."); return false
            end
            if arcA.startXY == arcB.startXY and arcA.endXY == arcB.endXY and arcA.type == arcB.type then
                notify("Both arcs must not overlap."); return false
            end
        end
        
        -- Programming --
        local t0, t1 = arcA.timing, arcA.endTiming
        local densitySlice = spliceTime
            or (Context.beatLengthAt(t0, arcA.timingGroup) / Context.beatlineDensity)

        local flag = true
        local isVoid, color, aType, tg = arcA.isVoid, arcA.color, arcA.type, arcA.timingGroup

        for s, e in bestDivisions(t0, t1, densitySlice) do
            local m = (typ == "brr" and (s + e) / 2)
                   or (typ == "ran" and e)
                   or (typ == "nar" and s)
                   or 0

            local startPos = arcA.positionAt(s)
            local midPos   = arcB.positionAt(m)
            local endPos   = arcA.positionAt(e)

            if (startPos.y == midPos.y or midPos.y == endPos.y)
               and midPos.y > 0 and forceHeightLines then
                endPos.y = endPos.y - 0.01
            end

            if typ == "wave" then
                if flag then
                    cmd.add(Event.arc(s, startPos, s, arcB.positionAt(s), isVoid, color, aType, tg).save())
                    cmd.add(Event.arc(s, arcB.positionAt(s), e, arcB.positionAt(e), isVoid, color, aType, tg).save())
                else
                    cmd.add(Event.arc(s, arcB.positionAt(s), s, startPos, isVoid, color, aType, tg).save())
                    cmd.add(Event.arc(s, startPos, e, endPos, isVoid, color, aType, tg).save())
                end
                flag = not flag

            elseif typ == "line" then
                cmd.add(Event.arc(s, startPos, s, arcB.positionAt(s), isVoid, color, aType, tg).save())

            else
                cmd.add(Event.arc(s, startPos, m, midPos, isVoid, color, aType, tg).save())
                cmd.add(Event.arc(m, midPos, e, endPos, isVoid, color, aType, tg).save())
            end
        end

        cmd.add(arcA.delete())
        cmd.add(arcB.delete())
    end
end

local function arc_split(arc, get_segments, amyg)
    local segments = {}
    local splice   = Context.beatLengthAt(arc.timing, arc.timingGroup) / Context.beatlineDensity

    for s, e in bestDivisions(arc.timing, arc.endTiming, splice) do
        local start_pos = arc.positionAt(s)
        local end_pos   = arc.positionAt(e)

        for _, seg in ipairs(get_segments(arc, s, e, start_pos, end_pos)) do
            table.insert(segments, seg)
        end
    end

    local cmd   = Command.create("Arc split edit")
    local shift = forceHeightLines or amyg

    for i, seg in ipairs(segments) do
        if shift then
            if i % 2 == 0 then
                seg.startXY = seg.startXY + xy(0, -0.01)
            else
                seg.endXY   = seg.endXY   + xy(0, -0.01)
            end
        end

        if i % 2 == 0 then
            if stasisArcs then
                if stasisTrace then
                    seg.isVoid = true
                    cmd.add(seg.save())
                else
                    cmd.add(seg.delete())
                end
            else
                cmd.add(seg.save())
            end
        else
            cmd.add(seg.save())
        end
    end

    return cmd, segments
end

local function arc_split_command(get_segments, amyg)
    return function(cmd)
        local sel = Event.getCurrentSelection(EventSelectionConstraint.create().arc())
        local arcs = table.icollapse(sel, "arc")
        if #arcs == 0 then
            notify("Please select one or more arcs to modify.")
            return false
        end

        for _, arc in ipairs(arcs) do
            local cmd2, _ = arc_split(arc, get_segments, amyg)
            cmd.add(cmd2)
            cmd.add(arc.delete())
        end
    end
end

-- MACROS › Segmentation.Generate --
FolderNew("floony.segmentation", "segmentation.generate", "ef3c", "[Generate]")

local generators = {
    { id = "brr",  name = "Zig-Zag",     icon = "e922", type = "brr" },
    { id = "ran",  name = "Ran",         icon = "e3e7", type = "ran" },
    { id = "nar",  name = "Reverse Ran", icon = "e3e6", type = "nar" },
    { id = "wave", name = "Square Wave", icon = "eba7", type = "wave" },
    { id = "line", name = "Line",        icon = "e152", type = "line" },
}

for _, g in ipairs(generators) do
    MacroNew(
        "segmentation.generate",
        g.id,
        g.name,
        g.icon,
        arcGenerator(g.type)
    )
end

-- MACROS › Floony.Segmentation.Split --
FolderNew("floony.segmentation", "floony.segmentation.split", "f184", "[Split]")
-- arc = Event.arc / s = Start Timing / e = End Timing / spos = Start Pos / epos = End Pos
MacroNew(
    "floony.segmentation.split", "split_normal",
    "Normal", "f108",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_amygdata",
    "Amygdata", "e260",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end, true
    )
)

MacroNew(
    "floony.segmentation.split", "split_chunky",
    "Chunky", "eba4",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {
                Event.arc(s, spos, math.lerp(s, e, 0.5), epos, arc.isVoid, arc.color, "s", arc.timingGroup),
                Event.arc(math.lerp(s, e, 0.5), epos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)
            }
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_rice",
    "Rice", "e5d3",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, math.lerp(s, e, riceMultiplier), spos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_stair",
    "Staircase", "ebaa",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {
                Event.arc(s, spos, e, spos, arc.isVoid, arc.color, "s", arc.timingGroup),
                Event.arc(e, spos, e, epos, arc.isVoid, arc.color, "s", arc.timingGroup)
            }
        end
    )
)

MacroNew(
    "floony.segmentation.split", "split_point",
    "Point (0ms)", "e837",
    arc_split_command(
        function(arc, s, e, spos, epos)
            return {Event.arc(s, spos, s, spos, arc.isVoid, arc.color, "s", arc.timingGroup)}
        end
    )
)

MacroNew("floony.segmentation", "floony.settings", "Settings", "e8b8", updateSettings)
