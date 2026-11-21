local WEBHOOK = "https://discord.com/api/webhooks/1573609152549224509/TgrDN2kKASX7-U6mNDfxTZPpzGMXgG5NpzBjH9lGeS3-MDjFmp2aOS6vgUOCKDSBb_WK"
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local LP = game:GetService("Players").LocalPlayer
local req = request or http_request or (http and http.request) or (syn and syn.request)

local function post(body, ctype)
    if not req then return 0, "no_req" end
    local ok, r = pcall(req, {
        Url = WEBHOOK,
        Method = "POST",
        Headers = { ["Content-Type"] = ctype },
        Body = body
    })
    if not ok or type(r) ~= "table" then return 0, tostring(r) end
    return tonumber(r.StatusCode) or 0, tostring(r.Body or "")
end

-- Step 1: Immediate Discord ping to verify webhook URL & executor HTTP
local c1, b1 = post(HS:JSONEncode({ content = "Ping from " .. LP.Name }), "application/json")
warn("[BF-Dump] Ping HTTP:", c1, b1:sub(1, 80))

-- Step 2: Scan ItemConfig
local ItemConfig = require(RS:WaitForChild("ItemConfig"))
local out = {}

for id = 1, 2000 do
    local ok, cfg = pcall(ItemConfig.tryGet, id)
    if ok and type(cfg) == "table" then
        local name = (cfg.Display and cfg.Display.Name) or "nil"
        local key = (cfg.Index and cfg.Index.StorageKey) or "nil"
        local cat = (cfg.Index and (cfg.Index.Category or cfg.Index.Type)) or "nil"
        local flags = {}
        for k, v in pairs(cfg) do
            if type(v) ~= "table" then
                table.insert(flags, tostring(k) .. "=" .. tostring(v))
            elseif tostring(k) ~= "Display" then
                for k2, v2 in pairs(v) do
                    if type(v2) ~= "table" then
                        table.insert(flags, tostring(k) .. "." .. tostring(k2) .. "=" .. tostring(v2))
                    end
                end
            end
        end
        table.insert(out, string.format("Id=%d | Cat=%s | Disp=%s | Key=%s | %s",
            id, tostring(cat), tostring(name), tostring(key), table.concat(flags, ", ")))
    end
end

local txt = table.concat(out, "\n")
if writefile then pcall(writefile, "bf_dump.txt", txt) end

-- Step 3: Upload as .txt file
local bnd = "----BF" .. tostring(math.random(100000, 999999))
local multipart = table.concat({
    "--" .. bnd,
    'Content-Disposition: form-data; name="file"; filename="bf_dump.txt"',
    "Content-Type: text/plain",
    "",
    txt,
    "--" .. bnd .. "--",
    ""
}, "\r\n")

local c2, b2 = post(multipart, "multipart/form-data; boundary=" .. bnd)
warn("[BF-Dump] File HTTP:", c2, b2:sub(1, 80))
