require "floony.lib.macroUtil"
require "floony.lib.utils"

------------------------------------\
-- // the funny :sparkles: // --    |
------------------------------------/
FolderNew('floony', 'floony.fun', 'ea65', '- The funny -')

-- // RAINBOW // --
MacroNew(
    "floony.fun", "rainbow", 
    "Turn Rainbow", "e3fc",
    function(cmd)
        local arc = Request.arc("Select the start of the arc group that you want to turn into a rainbow.")

        local arcs = getFullArc(arc)
        local farcs = {}
        for _, a in ipairs(arcs) do
            arcSplit(a, cmd, farcs)
        end
        cycleColors(farcs, cmd)
    end
)

-- // CHAOTIC RANDOM NOTES // --
MacroNew(
    "floony.fun", "chaotic", 
    "Chaotic Notes", "e043",
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        local dialogFields = {
            DialogField.create("intensity")
                .setLabel("Intensity")
                .setTooltip("How chaotic will it be?")
                .textField(FieldConstraint.create().integer())
                .defaultTo(1),
            DialogField.create("exclude")
                .description("Which Notes to Exclude?"),
            DialogField.create("tap")
                .setLabel("Tap")
                .checkbox(),
            DialogField.create("hold")
                .setLabel("Hold")
                .checkbox(),
            DialogField.create("arc")
                .setLabel("Arc")
                .checkbox(),
            DialogField.create("sky")
                .setLabel("SkyTap")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Chaotic Notes").requestInput(dialogFields)
        coroutine.yield()
        
        local intensityVal = tonumber(dialogRequest.result["intensity"]) or 1
        local tapEX, holdEX, arcEX, skyEX = dialogRequest.result["tap"], dialogRequest.result["hold"], dialogRequest.result["arc"], dialogRequest.result["sky"]
            
        local chaosTime = Context.beatLengthAt(tStart, Context.currentTimingGroup) / Context.beatlineDensity
        
        for timing = tStart, tEnd - chaosTime, chaosTime do
            for _ = 1, intensityVal do
                if not tapEX then cmd.add(Event.tap(timing + math.random(0, chaosTime), math.random(1, 4), Context.currentTimingGroup).save()) end
                if not holdEX then
                    local holdDuration = math.random(50, 500)
                    local holdTiming = timing + math.random(1, chaosTime - holdDuration)
                    cmd.add(Event.hold(holdTiming, holdTiming + math.random(holdDuration, chaosTime), math.random(1, 4), Context.currentTimingGroup).save())
                end
                if not arcEX then
                    local randomBoolean = math.random() < 0.5
                    local arcTiming = timing + math.random(0, chaosTime)
                    local position, endposition = xy(math.randomf(-0.5, 1.5), math.randomf(0, 1)), xy(math.randomf(-0.5, 2), math.randomf(0, 2))
                    cmd.add(Event.arc(arcTiming, position, arcTiming + math.random(1, 500), endposition, randomBoolean, math.random(0,1), "s", Context.currentTimingGroup).save())
                end
                if not skyEX then
                    local arcTiming = timing + math.random(0, chaosTime)
                    local position = xy(math.randomf(-0.5, 1.5), math.randomf(0, 1))
                    local arcEvent = Event.arc(arcTiming, position, arcTiming + 2, position, true, 0, "s", Context.currentTimingGroup)
                    cmd.add(arcEvent.save())
                    local skyEvent = Event.arctap(timing + 1, arcEvent)
                    cmd.add(skyEvent.save())
                end
            end
        end
    end
)

-- // -0.2 ARCS-INATOR // --
MacroNewNOCMD(
    "floony.fun", "mistake", 
    "Beginner's Mistake", "e99a",
    function()
        local cmd = Command.create("-0.2 arcs")
        local arcs = Event.query(EventSelectionConstraint.create().arc()).arc

        for _, arc in ipairs(arcs) do
            if arc.startXY.y == 0 then
                arc.startXY = xy(arc.startXY.x, -0.2)
            end

            if arc.endXY.y == 0 then
                arc.endXY = xy(arc.endXY.x, -0.2)
            end
            cmd.add(arc.save())
        end

        cmd.commit()
        notify("Enjoy the -0.2 arcs\nBtw you can undo this if you want to.")
    end
)

-- // C0MB0 BR34KER // --
MacroNewNOCMD(
    "floony.fun", "warning", 
    "Don't click this", "e002",
    function()
        -- Pre-warning
        local dialogFields = {
            DialogField.create("prewarn")
                .setLabel("Continue")
                .setTooltip("I click this on purpose. Execute this macro.")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Did you accidentally click this? If so, then please leave.").requestInput(dialogFields)
        coroutine.yield()
        local prewarn = dialogRequest.result["prewarn"]
        
        -- First warning
        if prewarn then
            local dialogFields2 =  {
                DialogField.create("firstwarn")
                .setLabel("Proceed.")
                .setTooltip("I want to execute this macro.")
                .checkbox()
            }
            local dialogRequest2 = DialogInput.withTitle("Oh really? But this is dangerous.").requestInput(dialogFields2)
            coroutine.yield()
            local firstwarn = dialogRequest2.result["firstwarn"]
            
            -- Second warning
            if firstwarn then
                local dialogFields3 = {
                    DialogField.create("secondwarn")
                    .setLabel("Proceed..")
                    .setTooltip("I am sure.")
                    .checkbox()
                }
                local dialogRequest3 = DialogInput.withTitle("Are you sure? Because once you execute this, it won't be undone.").requestInput(dialogFields3)
                coroutine.yield()
                local secondwarn = dialogRequest3.result["secondwarn"]
                
                -- Third warning
                if secondwarn then
                    local dialogFields4 = {
                        DialogField.create("thirdwarn")
                        .setLabel("Proceed...")
                        .setTooltip("Yes, I understand.")
                        .checkbox()
                    }
                    local dialogRequest4 = DialogInput.withTitle("Last warning, are you really sure!? The consequences will be dire.").requestInput(dialogFields4)
                    coroutine.yield()
                    local thirdwarn = dialogRequest4.result["thirdwarn"]
                    
                    -- Last warning
                    if thirdwarn then
                        local dialogFields5 = {
                            DialogField.create("lastwarn")
                            .setLabel("...")
                            .setTooltip("Type 'Execute' to run the command.")
                            .textField(FieldConstraint.create().any())
                        }
                        local dialogRequest5 = DialogInput.withTitle("ACTUAL LAST WARNING, ARE YOU REALLY VERY SURE????!!!").requestInput(dialogFields5)
                        coroutine.yield()
                        local lastwarn = dialogRequest5.result["lastwarn"]:lower()
                        
                        -- Add random tap note.
                        if lastwarn == "execute" then
                            local cmd = Command.create("Well... your loss then.")
                            for i = 1, math.random(69, 420) do
                                cmd.commit()
                            end
                            cmd.add(Event.tap(math.random(1, Context.songLength), 99, Context.currentTimingGroup).save())
                            cmd.commit()
                        end
                    end
                end
            end
        end
    end
)

-- // u stupood // --
MacroNewNOCMD(
    "floony.fun", "nineplusten", 
    "What's 9+10?", "ea5f",
    function()
        local cmd = Command.create("You stupid-")

        local function addArc(startTiming, endTiming, startX, endX, startY, endY)
            cmd.add(
                Event.arc(
                    startTiming,
                    xy(startX, startY),
                    endTiming,
                    xy(endX, endY),
                    true,
                    0,
                    "s",
                    Context.currentTimingGroup
                ).save()
            )
        end

        local startTiming = Context.currentTiming + Context.beatLengthAt(Context.currentTiming, Context.currentTimingGroup) / Context.beatlineDensity
        local endTiming = Context.currentTiming + Context.beatLengthAt(Context.currentTiming, Context.currentTimingGroup) / Context.beatlineDensity

        addArc(startTiming, endTiming, 0.90, 0.80, 0.20, 0.20)
        addArc(startTiming, endTiming, 1.00, 0.90, 0.00, 0.20)
        addArc(startTiming, endTiming, 0.55, 0.75, 0.60, 0.90)
        addArc(startTiming, endTiming, 0.55, 0.55, 0.70, 0.60)
        addArc(startTiming, endTiming, 0.65, 0.65, 0.00, 0.10)
        addArc(startTiming, endTiming, 0.35, 0.30, 0.10, 0.20)
        addArc(startTiming, endTiming, 0.05, 0.05, 0.20, 0.00)
        addArc(startTiming, endTiming, 0.40, 0.35, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.40, 0.40, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.05, 0.40, 0.20, 0.70)
        addArc(startTiming, endTiming, 0.70, 0.75, 0.80, 0.70)
        addArc(startTiming, endTiming, 0.00, 0.20, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.75, 0.80, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.80, 0.80, 0.00, 1.00)
        addArc(startTiming, endTiming, 0.00, 0.00, 0.00, 0.25)
        addArc(startTiming, endTiming, 0.38, 0.00, 0.75, 0.25)
        addArc(startTiming, endTiming, 0.00, 0.13, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.38, 0.38, 1.00, 0.75)
        addArc(startTiming, endTiming, 0.13, 0.38, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.00, 0.35, 0.00, 0.00)
        addArc(startTiming, endTiming, 0.65, 1.00, 0.00, 0.00)
        addArc(startTiming, endTiming, 0.55, 0.75, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.35, 0.35, 0.00, 0.10)
        addArc(startTiming, endTiming, 0.75, 0.75, 0.00, 1.00)

        cmd.commit()
        notify("21!")
    end
)

-- // Zydemon // --
    -- code by imrich (thanks) --
MacroNewNOCMD(
    "floony.fun", "zydemon",
    "Zydemon", "ef55",
    function ()
        -- Request timing and position
        local timingRequest = TrackInput.requestTiming("Select timing")
        coroutine.yield()
        local timing = timingRequest.result.timing
        
        local position = TrackInput.requestPosition(timing, "Select grid position")
        coroutine.yield()
        local xOffset = position.result["x"] - 0.5
        local yOffset = position.result["y"] - 0.5

        local cmd = Command.create("Add zydemon")
        local zydetg = Event.createTimingGroup("name=Zydemon, noarccap, noheightindicator")
        cmd.add(zydetg.save())

        local function addArc(startX, startY, endX, endY)
            local arcEvent = Event.arc(
                timing, 
                startX + xOffset, 
                startY + yOffset,
                timing,
                endX + xOffset, 
                endY + yOffset, 
                true, 
                0, 
                "s"
            )
            cmd.add(arcEvent.save().withTimingGroup(zydetg))
        end

        -- Add Zyde Trace
        addArc(0.68, 0.54, 0.62, 0.51)
        addArc(0.32, 0.32, 0.33, 0.25)
        addArc(0.30, 0.42, 0.37, 0.46)
        addArc(0.62, 0.64, 0.66, 0.71)
        addArc(0.66, 0.71, 0.68, 0.64)
        addArc(0.60, 0.35, 0.61, 0.35)
        addArc(0.43, 0.33, 0.43, 0.33)
        addArc(0.54, 0.26, 0.65, 0.25)
        addArc(0.65, 0.25, 0.67, 0.25)
        addArc(0.38, 0.36, 0.38, 0.35)
        addArc(0.39, 0.35, 0.40, 0.35)
        addArc(0.58, 0.49, 0.61, 0.49)
        addArc(0.69, 0.56, 0.68, 0.54)
        addArc(0.28, 0.92, 0.27, 1.00)
        addArc(0.31, 0.57, 0.32, 0.65)
        addArc(0.72, 0.47, 0.70, 0.28)
        addArc(0.34, 0.72, 0.42, 0.56)
        addArc(0.58, 0.36, 0.58, 0.39)
        addArc(0.27, 0.66, 0.29, 0.59)
        addArc(0.28, 0.50, 0.31, 0.69)
        addArc(0.41, 0.04, 0.34, 0.16)
        addArc(0.43, 0.38, 0.43, 0.44)
        addArc(0.39, 0.36, 0.39, 0.36)
        addArc(0.61, 0.49, 0.70, 0.44)
        addArc(0.43, 0.92, 0.52, 0.94)
        addArc(0.33, 0.35, 0.34, 0.35)
        addArc(0.33, 0.33, 0.32, 0.33)
        addArc(0.54, 0.30, 0.54, 0.26)
        addArc(0.34, 0.16, 0.29, 0.32)
        addArc(0.62, 0.51, 0.53, 0.51)
        addArc(0.52, 0.35, 0.54, 0.34)
        addArc(0.49, 0.37, 0.50, 0.37)
        addArc(0.32, 0.36, 0.33, 0.35)
        addArc(0.34, 0.35, 0.37, 0.35)
        addArc(0.73, 1.00, 0.75, 0.82)
        addArc(0.37, 0.35, 0.37, 0.35)
        addArc(0.44, 0.25, 0.54, 0.26)
        addArc(0.34, 0.80, 0.29, 0.88)
        addArc(0.39, 0.25, 0.39, 0.34)
        addArc(0.53, 0.51, 0.62, 0.64)
        addArc(0.47, 0.34, 0.47, 0.34)
        addArc(0.39, 0.34, 0.33, 0.33)
        addArc(0.68, 0.64, 0.69, 0.56)
        addArc(0.31, 0.43, 0.32, 0.36)
        addArc(0.40, 0.50, 0.34, 0.53)
        addArc(0.36, 0.83, 0.43, 0.92)
        addArc(0.48, 0.44, 0.58, 0.49)
        addArc(0.65, 0.13, 0.58, 0.03)
        addArc(0.67, 0.77, 0.71, 0.61)
        addArc(0.33, 0.25, 0.44, 0.25)
        addArc(0.38, 0.35, 0.39, 0.35)
        addArc(0.37, 0.37, 0.37, 0.46)
        addArc(0.58, 0.03, 0.49, 0.00)
        addArc(0.34, 0.53, 0.31, 0.57)
        addArc(0.31, 0.69, 0.36, 0.83)
        addArc(0.25, 0.78, 0.27, 0.66)
        addArc(0.39, 0.35, 0.39, 0.35)
        addArc(0.46, 0.51, 0.40, 0.50)
        addArc(0.43, 0.33, 0.43, 0.33)
        addArc(0.73, 1.00, 0.73, 1.00)
        addArc(0.49, 0.37, 0.58, 0.36)
        addArc(0.71, 0.61, 0.72, 0.47)
        addArc(0.32, 0.33, 0.32, 0.32)
        addArc(0.74, 0.72, 0.71, 0.60)
        addArc(0.54, 0.34, 0.54, 0.30)
        addArc(0.39, 0.34, 0.39, 0.34)
        addArc(0.40, 0.35, 0.40, 0.35)
        addArc(0.44, 0.34, 0.44, 0.35)
        addArc(0.43, 0.37, 0.49, 0.37)
        addArc(0.37, 0.35, 0.37, 0.37)
        addArc(0.58, 0.39, 0.58, 0.49)
        addArc(0.50, 0.37, 0.50, 0.39)
        addArc(0.66, 0.80, 0.70, 0.86)
        addArc(0.47, 0.34, 0.47, 0.26)
        addArc(0.60, 0.89, 0.67, 0.77)
        addArc(0.63, 0.34, 0.66, 0.34)
        addArc(0.29, 0.32, 0.28, 0.50)
        addArc(0.63, 0.34, 0.63, 0.34)
        addArc(0.49, 0.00, 0.41, 0.04)
        addArc(0.37, 0.46, 0.38, 0.36)
        addArc(0.70, 0.86, 0.73, 1.00)
        addArc(0.50, 0.39, 0.50, 0.41)
        addArc(0.50, 0.41, 0.49, 0.44)
        addArc(0.47, 0.34, 0.52, 0.35)
        addArc(0.59, 0.49, 0.60, 0.35)
        addArc(0.42, 0.56, 0.46, 0.51)
        addArc(0.70, 0.28, 0.65, 0.13)
        addArc(0.62, 0.37, 0.62, 0.37)
        addArc(0.62, 0.32, 0.62, 0.26)
        addArc(0.62, 0.32, 0.62, 0.32)
        addArc(0.39, 0.34, 0.39, 0.34)
        addArc(0.75, 0.82, 0.74, 0.72)
        addArc(0.39, 0.34, 0.39, 0.35)
        addArc(0.27, 1.00, 0.25, 0.78)
        addArc(0.46, 0.35, 0.47, 0.34)
        addArc(0.43, 0.33, 0.44, 0.34)
        addArc(0.37, 0.46, 0.48, 0.44)
        addArc(0.32, 0.65, 0.34, 0.72)
        addArc(0.40, 0.35, 0.43, 0.33)
        addArc(0.39, 0.35, 0.39, 0.36)
        addArc(0.54, 0.35, 0.55, 0.35)
        addArc(0.39, 0.36, 0.43, 0.36)
        addArc(0.55, 0.35, 0.62, 0.32)
        addArc(0.45, 0.35, 0.46, 0.35)
        addArc(0.52, 0.94, 0.60, 0.89)
        addArc(0.44, 0.35, 0.45, 0.35)
        addArc(0.61, 0.35, 0.62, 0.37)
        addArc(0.67, 0.28, 0.67, 0.26)
        addArc(0.67, 0.30, 0.67, 0.28)
        addArc(0.66, 0.33, 0.67, 0.30)
        addArc(0.62, 0.33, 0.66, 0.33)
        addArc(0.62, 0.32, 0.62, 0.33)
        addArc(0.66, 0.35, 0.67, 0.46)
        addArc(0.43, 0.36, 0.43, 0.38)
        addArc(0.66, 0.34, 0.66, 0.35)
        addArc(0.29, 0.88, 0.28, 0.92)
        addArc(0.63, 0.34, 0.63, 0.34)
        addArc(0.62, 0.36, 0.63, 0.34)
        addArc(0.62, 0.37, 0.62, 0.36)

        -- Add hair
        cmd.add(Event.arc(timing, 0.60 + xOffset, 0.89 + yOffset, timing, 0.45 + xOffset, 0.85 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.add(Event.arc(timing, 0.45 + xOffset, 0.85 + yOffset, timing, 0.34 + xOffset, 0.74 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.add(Event.arc(timing, 0.34 + xOffset, 0.74 + yOffset, timing, 0.30 + xOffset, 0.60 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.commit()
    end
)

-- // CONTEXT MACRO // --
MacroNew(
    "floony.fun", "contextmacro", 
    "Context Info", "f009",
    function(cmd)
        
        local dialogContext = {
            DialogField.create("macrocontext")
                .description(
                    "Drop Rate: " .. Context.dropRate .. " | " ..
                    "Offset: " .. Context.offset .. " | " ..
                    "Judge Density: " .. Context.timingPointDensityFactor .. " | " ..
                    "Beatline Density: " .. Context.beatlineDensity .. " | " ..
                    "Language: " .. Context.language .. "\n" ..
                    --
                    "Base BPM: " .. Context.baseBpm .. " | " ..
                    "Song Length: " .. Context.songLength .. " | " ..
                    "Max Combo: " .. Context.maxCombo .. " | " ..
                    "Note Count: " .. Context.noteCount .. "\n" ..
                    --
                    "Title: " .. tostring(Context.title) .. " | " ..
                    "Composer: " .. tostring(Context.composer) .. " | " ..
                    "Charter: " .. tostring(Context.charter) .. " | " ..
                    "Alias: " .. tostring(Context.alias)  .. "\n" ..
                    --
                    "Difficulty: " .. tostring(Context.difficulty)  .. " | " ..
                    "Difficulty Color: " .. tostring(Context.difficultyColor)  .. " | " ..
                    "Chart Path: " .. tostring(Context.chartPath)  .. " | " ..
                    "Side (Broken): " .. tostring(Context.side)  .. "\n" ..
                    --
                    "Is Light?: " .. tostring(Context.isLight)  .. " | " ..
                    "Current Arc Color: " .. Context.currentArcColor  .. " | " ..
                    "Max Arc Color: " .. Context.maxArcColor  .. "\n" ..
                    --
                    "Arc Types: " .. tostring(Context.allArcTypes)  .. " | " ..
                    "Current Arc Types: " .. tostring(Context.currentArcType)  .. " | " ..
                    "Is Trace?: " .. tostring(Context.currentIsTraceMode)  .. "\n" ..
                    --
                    "Current Timing Group: " .. tostring(Context.currentTimingGroup)  .. " | " ..
                    "Total Timing Group: " .. tostring(Context.timingGroupCount)  .. " | " ..
                    "Current Timing: " .. tostring(Context.currentTiming)  .. "\n" ..
                    --
                    "Screen Width: " .. tostring(Context.screenWidth)  .. " | " ..
                    "Screen Height: " .. tostring(Context.screenHeight)  .. " | " ..
                    "Aspect Ratio: " .. tostring(Context.screenAspectRatio)  .. " | " ..
                    "Screen Middle: " .. tostring(Context.screenMiddle)  ..  " | " ..
                    "Clipboard: " .. tostring(Context.systemClipboard) .. "\n" ..
                    --
                    "\n" ..
                    "Beat Length at: " .. tostring(Context.beatLengthAt(Context.currentTiming, Context.currentTimingGroup))  .. " | " ..
                    "BPM at: " .. tostring(Context.bpmAt(Context.currentTiming, Context.currentTimingGroup))  .. " | " ..
                    "Divisor at: " .. tostring(Context.divisorAt(Context.currentTiming, Context.currentTimingGroup))  .. " | " ..
                    "Floor Position at: " .. Context.floorPositionAt(Context.currentTiming, Context.currentTimingGroup)
                    --
                )
        }
        
        local dialogRequest = DialogInput.withTitle("Macro Context Info").requestInput(dialogContext)
    end
)

-- // TIP, HINT, TRIVIA // --
MacroNew(
    "floony.fun", "floony.chartifact", 
    "Chartifact", "e244",
    function(cmd)
        local quotes = require("floony.other.misc.chartifacts")
        local randomIndex = math.random(1, #quotes)
        local randomQuote = quotes[randomIndex]

        local dialogContent = {
            DialogField.create("hint")
                .description(randomQuote)
        }

        DialogInput.withTitle("Chartifact of the day!").requestInput(dialogContent)
    end
)