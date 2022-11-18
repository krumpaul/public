--ae2trasher


local checkFrequency = 15 -- How often inventory levels are checked in seconds.  Overridden by passing as the first argument.
local trashFileName = "trasher/trash_list.txt" -- Change this if you want the file somewhere else.
local useProgressBar = true -- Set to true or false depending if you want TEXT or Progress Bar output.
local wppnetwork = "base"
local wppmonitor = "wpp@base://14/monitor_17"
local wppmebridge = "wpp@base://15/meBridge_4"
local trashcan = "wpp@base://15/cyclic_trash_0"
local sliderBackgroundDefault = colors.gray
local sliderForegroundDefault = colors.red
local sliderBarHeightDefault = 3

-- --------------
-- CHECK AND INSTALL REQUIREMENTS
-- --------------
--slider
if (useProgressBar == true) then
    if fs.exists("sliders") then 
      os.loadAPI("sliders")
    else
      print("Downloading sliders library...")
      shell.run("wget https://raw.githubusercontent.com/krumpaul/public/main/sliders.lua sliders")
      os.loadAPI("sliders")
    end
end
--wpp
if (wppnetwork or wppmebridge) then
  if fs.exists("wpp") then
    wpp = require("/wpp")
  else
    print("Downloading wpp library...")
    shell.run("wget https://raw.githubusercontent.com/krumpaul/public/main/wpp.lua wpp")
    wpp = require("/wpp")
  end
    print("connecting to WPP Network:", wppnetwork)
    wpp.wireless.connect(wppnetwork)
end
--trashfile
if fs.exists(trashFileName) then
    -- do nothing
  else
    print("Downloading trash file")
    if fs.exists("/trasher") then
     -- do nothing
    else
        shell.run("mkdir", "/trasher")
        shell.run("wget https://raw.githubusercontent.com/krumpaul/public/main/trasher/trash_list.txt wpp")
    end
end

-- --------------
-- MISC FUNCTIONS
-- --------------
  function loadTrashFile(mon, trashFileName, ...)
    local trashFile = fs.open(trashFileName, "r")
    local trashFileContents = trashFile.readAll();
    trashFile.close();
    local outputTrash = textutils.unserialize(trashFileContents)
    srow = 2
    row = 1
    header_shown = 0
    for e in pairs(outputTrash) do
        item = outputTrash[e]
        if header_shown == 0 then
            --if wppnetwork then monitor = wpp.peripheral.wrap(wppmonitor) end
            --mPrintRowJustified(mon, row, "left", "REQUESTS")
            header_shown = 1
            row = row + 1
            srow = srow + 1
        end
        text = string.format("%s %s %d",item.displayName ,":", item.minQuantity)
        if useProgressBar == true then
          sliderbarSetup(mon, item.displayName, 0, srow, 0, 1, colors.gray, colors.green)
          srow = srow + 2
          row = row + 2
        else
          --if wppnetwork then monitor = wpp.peripheral.wrap(wppmonitor) end
          mPrintRowJustified(mon, row, "left", text, colors.white, ...)
          row = row + 1
        end
    end

    assert(#outputTrash > 0, "There are no entries in the " .. trashFileName .. " file.")
    return outputTrash
end

-- --------------
-- MONITOR FUNCTIONS
-- --------------
function sliderbarSetup(mon, itemname, x, y, width, height, background, foreground)
    w, h = mon.getSize()
    if width == 0 then width = w end
    if x == 0 then x = 1 end
    if height == 0 then height = sliderBarHeightDefault end
    sliders.setMonitor(mon)
    sliders.createSlider(itemname, x, y, width, height, foreground, background)
  end
  
  function sliderbarupdate(slidername, maxval, curval)
    local itempercent = 0 
    if curval > maxval then
      itempercent = 100;
    else
      itempercent = math.floor((curval / maxval) * 100)
    end
    sliders.updateSlider(slidername, itempercent)
  end

  function mPrintRowJustified(mon, y, pos, text, ...)
    w, h = mon.getSize()
    fg = mon.getTextColor()
    bg = mon.getBackgroundColor()

    if pos == "left" then x = 1 end
    if pos == "center" then x = math.floor((w - #text) / 2) end
    if pos == "right" then x = w - #text end

    if #arg > 0 and #arg < 4 then mon.setTextColor(arg[1]) end
    if #arg > 1 and #arg < 4 then mon.setBackgroundColor(arg[2]) end
    --mPrintRowJustified(mon, row, "right", text, color)
    -- mPrintRowJustified(mon,row, "right", " ", length, minVal, maxVal, colors.gray, colors.green)
    if #arg > 3 then 
        mon.setBackgroundColor(bg)
        progress_bar(mon, x, y, arg[1], arg[2], arg[3], arg[4], arg[5])
    else
        mon.setCursorPos(x, y)
        mon.write(text)
        mon.setTextColor(fg)
        mon.setBackgroundColor(colors.black)
    end

end

-- --------------
-- MAIN FUNCTIONS
-- --------------
function trashitems(mon, trash, trashperi, ... )
    row = 1
    header_shown = 0
    if header_shown == 0 then
        if row > 1 then row = row + 1 end
        if wppnetwork then monitor = wpp.peripheral.wrap(wppmonitor) end
        mPrintRowJustified(mon, row, "center", "ITEMS TO TRASH")
        header_shown = 1
        row = row + 1
    end
    for i=1, #trash do
      if useProgressBar == true then
        color = colors.white
      else
        color = colors.green
      end
        --print("Checking inventory for", trash[i].displayName)
        --if wppnetwork then ae2 = wpp.peripheral.wrap(wppmebridge) end
        item = (ae2.getItem({ name = trash[i].itemId}))
        if (item == nil or item == '') then 
            item = {name = trash[i].itemId, amount = 0}
        end
        if item.amount > trash[i].maxQuantity then
            color = colors.red
            print("Would have trashed: " .. item.name .. " batch size: " .. trash[i].batchSize .. " want to get to: " .. trash[i].maxQuantity .. " currently have: " .. item.amount )
            ae2.exportItem({name = item.name, count = trash[i].batchSize}, trashperi)
            --print("Crafting Required for:", trash[i].displayName)
            --if wppnetwork then ae2 = wpp.peripheral.wrap(wppmebridge) end
            --craftingstatus = ae2.isItemCrafting(item)
            --if craftingstatus then color = colors.orange end
        
            --if ( ae2.isItemCraftable(item) and not craftingstatus and isCpuAvailable(mon, ae2)  ) then
            --    --print(trash[i].batchSize, trash[i].displayName, "sent for crafting")
            --    color = colors.orange
            --    if wppnetwork then ae2 = wpp.peripheral.wrap(wppmebridge) end
            --    ae2.craftItem({name = item.name, count = trash[i].batchSize})
            --end
        end
        --if wppnetwork then monitor = wpp.peripheral.wrap(wppmonitor) end
        if useProgressBar == true then
          text = string.format("%s", trash[i].displayName) -- Stone 5000/5001
          text2 = string.format("%s", "    " .. item.amount .. "/" .. trash[i].minQuantity) -- Stone 5000/5001
          mPrintRowJustified(mon, row, "left", text, color, ...) -- PRINT NAME
          mPrintRowJustified(mon, row, "right", text2, color, ...) -- PRINT AMOUNT
          sliderbarupdate(trash[i].displayName, trash[i].minQuantity, item.amount)
          row = row + 2
        else
          text = string.format("%s %s", trash[i].displayName .. ":", item.amount .. "/" .. trash[i].minQuantity) -- Stone 5000/5001
          mPrintRowJustified(mon, row, "right", text, color)
          row = row + 1
        end
    end
    if useProgressBar == true then sliders.draw() end
end

function main()
    -- --------------
    -- SETUP
    -- --------------
    --
    -- Initialize Monitor
    monitor = peripheral.find("monitor")
    if (not monitor and wppnetwork)  then
        print("trying WPP monitor")
        monitor = wpp.peripheral.wrap(wppmonitor)
        if not monitor then 
            error("Monitor Not Found.")
        else
            monitor.setTextScale(0.5)
            monitor.clear()
            monitor.setCursorPos(1, 1)
            monitor.setCursorBlink(false)
            print("Monitor initialized.")
            if (useProgressBar == true) then  end
        end
    end
    -- Initialize RS Bridge
    ae2 = peripheral.find("meBridge")
    if (not ae2 and wppnetwork) then
        print("trying WPP bridge")
        ae2 = wpp.peripheral.wrap(wppmebridge)
    end
    if (not ae2 and not wppnetwork)  then 
        error("ME Bridge not found.")
    else
        print("ME Bridge initialized. Assuming AE2 with WPP glitch")
    end
    -- Initialize TrashCan
    trashperi = peripheral.find(trashcan)
    if (not trashperi and wppnetwork) then
        print("trying WPP bridge")
        trashperi = wpp.peripheral.wrap(trashcan)
    end
    if (not trashperi and not wppnetwork)  then 
        error("Trashcan not found.")
    else
        print("Trash initialized.")
    end
    -- --------------
    -- LOAD TRASH FILE
    -- --------------
    local trash = loadTrashFile(monitor, trashFileName)


    while (true) do
        print("[" .. getDisplayTime() .. "] Checking inventory.")
        --if wppnetwork then monitor = wpp.peripheral.wrap(wppmonitor) end
        --if wppnetwork then ae2 = wpp.peripheral.wrap(wppmebridge) end
        trashitems(monitor, trash, trashperi )
        os.sleep(checkFrequency)
    end



end



  main()
