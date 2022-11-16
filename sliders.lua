local sliders = {}
local monitor = nil

function setMonitor(side)
    if fs.exists("wpp") then
        monitor = side
    else
        monitor = peripheral.wrap(side)
    end
    if not (monitor.isColor()) then
        error("Monitor Doesn't Support Colors")
    end
end

function createSlider(name, x, y, length, height, sliderColor, barColor)

    -- Checks if name is not unique
    for k,v in pairs(sliders) do
        if name == k then
            error(name " already exist!")
        end
    end

    -- Optional values are put
    if sliderColor == nil then
        sliderColor = colors.gray
    end
    if barColor == nil then
        barColor = colors.white
    end

    -- fills in values
    sliders[name] = {}
    sliders[name]["x"] = x
    sliders[name]["y"] = y
    sliders[name]["length"] = length
    sliders[name]["height"] = height
    sliders[name]["sliderColor"] = sliderColor
    sliders[name]["barColor"] = barColor
    sliders[name]["value"] = 0
    sliders[name]["textColor"] = colors.black
end

-- This functions sets the value of the slider.
function updateSlider(name, value)
    if value > 100 then
        error(name ": Value can not be over 100!")
    elseif value < 0 then
        error(name ": Value can not be under 0!")
    end

    for k,v in pairs(sliders) do
        if k == name then
            sliders[name]["value"] = value
        end
    end
end

function draw(name, drawText)

    -- Sets default monitor to the term and checks if it supports color (is an advanced machine)

    if monitor == nil then
        monitor = term
        if not (monitor.isColor()) then
            error("Monitor doesn't support Colors")
        end
    end

    -- Checks if the arguments are set, if not do default
    if not (type(name) == "table") then
        if not (type(name) == "string") then
            name = {}
            for k,v in pairs(sliders) do
                table.insert(name,k)
            end
        else
            name = {name}
        end
    end

    if drawText == nil then
        drawText = true;
    end

    for k,v in pairs(sliders) do
        for s = 0, #name+1 do
            if k == name[s] then

                percentDraw = v.length * (v.value / 100)
                    for yPos = v.y, v.y + v.height - 1 do

                        monitor.setBackgroundColor(v.barColor)
                        monitor.setCursorPos(v.x, yPos)
                        monitor.write(string.rep(" ", v.length))

                        monitor.setCursorPos(v.x, yPos)
                        monitor.setBackgroundColor(v.sliderColor)
                        monitor.write(string.rep(" ", percentDraw))

                        if drawText == true then
                            textX = math.floor(v.x + (v.length/2)-1)
                            textY = math.floor(v.y + v.height - (v.height/2))
                            text = math.floor(v.value) .. "%"

                            monitor.setCursorPos(textX,textY)
                            monitor.setTextColor(v.textColor)

                            for i = 0, #text do
                                if percentDraw >= v.length/2 and i == 1 then
                                    monitor.setBackgroundColor(v.sliderColor)
                                    monitor.write(string.sub(text,i,i))
                                elseif percentDraw >= math.floor(v.length/2+1) and i <= 2 then
                                    monitor.setBackgroundColor(v.sliderColor)
                                    monitor.write(string.sub(text,i,i))
                                elseif percentDraw >= math.floor(v.length/2+2) and i <= 3 then
                                    monitor.setBackgroundColor(v.sliderColor)
                                    monitor.write(string.sub(text,i,i))
                                elseif percentDraw >= math.floor(v.length/2+3) and i <= 4 then
                                    monitor.setBackgroundColor(v.sliderColor)
                                    monitor.write(string.sub(text,i,i))
                                else
                                    monitor.setBackgroundColor(v.barColor)
                                    monitor.write(string.sub(text,i,i))
                                end
                            end
                        end
                    end
                end
            end

        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.white)
        monitor.setCursorPos(1,1)
             
    end
end