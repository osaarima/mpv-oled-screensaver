local assdraw = require "mp.assdraw"
local options = require "mp.options"

local o = {
    startAfter = 10,
    screensaverColor = "000000",
    rainbow = false,
    rainbowStep = 1,
    rainbowRedrawPrediod = 0.03,
    alphaStep = 12,
    luminance = 255,
    mouseMovementClears = true,
}

local state = {
    startScreensaverAfterTimer = nil,
    mouseMovementTimer = nil,
    drawScreensaverTimer = nil,
    lastMouseXPos = nil,
    lastMouseYPos = nil,
    colour = {o.luminance, 0, 0}, -- RGB
    alpha = 255,
    paused = false,
    fullscreen = false,
    ignore_clear_once = false,
}

options.read_options(o)

function changeColour(num, op)
    if op == "+" then
        state.colour[num] = state.colour[num] + o.rainbowStep
        if state.colour[num] > o.luminance then
            state.colour[num] = o.luminance
        end
    elseif op == "-" then
        state.colour[num] = state.colour[num] - o.rainbowStep
        if state.colour[num] < 0 then
            state.colour[num] = 0
        end
    end
end

function alphaHex()
    if state.alpha > 0 then
        state.alpha = state.alpha - o.alphaStep
        if state.alpha < 0 then
            state.alpha = 0
        end
    end

    return string.format("%02x", state.alpha)
end

function rainbowHex()
    if state.colour[1] >= o.luminance and state.colour[2] < o.luminance and state.colour[3] <= 0 then
        changeColour(2, "+")
    elseif state.colour[1] > 0 and state.colour[2] >= o.luminance and state.colour[3] <= 0 then
        changeColour(1, "-")
    elseif state.colour[1] <= 0 and state.colour[2] >= o.luminance and state.colour[3] < o.luminance then
        changeColour(3, "+")
    elseif state.colour[1] <= 0 and state.colour[2] > 0 and state.colour[3] >= o.luminance then
        changeColour(2, "-")
    elseif state.colour[1] < o.luminance and state.colour[2] <= 0 and state.colour[3] >= o.luminance then
        changeColour(1, "+")
    elseif state.colour[1] >= o.luminance and state.colour[2] <= 0 and state.colour[3] > 0 then
        changeColour(3, "-")
    end

    -- ASS Sub colours BBGGRR
    return string.format("%02x%02x%02x", state.colour[3], state.colour[2], state.colour[1])
end

function startScreensaver()
    state.drawScreensaverTimer:resume()
    if o.mouseMovementClears then
        mp.add_forced_key_binding("mouse_move", "screensaver_mouse_move", clearEvent)
    end
    state.mouseMovementTimer:kill()
end

function drawScreensaver()
    local colour = o.screensaverColor
    if o.rainbow == true then
        colour = rainbowHex()
    elseif state.alpha < 1 then
        state.drawScreensaverTimer:kill()
    end

    local w, h = mp.get_osd_size()
    ass = assdraw.ass_new()
    ass:new_event()
    ass:append("{\\c&H" .. colour .. "&}")
    ass:append("{\\{\\bord0}")
    ass:append("{\\shad0}")
    ass:append("{\\1a&H" .. alphaHex() .. "&}")
    ass:append("{\\2a&HFF&}")
    ass:append("{\\3a&HFF&}")
    ass:append("{\\4a&HFF&}")
    ass:pos(-1, -1)
    ass:draw_start()
    ass:rect_cw(0, 0, w+2, h+2)
    ass:draw_stop()
    mp.set_osd_ass(w, h, ass.text)
end

function clearScreensaver()
    state.startScreensaverAfterTimer:kill()
    state.drawScreensaverTimer:kill()
    state.mouseMovementTimer:kill()
    state.alpha = 255
    mp.set_osd_ass(0, 0, "")
    mp.remove_key_binding("screensaver_mouse_move")
end

function checkMouseMovement()
    local x, y = mp.get_mouse_pos()
    if x == state.lastMouseXPos or y == state.lastMouseYPos then
        state.startScreensaverAfterTimer:resume()
    else
        state.startScreensaverAfterTimer:kill()
    end
    state.lastMouseXPos = x
    state.lastMouseYPos = y
end

function clearEvent(name, clear)
    if not state.ignore_clear_once then
        clearScreensaver()
        if state.paused and state.fullscreen then
            state.mouseMovementTimer:resume()
        end
    else
        state.ignore_clear_once = false
    end
end

function fullscreenEvent(name, fs)
    state.fullscreen = fs
    updateState()
end

function pauseEvent(name, pause)
    state.paused = pause
    updateState()
end

function updateState()
    if state.paused and state.fullscreen then
        state.mouseMovementTimer:resume()
    else
        clearScreensaver()
    end
end

function pauseAndStartScreensaver()
    -- Need to ignore clearing command once because otherwise
    -- pause and fullscreen interrups the screensaver
    -- immediately in clearEvent
    state.ignore_clear_once = true
    mp.set_property_bool("pause",true)
    mp.set_property_bool("fullscreen",true)
    state.paused = true
    state.fullscreen = true
    startScreensaver()
end

function checkAndStartScreensaver()
    if state.paused and state.fullscreen then
        startScreensaver()
    end
end

state.startScreensaverAfterTimer = mp.add_timeout(o.startAfter, startScreensaver)
state.startScreensaverAfterTimer:kill()
state.drawScreensaverTimer = mp.add_periodic_timer(o.rainbowRedrawPrediod, drawScreensaver)
state.drawScreensaverTimer:kill()
state.mouseMovementTimer = mp.add_periodic_timer(0.5, checkMouseMovement)
state.mouseMovementTimer:kill()

mp.observe_property("pause", "bool", pauseEvent)
mp.observe_property("fullscreen", "bool", fullscreenEvent)
mp.observe_property("seeking", "bool", clearEvent)

mp.add_key_binding("", "pause_and_start_screensaver", pauseAndStartScreensaver)
mp.add_key_binding("", "start_screensaver", checkAndStartScreensaver)