local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local ItemReplicationService = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
local KEYS = require(ReplicatedStorage.ItemReplicationService:WaitForChild("KEYS"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

local function findFruitItemId(targetName)
    local query = targetName:lower()
    local ownedItems = ItemReplicationService:GetItems(KEYS.IS_OWNED)

    if type(ownedItems) == "table" then
        for _, item in pairs(ownedItems) do
            if item.Value == true and item.ItemId then
                local ok, cfg = pcall(function()
                    return ItemConfig.tryGet(item.ItemId)
                end)

                if ok and type(cfg) == "table" and cfg.Display then
                    local displayName = (cfg.Display.Name or ""):lower()
                    local storageKey = (cfg.Index and cfg.Index.StorageKey or ""):lower()

                    if displayName == query or storageKey == query or displayName:find(query, 1, true) then
                        print("[Found in Inventory]:", cfg.Display.Name, "| ItemId:", item.ItemId)
                        return item.ItemId
                    end
                end
            end
        end
    end

    return nil
end

local phoenixId = findFruitItemId("phoenix")

if phoenixId then
    TradeFunction:InvokeServer("addItem", phoenixId, 1)
    print("Added Phoenix to trade table! ItemId:", phoenixId)
else
    warn("Phoenix was not found in your owned inventory!")
end
