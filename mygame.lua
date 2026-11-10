
-- NOOB KEY SYSTEM
-- Roblox Studio / LocalScript
-- Place inside StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local KEY_LINK = "https://links-unlockr-gg.netlify.app/s?mOAtSVcp&data=qe4RQAE6kyWMDfsjlKZWN3TkZONzvfTcLlN3/OSuPE/3SxUitgWiEjzaDS1pz6md8uM02jv/pdxgS5O6qQU/DsVcWkZpzEOS8wfKXV5Z3SWdyYdyfQgQQ9LwLYy%2BBA8TNtO31PgWZ6XzFjY2F0t%2Bz3qMsfdzBlE1/IemBlQSQise4mc32YMo60W0jvD4aWRKJwh9kQ2t%2Buw286brYsvBHsXP3ldlfpIlehG3gGf0Q05gkNac%2BvDLdqzULY11HNPktVzAxovbA2EZK%2BvXBYte2Q%3D%3D"

-- CLEAN OLD GUI
local old = PlayerGui:FindFirstChild("NoobKeySystem")
if old then old:Destroy() end

-- DISABLE STANDARD PLAYER CONTROLS
local PlayerModule = require(
    Player.PlayerScripts:WaitForChild("PlayerModule")
)
local Controls = PlayerModule:GetControls()
Controls:Disable()

-- SAVE CAMERA POSITION
local Camera = workspace.CurrentCamera
local FixedCFrame = Camera.CFrame
local FixedFocus = Camera.Focus

Camera.CameraType = Enum.CameraType.Scriptable

-- BLUR
local Blur = Instance.new("BlurEffect")
Blur.Name = "NoobKeyBlur"
Blur.Size = 12
Blur.Parent = Lighting

-- SCREEN GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "NoobKeySystem"
GUI.IgnoreGuiInset = true
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 1000
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

-- DARK OVERLAY
local Overlay = Instance.new("TextButton")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.Position = UDim2.fromScale(0, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 0.5
Overlay.BorderSizePixel = 0
Overlay.Text = ""
Overlay.AutoButtonColor = false
Overlay.Active = true
Overlay.Modal = true
Overlay.ZIndex = 1
Overlay.Parent = GUI

-- MAIN WINDOW
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.new(0.9, 0, 0, 240)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.ZIndex = 5
Main.Parent = GUI

local Constraint = Instance.new("UISizeConstraint")
Constraint.MaxSize = Vector2.new(440, 260)
Constraint.MinSize = Vector2.new(280, 240)
Constraint.Parent = Main

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(45, 45, 52)
Stroke.Parent = Main

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.fromOffset(20, 20)
Title.BackgroundTransparency = 1
Title.Text = "Key Required"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.ZIndex = 6
Title.Parent = Main

-- SUBTITLE
local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -40, 0, 20)
Subtitle.Position = UDim2.fromOffset(20, 48)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Get a free key to access this script."
Subtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 13
Subtitle.ZIndex = 6
Subtitle.Parent = Main

-- GET KEY BUTTON
local GetKey = Instance.new("TextButton")
GetKey.Size = UDim2.new(1, -40, 0, 44)
GetKey.Position = UDim2.fromOffset(20, 84)
GetKey.BackgroundColor3 = Color3.fromRGB(114, 57, 234)
GetKey.Text = "Get Key (Copy Link)"
GetKey.TextColor3 = Color3.new(1, 1, 1)
GetKey.Font = Enum.Font.GothamBold
GetKey.TextSize = 14
GetKey.ZIndex = 7
GetKey.Parent = Main

Instance.new("UICorner", GetKey).CornerRadius =
    UDim.new(0, 8)

-- LINK BOX
local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(1, -40, 0, 40)
LinkBox.Position = UDim2.fromOffset(20, 140)
LinkBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
LinkBox.TextColor3 = Color3.new(1, 1, 1)
LinkBox.PlaceholderText = "Your key link appears here"
LinkBox.Text = ""
LinkBox.ClearTextOnFocus = false
LinkBox.TextEditable = false
LinkBox.Font = Enum.Font.Gotham
LinkBox.TextSize = 11
LinkBox.ZIndex = 7
LinkBox.Parent = Main

Instance.new("UICorner", LinkBox).CornerRadius =
    UDim.new(0, 8)

-- STATUS BUTTON
local Status = Instance.new("TextButton")
Status.Size = UDim2.new(1, -40, 0, 40)
Status.Position = UDim2.fromOffset(20, 190)
Status.BackgroundColor3 = Color3.new(1, 1, 1)
Status.Text = "Key System Active"
Status.TextColor3 = Color3.fromRGB(24, 24, 28)
Status.Font = Enum.Font.GothamBold
Status.TextSize = 14
Status.ZIndex = 7
Status.Parent = Main

Instance.new("UICorner", Status).CornerRadius =
    UDim.new(0, 8)

Status.Active = false

-- GET LINK
GetKey.Activated:Connect(function()
    LinkBox.Text = KEY_LINK
    GetKey.Text = "Link Displayed!"
    task.wait(1.5)

    if GetKey.Parent then
        GetKey.Text = "Get Key (Copy Link)"
    end
end)

-- KEEP CAMERA FIXED
RunService:BindToRenderStep(
    "NoobFixedCamera",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        local CurrentCamera = workspace.CurrentCamera

        if CurrentCamera then
            CurrentCamera.CameraType =
                Enum.CameraType.Scriptable
            CurrentCamera.CFrame = FixedCFrame
            CurrentCamera.Focus = FixedFocus
        end
    end
)

print("Noob Key System Loaded")
