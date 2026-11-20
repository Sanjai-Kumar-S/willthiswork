local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

-- Build a quick lookup of owned ItemIds
local ownedSet = {}
local okOwned, ownedItems = pcall(function()
    return ItemReplicationService:GetItems(KEYS.IS_OWNED)
end)
if okOwned and type(ownedItems) == "table" then
    for _, item in pairs(ownedItems) do
        if type(item) == "table" and item.ItemId and (item.Value == true or (type(item.Value) == "number" and item.Value > 0)) then
            ownedSet[item.ItemId] = true
        end
    end
end

-- Scan all ItemIds in ItemConfig (1 to 3000) regardless of ownership
local allEntries = {}
for id = 1, 3000 do
    local ok, cfg = pcall(ItemConfig.tryGet, id)
    if ok and type(cfg) == "table" and cfg.Display then
        local dName = tostring(cfg.Display.Name or "nil")
        local sKey = tostring((cfg.Index and cfg.Index.StorageKey) or "nil")
        local iType = tostring((cfg.Index and cfg.Index.Type) or cfg.Type or "nil")
        local ownedTag = ownedSet[id] and "OWNED" or "UNOWNED"

        local line = string.format("[%s] Id=%d | Type=%s | Display=%s | Key=%s", ownedTag, id, iType, dName, sKey)
        print(line)
        table.insert(allEntries, line)
    end
end

-- Copy the full dump to your clipboard automatically if supported
if typeof(setclipboard) == "function" then
    setclipboard(table.concat(allEntries, "\n"))
    print(string.format("[Dump] Copied %d total registry items to clipboard!", #allEntries))
end
