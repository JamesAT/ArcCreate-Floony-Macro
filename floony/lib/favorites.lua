--Favorites.lua
--Pin the macros you use most into one folder at the top of the menu.
--  - Pin Last Macro / Pin Macro... : pin by hand
--  - Usage & Most Used...          : view usage stats, pin top macros, or reset counts

require 'floony.lib.macroUtil'

Favorites = {}

local FOLDER = 'floony.favorites'
local STORE_KEY = 'floony.favorites'
local MAX_FAVORITES = 12

--------------------------------------------------------------------------------
-- Names
--------------------------------------------------------------------------------

local function stripTags(s)
    s = tostring(s)
    s = s:gsub('<[^>]+>', '')
    return s
end

--- Name of the folder a macro lives in, without decoration, e.g. "[Split]" -> "Split".
local function folderLabel(parent)
    local f = parent and Floony.folders[parent]
    if not f then return nil end
    local n = stripTags(f.name)
    n = n:gsub('^[%[%-%s]+', '')
    n = n:gsub('[%]%-%s]+$', '')
    if n == '' then return nil end
    return n
end

local function entryLabel(id, fallbackName)
    local m = Floony.macros[id]
    local name = m and m.name or fallbackName or id
    local ctx = m and folderLabel(m.parent)
    if ctx then
        return string.format('%s <size=70%%>(%s)</size>', name, ctx)
    end
    return name
end

--------------------------------------------------------------------------------
-- Saved favorites
--------------------------------------------------------------------------------

--- Pinned favorites, in pin order: { { id = ..., name = ... }, ... }
---@return table[]
function Favorites.load()
    local str = FloonyStore.getString(STORE_KEY, '')
    local list = {}
    if type(str) == 'string' and str ~= '' then
        for line in str:gmatch('[^\r\n]+') do
            local id, name = line:match('^([^\t]+)\t?(.*)$')
            if id and id ~= '' then
                list[#list + 1] = { id = id, name = (name ~= '' and name or id) }
            end
        end
    end
    return list
end

---@param list table[]
function Favorites.save(list)
    local lines = {}
    for _, e in ipairs(list) do
        lines[#lines + 1] = e.id .. '\t' .. (e.name or e.id)
    end
    FloonyStore.setString(STORE_KEY, table.concat(lines, '\n'))
end

local function isPinned(id)
    for _, e in ipairs(Favorites.load()) do
        if e.id == id then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Shortcuts (the entries in the menu)
--------------------------------------------------------------------------------

-- Adds one shortcut macro, in `parent`, that runs the macro `id`.
local function addShortcut(parent, shortcutId, id, label, permanent)
    local m = Floony.macros[id]

    MacroNewNOCMD(parent, shortcutId, label, (m and m.icon) or 'e838',
        function()
            local target = Floony.macros[id]
            if not target then
                notifyWarn('The macro "' .. id .. '" does not exist anymore. Unpin it from Favorites.')
                return
            end
            if not permanent and not isPinned(id) then
                notifyWarn('This favorite was unpinned. Reload the macros to remove it from the menu.')
                return
            end
            return target.run()
        end,
        true -- the shortcut itself is never "the last macro"; the macro it runs is
    )
end

--- Add one shortcut macro to the Favorites folder.
---@param id string @id of the macro to run
---@param fallbackName string? @label used when that macro is not loaded
---@param permanent boolean? @true for the always-on list from floony.lua
function Favorites.registerEntry(id, fallbackName, permanent)
    local m = Floony.macros[id]
    local label = m and entryLabel(id, fallbackName) or ('(missing) ' .. tostring(fallbackName or id))
    addShortcut(FOLDER, 'floony.fav.' .. id, id, label, permanent)
end

local function removeShortcut(id)
    if Favorites.permanent and table.contains(Favorites.permanent, id) then return end
    pcall(removeMacro, 'floony.fav.' .. id)
end

--------------------------------------------------------------------------------
-- Finding macros (for Pin Macro... and Macro List)
--------------------------------------------------------------------------------

local function cleanName(name)
    local n = stripTags(name)
    n = n:gsub('^[%[%-%s]+', '')
    n = n:gsub('[%]%-%s]+$', '')
    return n
end

local function folderPath(parent)
    local names = {}
    local id, guard = parent, 0
    while id and id ~= 'floony' and guard < 12 do
        local folder = Floony.folders[id]
        if not folder then break end
        table.insert(names, 1, cleanName(folder.name))
        id = folder.parent
        guard = guard + 1
    end
    return names
end

local function listMacros()
    local list = {}
    for id, m in pairs(Floony.macros) do
        if not id:find('^floony%.fav[%._]') then
            local folders = folderPath(m.parent)
            local rest = {}
            for i = 2, #folders do rest[#rest + 1] = folders[i] end

            list[#list + 1] = {
                id = id,
                name = string.trim(stripTags(m.name)),
                section = folders[1] or 'Main menu',
                path = table.concat(rest, ' > '),
            }
        end
    end

    table.sort(list, function(a, b)
        if a.section ~= b.section then return a.section < b.section end
        if a.path ~= b.path then return a.path < b.path end
        return a.name:lower() < b.name:lower()
    end)
    return list
end

local function listSections(macros)
    local names, seen = {}, {}
    for _, e in ipairs(macros) do
        if not seen[e.section] then
            seen[e.section] = true
            names[#names + 1] = e.section
        end
    end
    table.sort(names)
    return names
end

local function labelOf(e)
    local path = (e.path ~= '') and (e.path .. ' > ') or ''
    return string.format('%s%s  [%s]', path, e.name, e.id)
end

--------------------------------------------------------------------------------
-- Pinning
--------------------------------------------------------------------------------

local function pinMacro(id)
    local m = Floony.macros[id]
    if not m then
        notifyWarn('That macro is not loaded.')
        return false
    end

    local list = Favorites.load()
    for _, e in ipairs(list) do
        if e.id == id then
            notifyWarn('"' .. stripTags(m.name) .. '" is already pinned.')
            return false
        end
    end

    if #list >= MAX_FAVORITES then
        notifyWarn('Favorites is full (' .. MAX_FAVORITES .. '). Unpin one first.')
        return false
    end

    list[#list + 1] = { id = id, name = m.name }
    Favorites.save(list)

    pcall(Favorites.registerEntry, id, m.name, false)
    notify('Pinned "' .. stripTags(m.name) .. '". It is saved and stays after reloads.')
    return true
end

local function pin()
    local last = Floony.lastRun
    if not last then
        notifyWarn('Run a macro first, then use "Pin Last Macro" to pin it.')
        return
    end
    pinMacro(last.id)
end

local function pickAndPin()
    local macros = listMacros()
    local sections = listSections(macros)
    if #sections == 0 then
        notifyWarn('No macros found.')
        return
    end

    local r1 = Request.dialogRaw('Pin Macro (1 of 2)',
        DialogField.create('section')
            .setLabel('Section')
            .setTooltip('The part of the menu the macro is in.')
            .dropdownMenu(table.unpack(sections))
    )
    if not r1 then return end
    local section = sections[choiceIndex(r1['section'], sections)]

    local items, options = {}, {}
    for _, e in ipairs(macros) do
        if e.section == section and not isPinned(e.id) then
            items[#items + 1] = e
            options[#options + 1] = labelOf(e)
        end
    end
    if #items == 0 then
        notifyWarn('Everything in "' .. section .. '" is already pinned.')
        return
    end

    local r2 = Request.dialogRaw('Pin Macro (2 of 2): ' .. section,
        DialogField.create('macro')
            .setLabel('Macro')
            .setTooltip('The id is shown in [brackets].')
            .dropdownMenu(table.unpack(options))
    )
    if not r2 then return end

    pinMacro(items[choiceIndex(r2['macro'], options)].id)
end

local function unpin()
    local list = Favorites.load()
    if #list == 0 then
        notifyWarn('There are no pinned favorites.')
        return
    end

    local options = {}
    for i, e in ipairs(list) do
        options[i] = string.format('%d: %s', i, stripTags(entryLabel(e.id, e.name)))
    end
    local removeAll = '* Remove all'
    options[#options + 1] = removeAll

    local r = Request.dialogRaw('Unpin Favorite',
        DialogField.create('which')
            .setLabel('Unpin')
            .dropdownMenu(table.unpack(options)),
        DialogField.create('note')
            .description('Unpinned entries are removed from the menu right away.')
    )
    if not r then return end

    local index = choiceIndex(r['which'], options)

    if options[index] == removeAll then
        for _, e in ipairs(list) do removeShortcut(e.id) end
        Favorites.save({})
        notify('All favorites were unpinned.')
        return
    end

    if list[index] then
        local removed = table.remove(list, index)
        Favorites.save(list)
        removeShortcut(removed.id)
        notify('Unpinned "' .. stripTags(removed.name) .. '".')
        return
    end

    notifyWarn('Nothing was unpinned.')
end

--------------------------------------------------------------------------------
-- Usage & Most Used (Combined View, Pinning, & Reset)
--------------------------------------------------------------------------------

local function showUsage()
    if not FloonyUsage then
        notifyWarn('Usage counting is not available.')
        return
    end

    local top = FloonyUsage.top(15)
    local lines = {}

    if #top == 0 then
        lines[1] = 'Nothing counted yet. Run some macros first!'
    else
        lines[1] = '<b>Most Used Macros</b>'
        for i, e in ipairs(top) do
            local pinnedTag = isPinned(e.id) and ' <size=70%>(Pinned)</size>' or ''
            lines[#lines + 1] = string.format('%d. %s <size=75%%>x%d</size>%s', i, stripTags(entryLabel(e.id)), e.count, pinnedTag)
        end
        lines[#lines + 1] = ''
        lines[#lines + 1] = string.format('<size=80%%>%d unique macro(s) tracked in total.</size>', FloonyUsage.size())
    end

    local options = { 'Do nothing' }
    local actionMap = {}

    -- Build dropdown options to pin top unpinned macros
    for _, e in ipairs(FloonyUsage.top(5)) do
        if not isPinned(e.id) then
            local optLabel = string.format('Pin: %s (x%d)', stripTags(entryLabel(e.id)), e.count)
            options[#options + 1] = optLabel
            actionMap[#options] = { type = 'pin', id = e.id }
        end
    end

    local resetOpt = '* Reset usage counts'
    options[#options + 1] = resetOpt
    actionMap[#options] = { type = 'reset' }

    local r = Request.dialogRaw('Usage & Most Used',
        DialogField.create('list').description(table.concat(lines, '\n')),
        DialogField.create('action')
            .setLabel('Action')
            .setTooltip('Pin a top macro to Favorites, or reset usage counts.')
            .defaultTo(options[1])
            .dropdownMenu(table.unpack(options))
    )
    if not r then return end

    local idx = choiceIndex(r['action'], options)
    local action = actionMap[idx]

    if action then
        if action.type == 'reset' then
            FloonyUsage.reset()
            notify('The usage counts were reset.')
        elseif action.type == 'pin' then
            pinMacro(action.id)
        end
    end
end

--------------------------------------------------------------------------------
-- Macro List
--------------------------------------------------------------------------------

local MAX_LIST_LINES = 45

local function showMacroList()
    local macros = listMacros()
    local options = { 'All sections' }
    for _, name in ipairs(listSections(macros)) do options[#options + 1] = name end

    local r = Request.dialogRaw('Macro List',
        DialogField.create('section')
            .setLabel('Show')
            .setTooltip('Pick one section to see all of its macros.')
            .dropdownMenu(table.unpack(options))
    )
    if not r then return end

    local choice = choiceIndex(r['section'], options)
    local wanted = (choice > 1) and options[choice] or nil

    local shown, copy, current = {}, {}, nil
    for _, e in ipairs(macros) do
        if not wanted or e.section == wanted then
            if e.section ~= current then
                current = e.section
                shown[#shown + 1] = '<b>' .. e.section .. '</b>'
            end
            local path = (e.path ~= '') and (e.path .. ' > ') or ''
            shown[#shown + 1] = string.format('  %s%s <size=75%%>[%s]</size>', path, e.name, e.id)
            copy[#copy + 1] = string.format("'%s',  -- %s > %s%s", e.id, e.section, path, e.name)
        end
    end

    local text = {}
    for i = 1, math.min(#shown, MAX_LIST_LINES) do text[i] = shown[i] end
    if #shown > MAX_LIST_LINES then
        text[#text + 1] = string.format('...and %d more lines. Pick one section to see them all.', #shown - MAX_LIST_LINES)
    end

    local copied = pcall(function() Context.systemClipboard = table.concat(copy, '\n') end)
    if copied then
        text[#text + 1] = ''
        text[#text + 1] = '<size=80%>All ids were copied to the clipboard, ready to paste into PERMANENT_FAVORITES.</size>'
    end

    dialogNotify(table.concat(text, '\n'), 'Macro List')
end

--------------------------------------------------------------------------------
-- Help
--------------------------------------------------------------------------------

local function help()
    dialogNotify(
        '<b>Favorites</b>\n' ..
        'Ways to pin a macro:\n' ..
        '1. <b>Usage & Most Used...</b>: view top used macros and pin them directly from the dropdown.\n' ..
        '2. <b>Pin Macro...</b>: pick any macro from a list by section.\n' ..
        '3. Run any macro once, then run <b>Pin Last Macro</b>.\n' ..
        '\n' ..
        'Pins are saved automatically and survive reloads and restarts.\n' ..
        'Use <b>Unpin...</b> to remove one; it leaves the menu immediately.\n' ..
        '<b>Macro List</b> shows every macro with its id.\n' ..
        '\n' ..
        'Want shortcuts that are always there? Edit <b>PERMANENT_FAVORITES</b> at the top of floony.lua ' ..
        'and list the macro ids (Macro List copies them for you), e.g. { "split_normal", "filtersel" }.',
        'How Favorites Work'
    )
end

--------------------------------------------------------------------------------
-- Building the folder
--------------------------------------------------------------------------------

function Favorites.createFolder()
    FolderNew('floony', FOLDER, 'e838', '- Favorites -')
end

function Favorites.build(permanentIds)
    permanentIds = permanentIds or {}
    Favorites.permanent = permanentIds
    local seen = {}

    for _, e in ipairs(Favorites.load()) do
        if not seen[e.id] then
            seen[e.id] = true
            local isPerm = table.contains(permanentIds, e.id)
            Favorites.registerEntry(e.id, e.name, isPerm)
        end
    end

    for _, id in ipairs(permanentIds) do
        if not seen[id] then
            if Floony.macros[id] then
                seen[id] = true
                Favorites.registerEntry(id, id, true)
            else
                Floony.loadErrors[#Floony.loadErrors + 1] = {
                    module = 'PERMANENT_FAVORITES',
                    err = 'unknown macro id "' .. tostring(id) .. '"',
                }
            end
        end
    end

    MacroNewNOCMD(FOLDER, 'floony.fav_pin', 'Pin Last Macro', 'e838', pin, true)
    MacroNewNOCMD(FOLDER, 'floony.fav_pick', 'Pin Macro...', 'e145', pickAndPin, true)
    MacroNewNOCMD(FOLDER, 'floony.fav_unpin', 'Unpin...', 'e5cd', unpin, true)
    MacroNewNOCMD(FOLDER, 'floony.fav_usage', 'Usage & Most Used...', 'e8e5', showUsage, true)
    MacroNewNOCMD(FOLDER, 'floony.fav_list', 'Macro List', 'e896', showMacroList, true)
    MacroNewNOCMD(FOLDER, 'floony.fav_help', 'How Favorites Work', 'e8fd', help, true)
end