-- ============================================================================
-- PaperWM Configuration - Tiling Window Manager for macOS
-- ============================================================================

PaperWM = hs.loadSpoon("PaperWM")

-- Bind default hotkeys
PaperWM:bindHotkeys({
    -- Focus windows
    focus_left  = {{"alt", "cmd"}, "left"},
    focus_right = {{"alt", "cmd"}, "right"},
    focus_up    = {{"alt", "cmd"}, "up"},
    focus_down  = {{"alt", "cmd"}, "down"},
    focus_prev = {{"alt", "cmd"}, "k"},
    focus_next = {{"alt", "cmd"}, "j"},

    -- Swap windows
    swap_left  = {{"alt", "cmd", "shift"}, "left"},
    swap_right = {{"alt", "cmd", "shift"}, "right"},
    swap_up    = {{"alt", "cmd", "shift"}, "up"},
    swap_down  = {{"alt", "cmd", "shift"}, "down"},

    -- Window sizing
    center_window = {{"alt", "cmd"}, "c"},
    full_width = {{"alt", "cmd"}, "f"},
    cycle_width = {{"alt", "cmd"}, "r"},
    reverse_cycle_width = {{"ctrl", "alt", "cmd"}, "r"},
    cycle_height = {{"alt", "cmd", "shift"}, "r"},
    reverse_cycle_height = {{"ctrl", "alt", "cmd", "shift"}, "r"},
    increase_width = {{"alt", "cmd"}, "l"},
    decrease_width = {{"alt", "cmd"}, "h"},

    -- Slurp and barf
    slurp_in = {{"alt", "cmd"}, "i"},
    barf_out = {{"alt", "cmd"}, "o"},

    -- Floating windows
    toggle_floating = {{"alt", "cmd", "shift"}, "escape"},
    focus_floating = {{"alt", "cmd", "shift"}, "f"},

    -- Focus specific window by number
    focus_window_1 = {{"cmd", "shift"}, "1"},
    focus_window_2 = {{"cmd", "shift"}, "2"},
    focus_window_3 = {{"cmd", "shift"}, "3"},
    focus_window_4 = {{"cmd", "shift"}, "4"},
    focus_window_5 = {{"cmd", "shift"}, "5"},
    focus_window_6 = {{"cmd", "shift"}, "6"},
    focus_window_7 = {{"cmd", "shift"}, "7"},
    focus_window_8 = {{"cmd", "shift"}, "8"},
    focus_window_9 = {{"cmd", "shift"}, "9"},

    -- Switch spaces
    switch_space_l = {{"alt", "cmd"}, ","},
    switch_space_r = {{"alt", "cmd"}, "."},
    switch_space_1 = {{"alt", "cmd"}, "1"},
    switch_space_2 = {{"alt", "cmd"}, "2"},
    switch_space_3 = {{"alt", "cmd"}, "3"},
    switch_space_4 = {{"alt", "cmd"}, "4"},
    switch_space_5 = {{"alt", "cmd"}, "5"},
    switch_space_6 = {{"alt", "cmd"}, "6"},
    switch_space_7 = {{"alt", "cmd"}, "7"},
    switch_space_8 = {{"alt", "cmd"}, "8"},
    switch_space_9 = {{"alt", "cmd"}, "9"},

    -- Move window to space
    move_window_1 = {{"alt", "cmd", "shift"}, "1"},
    move_window_2 = {{"alt", "cmd", "shift"}, "2"},
    move_window_3 = {{"alt", "cmd", "shift"}, "3"},
    move_window_4 = {{"alt", "cmd", "shift"}, "4"},
    move_window_5 = {{"alt", "cmd", "shift"}, "5"},
    move_window_6 = {{"alt", "cmd", "shift"}, "6"},
    move_window_7 = {{"alt", "cmd", "shift"}, "7"},
    move_window_8 = {{"alt", "cmd", "shift"}, "8"},
    move_window_9 = {{"alt", "cmd", "shift"}, "9"}
})

-- Start PaperWM
PaperWM:start()

-- ============================================================================
-- Window Border Highlight Configuration
-- Draws a temporary highlight border around windows when they gain focus
-- ============================================================================

-- Configuration
local borderWidth = 6
local borderColor = {red=0.2, green=0.6, blue=1.0, alpha=0.8}  -- Blue color
local highlightDuration = 0.5  -- Duration in seconds for the highlight effect
local fadeSteps = 20  -- Number of steps for fade animation

-- Border objects
local borders = {}
local fadeTimers = {}

-- Helper function to create a border for a window
local function createBorder(win)
    if not win then return nil end

    local frame = win:frame()
    if not frame then return nil end

    -- Create canvas for the border
    local border = hs.canvas.new({
        x = frame.x - borderWidth,
        y = frame.y - borderWidth,
        w = frame.w + (borderWidth * 2),
        h = frame.h + (borderWidth * 2)
    })

    -- Draw border rectangle
    border:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = borderColor,
        strokeWidth = borderWidth,
        roundedRectRadii = { xRadius = 8, yRadius = 8 },
    })

    -- Set level to be above window but below popup
    border:level(hs.canvas.windowLevels.overlay)
    border:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    return border
end

-- Helper function to show border with fade effect
local function showBorder(win)
    if not win then return end

    -- Clean up any existing border for this window
    local winId = win:id()
    if borders[winId] then
        if fadeTimers[winId] then
            fadeTimers[winId]:stop()
            fadeTimers[winId] = nil
        end
        borders[winId]:delete()
        borders[winId] = nil
    end

    -- Create new border
    local border = createBorder(win)
    if not border then return end

    borders[winId] = border
    border:show()

    -- Fade out animation
    local currentStep = 0
    fadeTimers[winId] = hs.timer.doEvery(highlightDuration / fadeSteps, function()
        currentStep = currentStep + 1
        local alpha = borderColor.alpha * (1 - (currentStep / fadeSteps))

        if alpha <= 0 or currentStep >= fadeSteps then
            if fadeTimers[winId] then
                fadeTimers[winId]:stop()
                fadeTimers[winId] = nil
            end
            if borders[winId] then
                borders[winId]:delete()
                borders[winId] = nil
            end
        else
            border[1].strokeColor = {
                red = borderColor.red,
                green = borderColor.green,
                blue = borderColor.blue,
                alpha = alpha
            }
        end
    end)
end

-- Window filter to watch for focus changes
local windowFilter = hs.window.filter.new()
windowFilter:setDefaultFilter{}

-- Subscribe to window focused events
windowFilter:subscribe(hs.window.filter.windowFocused, function(window)
    showBorder(window)
end)

-- Clean up on reload
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
    hs.reload()
end)

-- Notification on successful load
hs.notify.new({
    title = "Hammerspoon",
    informativeText = "PaperWM & Window highlights loaded"
}):send()

hs.alert.show("Hammerspoon loaded - PaperWM enabled")
