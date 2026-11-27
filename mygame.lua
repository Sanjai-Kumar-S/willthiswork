-- =========================================
-- BLOX FRUITS SCRIPT - EMERGENCY STOP
-- Does NOT reset or kill your character
-- =========================================

_G.ScriptRunning = false
_G.StopScript = true

-- Disconnect tracked connections
if _G.ScriptConnections then
    for _, connection in pairs(_G.ScriptConnections) do
        if typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
end

_G.ScriptConnections = {}

-- Stop tracked running threads
if _G.ScriptThreads then
    for _, thread in pairs(_G.ScriptThreads) do
        pcall(function()
            task.cancel(thread)
        end)
    end
end

_G.ScriptThreads = {}

print("[Emergency Stop] Script shutdown requested.")
print("[Emergency Stop] Character was NOT reset.")
