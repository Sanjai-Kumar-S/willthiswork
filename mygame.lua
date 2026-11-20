local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local COMMAND_PREFIX = "!add "

local function findFruitItemId(targetName)
    local query = targetName:lower():match("^%s*(.-)%s*$")
    if query == "" then return nil end

    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)
    if type(ownedItems) ~= "table" then return nil end

    for _, item in pairs(ownedItems) do
        if item.Value == true and item.ItemId then
            local ok, cfg = pcall(function()
                return ItemConfig.tryGet(item.ItemId)
            end)

            if ok and type(cfg) == "table" and cfg.Display then
                local displayName = (cfg.Display.Name or ""):lower()
                local storageKey = (cfg.Index and cfg.Index.StorageKey or ""):lower()

                if displayName == query or storageKey == query or displayName:find(query, 1, true) then
                    return item.ItemId, cfg.Display.Name
                end
            end
        end
    end

    return nil
end

local function handleChatCommand(rawText)
    if type(rawText) ~= "string" then return end
    
    local lowerText = rawText:lower()
    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

    local targetFruit = rawText:sub(#COMMAND_PREFIX + 1)
    local itemId, resolvedName = findFruitItemId(targetFruit)

    if itemId then
        local ok, err = pcall(function()
            TradeFunction:InvokeServer("addItem", itemId, 1)
        end)
        if ok then
            print("[Trade] Added:", resolvedName, "| ItemId:", itemId)
        else
            warn("[Trade] InvokeServer failed:", err)
        end
    else
        warn("[Trade] Fruit not found in inventory:", targetFruit)
    end
end

-- Legacy chat fallback
LocalPlayer.Chatted:Connect(handleChatCommand)

-- Modern TextChatService listener
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource and textChatMessage.TextSource.UserId == LocalPlayer.UserId then
            handleChatCommand(textChatMessage.Text)
        end
    end)
end

print("[Trade] Chat listener active. Type '!add <fruit>' while seated at a trade table.")
