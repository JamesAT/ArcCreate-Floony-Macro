-- NEW APIs

---@param parent string?
---@param id string
---@param displayname string
---@param func fun(cmd: Command)
function MacroNew(parent, id, displayname, icon, func)
    local cmd_name = string.format("Macro %s (%s)", displayname, parent)
    Macro.new(id)
        .withParent(parent)
        .withName(displayname)
        .withIcon(icon)
        .withDefinition(function()
            local cmd = Command.create(cmd_name)
            if func(cmd) ~= false then
                cmd.commit()
            end
        end)
        .add()
end

---@param parent string?
---@param id string
---@param displayname string
function MacroNewNOCMD(parent, id, displayname, icon, func)
    Macro.new(id)
        .withParent(parent)
        .withName(displayname)
        .withIcon(icon)
        .withDefinition(func)
        .add()
end

---@param parent string?
---@param id string
---@param displayname string
function FolderNew(parent, id, icon, displayname)
    Folder.new(id)
        .withParent(parent)
        .withName(displayname)
        .withIcon(icon)
        .add()
end

------------------------------

---@param parent string?
---@param id string
---@param displayname string
---@param func fun(cmd: Command)
function addCommandMacro(parent, id, displayname, func)

    addMacro(parent, id, displayname, function()

        local cmd = Command.create('Macro '..displayname)
        local r = func(cmd)
        if r ~= false then
            cmd.commit()
        end

    end)

end

---@param parent string?
---@param id string
---@param displayname string
---@param icon string
---@param func fun(cmd: Command)
function addCommandMacroWithIcon(parent, id, displayname, icon, func)

    addMacroWithIcon(parent, id, displayname, icon, function()

        local cmd = Command.create('Macro '..displayname)
        local r = func(cmd)
        if r ~= false then
            cmd.commit()
        end

    end)

end

-- Requests --
--- All requests should be made inside of a macro:
--- If they are not, errors will be thrown.
Request = {}

--- Request that the user select a note that meets the given constraint.
---@param constraint EventSelectionConstraint
---@param notif string?
---@return Events
function Request.note(constraint, notif)

    local req = EventSelectionInput.requestSingleEvent(constraint)

    if notif then
        notify(notif)
    end

    coroutine.yield()
    return req.result

end

--- Request that the user select an arc.
---@param notif string?
---@return LuaArc
function Request.arc(notif)
    return Request.note(EventSelectionConstraint.create().arc(), notif).arc[1]
end

--- Request that the user select a hold.
---@param notif string?
---@return LuaHold
function Request.hold(notif)
    return Request.note(EventSelectionConstraint.create().hold(), notif).hold[1]
end

--- Request that the user select a tap.
---@param notif string?
---@return LuaTap
function Request.tap(notif)
    return Request.note(EventSelectionConstraint.create().tap(), notif).tap[1]
end

--- Request that the user select a time.
---@param notif string
---@return integer
function Request.time(notif)

    local req = TrackInput.requestTiming(true, notif)

    coroutine.yield() 
    return req.result.timing

end

--- Request that the user select a time range. The returned values will be done so that the first value is the start time and the second value is the end time, regardless of selection order.
---@param notifA string? @The notification to display when selecting the first time.
---@param notifB string? @The notification to display when selecting the second time.
---@return integer, integer
function Request.timeRange(notifA, notifB)

    local a = Request.time(notifA or 'Select start time')
    local b = Request.time(notifB or 'Select end time')
    return math.min(a, b), math.max(a, b)

end

--- Request that the user select a position on the screen from the given time.
---@param t number
---@param notif string?
---@return XY
function Request.position(t, notif)

    ---@type MacroRequest
    local req = nil

    if notif then 
        req = TrackInput.requestPosition(t, notif) 
    else 
        req = TrackInput.requestPosition(t) 
    end

    coroutine.yield() 
    return xy(req.result.x, req.result.y)

end

--- Request that the user select a position on the screen from a given they also select.
---@param tnotif string?
---@param pnotif string?
---@return number, XY
function Request.timeAndPosition(tnotif, pnotif)

    local t = Request.time(tnotif)
    local pos = Request.position(t, pnotif)

    return t, pos

end

--- Request that the user input items into a dialog, then return the raw result.
---@param title string
---@param ... DialogField
---@return table
function Request.dialogRaw(title, ...)

    local arg = {...}
    local inputs = table.imap(arg, function(k, v) return resolveField(v) end)

    local req = DialogInput.withTitle(title).requestInput(inputs)

    coroutine.yield()
    
    return req.result

end

--- 
---@param title string
---@param ... DialogField
---@return ...
function Request.dialog(title, ...)

    local res = Request.dialogRaw(title, ...)
    
    local ret = {}
    for _, v in ipairs(table.pack(...)) do

        local val = res[v.key]
        
        local desc = v.fieldConstraint.getConstraintDescription()
        if string.match(desc, 'number') or 
           string.match(desc, 'integer') or
           string.match(desc, 'decimal') then
            table.insert(ret, tonumber(val))
        elseif val ~= nil then
            table.insert(ret, val)
        end

    end

    return table.unpack(ret)

end

-- Custom Constraints --
CustomConstraints = {}

---Set constraint to accept all notes between the given times
---@param tStart number
---@param tEnd number
---@return EventSelectionConstraint
function CustomConstraints.timeRange(tStart, tEnd)

    return EventSelectionConstraint.create().custom(
        function(ev)
            if ev.is 'long' then
                ---@cast ev LuaArc|LuaHold
                return ev.timing >= tStart and ev.endTiming <= tEnd
            else
                return ev.timing >= tStart and ev.timing <= tEnd
            end
        end,
        'Event must be within time range of '..tostring(tStart)..'ms to '..tostring(tEnd)..'ms'
    )

end

-- DialogField Utils --
local _saved_fields = {}

DialogFields = {}

---@param field DialogField
---@param value any
function DialogFields.save(field, value) 

    _saved_fields[field.key] = value

end

---@param field DialogField
function DialogFields.defaultToSaved(field)

    if _saved_fields[field.key] == nil then return end

    field.defaultTo(_saved_fields[field.key])

end


-- Arcade Utils --

---Notify the user of some content with a dialog (or a toast notification if a dialog cannot be created; when called from outside a macro).
---@param content string
function dialogNotify(content)

    if coroutine.running() then

        DialogInput.withTitle('Notification')
            .requestInput{
                DialogField.create('unnamed')
                    .description(content)
            }
        
        coroutine.yield()

    else

        notify(content)

    end

end

---Notify the user of some content with a customized title dialog (or a toast notification if a dialog cannot be created; when called from outside a macro).
---@param title string
---@param content string
function dialogNotifyCustom(title, content)

    if coroutine.running() then

        DialogInput.withTitle(title)
            .requestInput{
                DialogField.create('unnamed')
                    .description(content)
            }
        
        coroutine.yield()

    else

        notify(content)

    end

end

-- COLORING ARCS
local _COLORS = {6, 8, 3, 7, 2, 0, 5, 1}
function cycleColors(arcs, cmd)
    local start = table.find(_COLORS, arcs[1].color)
    for i, event in ipairs(arcs) do
        event.color = _COLORS[(i + start - 2) % #_COLORS + 1]
        cmd.add(event.save())
    end
end

-- SELECT FULL ARC
function getFullArc(arc)
    
    local n = arc
    local s = true

    local ns = {n}

    while s do
        
        local nn = Event.query(EventSelectionConstraint.create().custom(function (v)
            return v.is 'arc' and math.abs(v.timing - n.endTiming) <= 1 and (v.startX == n.endX) and (v.startY == n.endY)
        end)).arc

        if not nn[1] then
            s = false
        else
            n = nn[1]
            table.insert(ns, n)
        end

    end

    return ns

end

-- ARC SPLIT
function arcSplit(arc, cmd, output, rice)
    if output == nil then
        output = {}
    end

    if rice == nil then
        rice = false
    end

    -- Programming --
    local spliceTime = Context.beatLengthAt(arc.timing, arc.timingGroup) / Context.beatlineDensity

    local i = 0
    local lastend = nil
    for timing, endTiming in bestDivisions(arc.timing, arc.endTiming, spliceTime) do
        local startpos = lastend or arc.positionAt(timing)
        local endpos = arc.positionAt(endTiming)

        if startpos.y == endpos.y and i % 2 == 0 then
            if endpos.y <= 0 then
                endpos.y = endpos.y
            elseif forceHeightLines == true then
                endpos.y = endpos.y - 0.01
            end
        end

        if rice then
            startpos = arc.positionAt(timing)
            endpos = startpos
            timing = timing + (endTiming - timing) / 2
        end
        
        local a = Event.arc(timing, startpos, endTiming, endpos, arc.isVoid, arc.color, "s", arc.timingGroup)

        cmd.add(a.save())
        output[#output + 1] = a

        i = i + 1
        lastend = endpos
    end

    cmd.add(arc.delete())
end