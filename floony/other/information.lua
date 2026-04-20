require 'floony.lib.macroUtil'
require 'floony.lib.utils'

------------------------------------\
-- // INFORMATION // --             |
------------------------------------/
-- // MS TO X:XX // --
function formatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- // CHART DETAILS // --
MacroNewNOCMD(
    "floony", "chartinfo", 
    "Chart Information", "e97a",
    function()
        local allNotes = Event.query(EventSelectionConstraint.create().any())
        local combo = Context.maxCombo
        local note = Context.noteCount
        local timinggroup = Context.timingGroupCount - 1
        local songlength = formatTime(Context.songLength)
        local count = {
            arc = 0, trace = 0, hold = 0, tap = 0, arctap = 0, fake = 0,
            timing = 0, camera = 0, scenecontrol = 0,
            totalnotes = 0, totalevents = 0, summary = 0
        }
        
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.noInput == true then
                local fakeGroupNotes = Event.query(EventSelectionConstraint.create().ofTimingGroup(group.num).judgeable()).result
                
                for _, Fakenotes in pairs(fakeGroupNotes) do
                    count.fake = count.fake + #Fakenotes
                end
            end
        end
        local function conditionalFakeNotes()
            if count.fake > 0 then
                return "\n<color=#FF5733>Fake Notes: </color>" .. count.fake
            else
                return ""
            end
        end

        for eventType, notes in pairs(allNotes.result) do
            if eventType == "arc" then
                for _, note in ipairs(notes) do
                    if note.is("solidArc") then
                        count.arc = count.arc + 1
                    elseif note.is("voidArc") then
                        count.trace = count.trace + 1
                    end
                end
            else
                count[eventType] = #notes
            end
        end
        
        count.totalnotes = count.arc + count.trace + count.hold + count.tap + count.arctap
        count.totalevents = count.timing + count.camera + count.scenecontrol + timinggroup
        count.summary = count.totalnotes + count.totalevents

        if timinggroup == 0 then
            timinggroup = "0 (Base)"
        end
        
        --[[ currently broken as it's only picked the Accent
        function sideDivider()
        if Context.side == "light" then
            return "\n<color=#1e97d4>[]--Stats---------------------------------------------[]</color>"
        elseif Context.side == "conflict" then
            return "\n<color=#7f4dbd>[]--Stats---------------------------------------------[]</color>"       
        elseif Context.side == "colorless" then
            return "\n<color=#ddd7de>[]--Stats---------------------------------------------[]</color>"
        end end
        ]]--

                notify(
                    "Chart info displayed (Hover to view statistics)\n" ..
                    "\n" ..
                    "[]--Stats---------------------------------------------[]" ..
                    "\nSong Length: " .. songlength ..
                    " | Current Combo: " .. combo ..
                    "\n" ..
                    "\n[]--Elements---------------------------------------------[]" ..
                    "\n" ..
                    "Tap: " .. count.tap ..
                    " | Hold: " .. count.hold ..
                    " | SkyTap: " .. count.arctap ..
                    " | Arc: " .. count.arc ..
                    " | Trace: " .. count.trace ..
                    conditionalFakeNotes() ..
                    "\n<color=#FFD73B>Total Notes: </color>" .. count.totalnotes ..
                    "\n" ..
                    "\nTiming: " .. count.timing ..
                    " | Timing Group: " .. timinggroup  ..
                    " | Scenecontrol: " .. count.scenecontrol ..
                    " | Camera: " .. count.camera ..
                    "\n<color=#FFD73B>Total Event: </color>" .. count.totalevents ..
                    "\n" ..
                    "\n[]--Summaries---------------------------------------------[]" ..
                    -- sideDivider() ..
                    "\n<color=#C3FF3E>Total Notes + Total Event: </color>" .. count.summary ..
                    "\n" ..
                    "\n"
                ) end

    
        --[[ // Using Dialog Display
        local dialogContent = {
            DialogField.create("notescount")
                .description(
                    "[]--Stats---------------------------------------------[]" ..
                    "\nSong Length: " .. songlength ..
                    " | Current Combo: " .. combo ..
                    "\n" ..
                    "\n[]--Elements---------------------------------------------[]" ..
                    "\n" ..
                    "Tap: " .. count.tap ..
                    " | Hold: " .. count.hold ..
                    " | SkyTap: " .. count.arctap ..
                    " | Arc: " .. count.arc ..
                    " | Trace: " .. count.trace ..
                    -- "\n<color=#FF5733>Fake Notes: </color>" .. count.fake ..
                    "\n<color=#FFD73B>Total Notes: </color>" .. count.totalnotes ..
                    "\n" ..
                    "\nTiming: " .. count.timing ..
                    " | Timing Group: " .. timinggroup  ..
                    " | Scenecontrol: " .. count.scenecontrol ..
                    " | Camera: " .. count.camera ..
                    "\n<color=#FFD73B>Total Event: </color>" .. count.totalevents ..
                    "\n" ..
                    "\n[]--Summaries---------------------------------------------[]" ..
                    -- sideDivider() ..
                    "\n<color=#C3FF3E>Total Notes + Total Event: </color>" .. count.summary
                )
        }

        -- Display dialog
        DialogInput.withTitle("Chart Information").requestInput(dialogContent)
    end
    ]]--
)

--[[----------------------------------------------------]]--

-- // HEATMAP, PROGRESS, and something // --

-- // SELECT YOUR COLOR // --
    -- / Select your color!
local default = { 99, 183, 204 } -- aka Blue
local red = { 123, 13, 30 }
local green = { 19, 154, 67 }
local yellow = { 242, 232, 99 }
local custom = { r, g, b }

local colorPicked = green

local min_color = { 65, 65, 65 }
local max_color = colorPicked

-- // FUNCTIONS // --
local function allocate(events, count, length, counter)
    local tbl = {}
    for i = 1, count do tbl[i] = 0 end
    local max = 0
    local slot_length = length / count
    
    for _, e in ipairs(events.resultCombined) do
        counter(e, function(timing)
            local slot = math.floor(timing / slot_length) + 1
            if slot > 0 and slot <= #tbl then
                tbl[slot] = tbl[slot] + 1
                if tbl[slot] > max then max = tbl[slot] end
            end
        end)
    end
    if max == 0 then return nil, 0 end
    for i = 1, #tbl do tbl[i] = tbl[i] / max end
    return tbl, max
end

local function allocation_to_str(allocation)
    local t = {}
    for i = 1, #allocation do
        local num = allocation[i]
        local r = min_color[1] + (max_color[1] - min_color[1]) * num
        local g = min_color[2] + (max_color[2] - min_color[2]) * num
        local b = min_color[3] + (max_color[3] - min_color[3]) * num
        t[i] = string.format("<color=#%02x%02x%02x>■</color>", r, g, b)
    end
    return "[" .. table.concat(t, "") .. "]"
end

local function getTimeline(lengthMs)
    local t0 = "0:00"
    local t25 = "|" .. formatTime(lengthMs * 0.25) .. "|"
    local t50 = "|" .. formatTime(lengthMs * 0.50) .. "|"
    local t75 = "|" .. formatTime(lengthMs * 0.75) .. "|"
    local t100 = formatTime(lengthMs)
    
    local padding = string.rep(" ", 36)  -- Adjust the scale of the duration
    -- %% to escape the percentage sign for Lua string.format
    return string.format("%s%s<size=70%%>%s%s%s%s%s</size>%s%s", 
        t0, padding, t25, padding, t50, padding, t75, padding, t100)
end

-- // MACRO // --
MacroNew(
    'floony', 'floony.progress',
    'Density / Progress', 'e9e6',
    function(cmd)
        local all = Event.query(EventSelectionConstraint.create().any())
        local length = Context.songLength
        local char_count = 41 -- Adjust the scale of the progress bar

        local totalNotes = 0
        for _, e in ipairs(all.resultCombined) do
            if not Event.getTimingGroup(e.timingGroup).noInput then
                if e.is("tap") or e.is("arctap") or e.is("hold") or (e.is("arc") and not e.isVoid) then
                    totalNotes = totalNotes + 1
                end
            end
        end

        local by_count, _ = allocate(all, char_count, length, function(e, adder)
            if e.is("timing") or e.is("camera") or e.is("scenecontrol") then
                adder(e.timing)
            end
        end)
        
        local by_combo, note_max = allocate(all, char_count, length, function(e, adder)
            if Event.getTimingGroup(e.timingGroup).noInput then return end
            if e.is("tap") or e.is("arctap") then 
                adder(e.timing) 
            elseif e.is("hold") or (e.is("arc") and not e.isVoid) then
                local bpm = math.abs(Context.bpmAt(e.timing, e.timingGroup))
                local dur = e.endTiming - e.timing
                if bpm ~= 0 and dur > 0 then
                    local x = (bpm >= 255) and 60000 or 30000
                    local increment = x / bpm / Context.timingPointDensityFactor
                    local count = math.floor(dur / increment)
                    if count <= 1 then adder(e.timing + dur / 2)
                    else
                        for i = 0, count - 1 do adder(e.timing + (increment * i)) end
                    end
                end
            end
        end)
        
        local filled_slots = 0
        if by_combo then for i = 1, #by_combo do if by_combo[i] > 0 then filled_slots = filled_slots + 1 end end end
        local percentage = math.floor((filled_slots / char_count) * 100)
        
        local coverageDisplay = ""
            if percentage >= 100 then
                coverageDisplay = string.format("<color=#4CFC6B><b>%d%% <size=90%%>- Completed!</b></size></color> <size=70%%>(Don't forget to polish the chart)</size>", percentage)
            elseif percentage >= 97 then
                coverageDisplay = string.format("<color=#2AA13C><b>%d%% <size=90%%>- Technically Completed</b></size></color> <size=70%%>(Don't forget to polish the chart)</size>", percentage)
            elseif percentage >= 90 then
                coverageDisplay = string.format("<color=#F4D35E><b>%d%% <size=90%%>- Almost Finished</b></size></color> <size=70%%>(Or it is finished?)</size>", percentage)
            elseif percentage >= 50 then
                coverageDisplay = string.format("<b>%d%% <size=90%%>- Halfway there!</size></b>", percentage)
            else
                coverageDisplay = string.format("<b>%d%%</b>", percentage)
            end
                             
        local slotSec = (length / char_count) / 1000
        local peakNPS = by_combo and string.format("%.2f", note_max / slotSec) or "0.00"
        local avgNPS = length > 0 and string.format("%.2f", totalNotes / (length / 1000)) or "0.00"
        
        local timeline = getTimeline(length)
        local dialog = DialogInput.withTitle("Chart Progress & Density")
            .requestInput({
                DialogField.create("Prog").description(string.format("</b><size=115%%>Chart Progress: %s</size>", coverageDisplay)),

                DialogField.create("Density").description("<b>- Events Density:</b> <size=70%>(Timing / Camera / Scenecontrol)</size>"),
                DialogField.create("AllocE").description("<color=#888888>" .. timeline .. "</color>\n" .. (by_count and allocation_to_str(by_count) or "<color=#F25F5C>[Chart the song first, then come back]</color>")),
                
                DialogField.create("Notes").description("<b>- Notes Density:</b> <size=70%>(Playable Notes)</size>"),
                DialogField.create("AllocC").description("<color=#888888>" .. timeline .. "</color>\n" .. (by_combo and allocation_to_str(by_combo) or "<color=#F25F5C>[Chart the song first, then come back]</color>")),
                
                DialogField.create("Stats").description(string.format("\n<size=70%%>NPS (Notes per Second) Stats</size>\nPeak NPS: <b>%s</b>\nAverage NPS: <b>%s</b>", peakNPS, avgNPS)),
            })
end)

-- // PROGRESS LENGTH - LAST CHARTED // --

FolderNew('floony', 'floony.proglength', 'e41c', '[Progress Length]')

local function calculateProgress(tStart, tEnd)
    if not tEnd or tEnd <= 0 then
        dialogNotify("Invalid time range! Ensure endTiming greater than the startTiming.")
        return
    end

    local notes = Event.query(
        CustomConstraints.timeRange(tStart, tEnd)
    )
    notes = table.icollapse(notes, 'arc', 'tap', 'hold', 'arctap')

    local songLength = Context.songLength

    local furthestTiming = 0
    for _, note in ipairs(notes) do
        local endTiming = note.is("long") and note.endTiming or note.timing
        furthestTiming = math.max(furthestTiming, endTiming)
    end

    local chartedPercentage = (furthestTiming / songLength) * 100
    if chartedPercentage > 100 then
        chartedPercentage = 100
    end

    local selectedDuration = tEnd - tStart

    local message
    if chartedPercentage >= 97 then
        message = string.format(
            "Charted Length: %s of %s | <color=#53DD6C>Progress: %.2f%%</color>\n" ..
            "<size=85%%>Selected Duration: %s</size>",
            formatTime(furthestTiming),
            formatTime(songLength),
            chartedPercentage,
            formatTime(selectedDuration)
        )
    else
        message = string.format(
            "Charted Length: %s of %s | Progress: %.2f%%\n" ..
            "<size=85%%>Selected Duration: %s</size>",
            formatTime(furthestTiming),
            formatTime(songLength),
            chartedPercentage,            
            formatTime(selectedDuration)
        )
    end
    
    dialogNotify(message)
end



-- Macro for calculating progress from the beginning
MacroNew(
    'floony.proglength', 'beginning',
    'From Beginning', 'e089',
    function(cmd)
        local tStart = 0
        local tEnd = Request.time('Please select the last charted timing')
        calculateProgress(tStart, tEnd)
    end
)

-- Macro for calculating progress within a specific section
MacroNew(
    'floony.proglength', 'segment',
    'Segment', 'e94b',
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        if not tStart or tStart <= 0 or not tEnd or tEnd <= tStart then
            dialogNotify("Invalid time range! Ensure endTiming greater than the startTiming.")
            return
        end

        local songLength = Context.songLength

        local sectionDuration = tEnd - tStart
        local percentageOfSong = (sectionDuration / songLength) * 100

        local message = string.format(
            "Duration: %s to %s (%s of %s) | Covers: %.2f%% of Song",
            formatTime(tStart),
            formatTime(tEnd),
            formatTime(sectionDuration),
            formatTime(songLength),
            percentageOfSong
        )

        dialogNotify(message)
    end
)

-- // GENERATE FORUM CHART FORMAT // --
MacroNewNOCMD(
    "floony", "genforum", 
    "Generate Post Format", "e0bf",
    function()
        local dialogFields = {
            DialogField.create("illustrator")
                .setLabel("Illustrator")
                .setTooltip("Enter the illustrator name (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartConstantFuture")
                .setLabel("Chart Constant (Future)")
                .setTooltip("Enter the chart constant for Future difficulty (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartViewFuture")
                .setLabel("Chart View (Future)")
                .setTooltip("Enter the URL for Future difficulty (leave blank for N/A)")
                .textField(FieldConstraint.create().any()),
                
            DialogField.create("chartDescription")
                .setLabel("Chart Description")
                .setTooltip("Enter a chart description (leave blank for N/A)")
                .textField(FieldConstraint.create().any())
        }
        
        local dialogResult = DialogInput.withTitle("Chart Post Format Addition")
            .requestInput(dialogFields)
            
        if not dialogResult then
            notify("Operation canceled.")
            return
        end
        coroutine.yield()
        local illustrator = (dialogResult.illustrator and dialogResult.illustrator ~= "") and dialogResult.illustrator or "N/A"
        local chartConstantFuture = (dialogResult.chartConstantFuture and dialogResult.chartConstantFuture ~= "") and dialogResult.chartConstantFuture or "N/A"
        local chartViewFuture = (dialogResult.chartViewFuture and dialogResult.chartViewFuture ~= "") and dialogResult.chartViewFuture or "N/A"
        local chartDescription = (dialogResult.chartDescription and dialogResult.chartDescription ~= "") and dialogResult.chartDescription or "N/A"
        
        local songTitle = Context.title or "N/A"
        local composer = Context.composer or "N/A"
        local charter = Context.charter or "N/A"
        local alias = Context.alias or "N/A"
        
        local info = "Song: " .. songTitle .. "\n" ..
                     "Composer: " .. composer .. "\n" ..
                     "Illustrator: " .. illustrator .. "\n\n" ..
                     "Difficulty: Future ?\n" ..
                     "Charter: " .. charter .. "\n" ..
                     "Alias: " .. alias .. "\n" ..
                     "Chart Constant: " .. chartConstantFuture .. "\n" ..
                     "Chart View: " .. chartViewFuture .. "\n\n" ..
                     "Chart Description:\n" .. chartDescription
        
        -- Copy the generated info to the system clipboard
        Context.systemClipboard = info
        
        notify("Chart Post Format generated and copied to the clipboard!")
    end
)


--[[ In WIP hell
MacroNewNOCMD(
    'floony', 'verification',
    'Is this legal?', 'f1c2',
    function()
        -- Query all note events
        local notes = Event.query(EventSelectionConstraint.create().any())

        -- Collapse to simplify note types for processing
        notes = table.icollapse(notes, 'hold', 'tap')

        local invalidNotes = {}

        for _, note in ipairs(notes) do
            -- Check for invalid lanes
            if note.is 'tap' or note.is 'hold' then
                if note.lane < 1 or note.lane > 4 then
                    table.insert(invalidNotes, note)
                end
            end
        end

        -- Query and filter for 'illegal' scenecontrol events
        local sceneGroup = Event.query(EventSelectionConstraint.create().scenecontrol()).scenecontrol
        local groupIllegalEvents = {}

        local illegalTypes = {'groupalpha', 'trackdisplay', 'enwidenlanes', 'enwidencamera'}
        for _, scEvent in ipairs(sceneGroup) do
            if table.contains(illegalTypes, scEvent.type) then
                table.insert(groupIllegalEvents, scEvent)
            end
        end

        local message = ""

        if #invalidNotes > 0 then
            message = message .. "<b>- Invalid Notes Detected:</b>\n\n"
            for _, note in ipairs(invalidNotes) do
                message = message .. string.format(
                    "Note at Timing: %d, Lane: %d, Timing Group: %d\n",
                    note.timing, note.lane, note.timingGroup
                )
            end
            message = message .. "\n"  -- Add space after invalid notes section
        end

        if #groupIllegalEvents > 0 then
            message = message .. "<b>- Illegal Scenecontrol Events Detected:</b>\n\n"
            for _, scEvent in ipairs(groupIllegalEvents) do
                message = message .. string.format(
                    "Scenecontrol at Timing: %d, Type: %s, Timing Group: %d\n",
                    scEvent.timing, scEvent.type, scEvent.timingGroup
                )
            end
        end

        if #invalidNotes > 0 or #groupIllegalEvents > 0 then
            local dialog = DialogInput.withTitle("Verification Notification")
                .requestInput({
                    DialogField.create("Issues Found").description(message),
                })

            Event.setSelection(invalidNotes)
        else
            notify("No illegal stuff found. You're good to go!")
        end
    end
)
]]--