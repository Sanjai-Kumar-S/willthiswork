
-- =========================================================
-- BLOX FRUITS TRADE ADDER - VERSION 5
-- Direct StorageKey-based resolver
-- =========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

local TradeFunction = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("TradeFunction")

-- =========================================================
-- 1. CONFIGURATION
-- =========================================================

local COMMAND_PREFIX = "!add "
local DUPLICATE_COOLDOWN = 1.0

-- Disconnect old listeners
if _G.TradeAddConnections then
    for _, connection in ipairs(_G.TradeAddConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

_G.TradeAddConnections = {}

-- =========================================================
-- 2. ITEM STORAGE KEY REGISTRY
-- =========================================================

-- INSERT YOUR COMPLETE ItemKeys TABLE HERE.
-- Use the exact table supplied in your message.
--
-- Format:
-- local ItemKeys = {
--     ["rocket"] = "Rocket-Rocket",
--     ["perm rocket"] = "Permanent Rocket-Rocket",
--     ...
-- }
--
-- Do not add ItemIds or numeric identifiers.

-- =========================================================
-- 3. NORMALIZE INPUT
-- =========================================================

local function normalizeInput(name)
    if type(name) ~= "string" then
        return nil
    end

    name = name:lower()
    name = name:match("^%s*(.-)%s*$")
    name = name:gsub("^<(.-)>$", "%1")
    name = name:match("^%s*(.-)%s*$")

    if name == "" then
        return nil
    end

    return name
end

-- =========================================================
-- 4. RESOLVE STORAGE KEY
-- =========================================================

local function findStorageKey(rawInput)

    local query = normalizeInput(rawInput)

    if not query then
        return nil, "invalid"
    end

    -- Direct key lookup
    local storageKey = ItemKeys[query]

    if storageKey then
        return storageKey, "exact"
    end

    -- Unique partial alias matching
    local matches = {}

    for alias, key in pairs(ItemKeys) do

        if alias:find(query, 1, true) then
            matches[key] = true
        end

    end

    local count = 0
    local result

    for key in pairs(matches) do
        count += 1
        result = key
    end

    if count == 1 then
        return result, "partial"
    elseif count > 1 then
        return nil, "ambiguous"
    end

    return nil, "not_found"
end

-- =========================================================
-- 5. CHAT COMMAND HANDLER
-- =========================================================

local lastText = ""
local lastTime = 0

local function handleChatCommand(rawText)

    if type(rawText) ~= "string" then
        return
    end

    local cleanText = rawText:match("^%s*(.-)%s*$")
    local lowerText = cleanText:lower()

    if lowerText:sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then
        return
    end

    -- Duplicate command protection
    local now = os.clock()

    if lowerText == lastText
        and (now - lastTime) < DUPLICATE_COOLDOWN then
        return
    end

    lastText = lowerText
    lastTime = now

    local targetInput =
        cleanText:sub(#COMMAND_PREFIX + 1)

    local storageKey, matchType =
        findStorageKey(targetInput)

    if not storageKey then

        if matchType == "ambiguous" then
            warn(
                "[Trade] Multiple matching items:",
                targetInput,
                "| Use a more specific name."
            )
        else
            warn(
                "[Trade] Item not found:",
                targetInput
            )
        end

        return
    end

    -- =====================================================
    -- DIRECT STORAGE KEY TRADE REQUEST
    -- =====================================================

    local ok, result = pcall(function()

        return TradeFunction:InvokeServer(
            "addItem",
            storageKey,
            1
        )

    end)

    if ok then

        print(
            "[Trade] Add request sent:",
            targetInput,
            "| StorageKey:",
            storageKey,
            "| Match:",
            matchType
        )

    else

        warn(
            "[Trade] InvokeServer failed:",
            result
        )

    end

end

-- =========================================================
-- 6. CHAT LISTENER
-- =========================================================

if TextChatService
    and TextChatService.ChatVersion
        == Enum.ChatVersion.TextChatService then

    table.insert(
        _G.TradeAddConnections,

        TextChatService.MessageReceived:Connect(function(msg)

            if msg.TextSource
                and msg.TextSource.UserId == LocalPlayer.UserId then

                handleChatCommand(msg.Text)

            end

        end)
    )

else

    table.insert(
        _G.TradeAddConnections,
        LocalPlayer.Chatted:Connect(handleChatCommand)
    )

end

-- =========================================================
-- 7. READY
-- =========================================================

print("========================================")
print("[Trade] Version 5 loaded!")
print("[Trade] StorageKey-based resolver active.")
print("[Trade] Physical / Permanent / Special items")
print("[Trade] Direct key lookup enabled.")
print("[Trade] Commands: !add <item>")
print("========================================")
