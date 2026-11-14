local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local function getPhoenixItemId()
    local ok, result = pcall(function()
        local ItemReplication = require(ReplicatedStorage:WaitForChild("ItemReplicationService"))
        local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

        local ownedItems = ItemReplication.GetItems(ItemReplication.KEYS.IS_OWNED)
        local quantities = ItemReplication.GetItems(ItemReplication.KEYS.QUANTITY)

        for _, item in ipairs(ownedItems) do
            local count = quantities[item.ItemId] or 1
            if item.Value and count > 0 then
                local configData = ItemConfig.tryGet(item.ItemId)
                if configData and configData.Display and configData.Display.Name then
                    if configData.Display.Name:lower() == "phoenix" then
                        return item.ItemId
                    end
                end
            end
        end
        return nil
    end)

    if ok and result then
        return result
    end

    -- Fallback storage key if ItemReplicationService doesn't return an ID
    return "Phoenix-Phoenix"
end

-- Find Phoenix in inventory and add 1 copy to the active trade window
local phoenixId = getPhoenixItemId()
print("Adding Phoenix to trade table with ID:", tostring(phoenixId))
TradeFunction:InvokeServer("addItem", phoenixId, 1)
