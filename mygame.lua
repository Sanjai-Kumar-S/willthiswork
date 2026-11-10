
-- Made by Noob
-- Persistent Key GUI + Fixed Camera
-- Roblox Luau / Client Executor

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local KEY_LINK = "https://links-unlockr-gg.netlify.app/s?mOAtSVcp&data=qe4RQAE6kyWMDfsjlKZWN3TkZONzvfTcLlN3/OSuPE/3SxUitgWiEjzaDS1pz6md8uM02jv/pdxgS5O6qQU/DsVcWkZpzEOS8wfKXV5Z3SWdyYdyfQgQQ9LwLYy%2BBA8TNtO31PgWZ6XzFjY2F0t%2Bz3qMsfdzBlE1/IemBlQSQise4mc32YMo60W0jvD4aWRKJwh9kQ2t%2Buw286brYsvBHsXP3ldlfpIlehG3gGf0Q05gkNac%2BvDLdqzULY11HNPktVzAxovbA2EZK%2BvXBYte2Q%3D%3D"

local FIXED_CAMERA = true
local DARKNESS = 0.5
local BLUR_SIZE = 12

-- CLEAN OLD GUI
if CoreGui:FindFirstChild("NoobKeySystem") then
    CoreGui.NoobKeySystem:Destroy()
end

-- SAVE CAMERA VIEW
local savedCameraCFrame = Camera.CFrame
local savedCameraType = Camera.CameraType

-- BLUR EFFECT
local Blur = Instance.new("BlurEffect")
Blur.Name = "NoobKeyBlur"
Blur.Size = BLUR_SIZE
Blur.Parent = Lighting

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoobKeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- DARK OVERLAY
local Overlay = Instance.new("Frame")
Overlay.Name = "DarkOverlay"
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 1 - DARKNESS
Overlay.BorderSizePixel = 0
Overlay.Active = false
Overlay.Parent = ScreenGui

-- MAIN WINDOW
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(440, 240)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius =
    UDim.new(0, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(45, 45, 52)
Stroke.Parent = MainFrame

local function CreateLabel(name, text, position, size)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Position = position
    label.Size = size
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.ZIndex = 3
    label.Parent = MainFrame
    return label
end

CreateLabel(
    "Title",
    "Key Required",
    UDim2.fromOffset(20, 20),
    UDim2.new(1, -40, 0, 30)
).Font = Enum.Font.GothamBold

local Subtitle = CreateLabel(
    "Subtitle",
    "Get a free key to access this script.",
    UDim2.fromOffset(20, 48),
    UDim2.new(1, -40, 0, 20)
)
Subtitle.TextColor3 = Color3.fromRGB(160, 160, 170)

-- GET KEY BUTTON
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(1, -40, 0, 44)
GetKeyBtn.Position = UDim2.fromOffset(20, 84)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(114, 57, 234)
GetKeyBtn.Text = "Get Key (Copy Link)"
GetKeyBtn.TextColor3 = Color3.new(1, 1, 1)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 14
GetKeyBtn.ZIndex = 3
GetKeyBtn.Parent = MainFrame

Instance.new("UICorner", GetKeyBtn).CornerRadius =
    UDim.new(0, 8)

-- INPUT BOX
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -40, 0, 40)
InputBox.Position = UDim2.fromOffset(20, 140)
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
InputBox.PlaceholderText = "Paste your key here..."
InputBox.Text = ""
InputBox.TextColor3 = Color3.new(1, 1, 1)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 14
InputBox.ClearTextOnFocus = false
InputBox.ZIndex = 3
InputBox.Parent = MainFrame

Instance.new("UICorner", InputBox).CornerRadius =
    UDim.new(0, 8)

-- VERIFY BUTTON (DISPLAY ONLY)
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, -40, 0, 40)
VerifyBtn.Position = UDim2.fromOffset(20, 190)
VerifyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
VerifyBtn.Text = "Key System Active"
VerifyBtn.TextColor3 = Color3.fromRGB(24, 24, 28)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 14
VerifyBtn.ZIndex = 3
VerifyBtn.Parent = MainFrame

Instance.new("UICorner", VerifyBtn).CornerRadius =
    UDim.new(0, 8)

-- COPY LINK
GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        local success = pcall(function()
            setclipboard(KEY_LINK)
        end)

        GetKeyBtn.Text = success and
            "Copied Link!" or "Copy Failed"
    else
        GetKeyBtn.Text = "Clipboard Unavailable"
    end

    task.wait(2)
    if GetKeyBtn.Parent then
        GetKeyBtn.Text = "Get Key (Copy Link)"
    end
end)

-- FIXED CAMERA
if FIXED_CAMERA then
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = savedCameraCFrame
end

local CameraConnection
CameraConnection = RunService.RenderStepped:Connect(function()
    if FIXED_CAMERA and workspace.CurrentCamera then
        local currentCamera = workspace.CurrentCamera

        currentCamera.CameraType = Enum.CameraType.Scriptable
        currentCamera.CFrame = savedCameraCFrame
    end
end)

-- CHARACTER MOVEMENT IS NOT MODIFIED
-- Camera stays at its saved viewpoint.
-- GUI remains visible until manually stopped.

print("Noob Key System Loaded")
