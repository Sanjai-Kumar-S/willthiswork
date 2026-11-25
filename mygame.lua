-- 1. Check if the new table is loaded in memory
print("Check V5 loaded:", _G.TradeAddConnections ~= nil)

-- 2. Rejoin or test directly without chat to verify the registry works:
-- Paste this into your executor and run it while sitting in a trade chair:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradeFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TradeFunction")

local res = TradeFunction:InvokeServer("addItem", 451, 1)
print("Direct 451 result:", res)

if res == false then
    local res2 = TradeFunction:InvokeServer("addItem", "LIGHTNINGSKINyellow", 1)
    print("Direct LIGHTNINGSKINyellow result:", res2)
end
