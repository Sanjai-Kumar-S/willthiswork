
-- Made by Noob
-- Persistent Key GUI + Fixed Camera + Input Lock
-- Roblox Luau / Client Executor

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

-- CONFIGURATION
local KEY_LINK = "https://links-unlockr-gg.netlify.app/s?mOAtSVcp&data=qe4RQAE6kyWMDfsjlKZWN3TkZONzvfTcLlN3/OSuPE/3SxUitgWiEjzaDS1pz6md8uM02jv/pdxgS5O6qQU/DsVcWkZpzEOS8wfKXV5Z3SWdyYdyfQgQQ9LwLYy%2BBA8TNtO31PgWZ6XzFjY2F0t%2Bz3qMsfdzBlE1/IemBlQSQise4mc32YMo60W0jvD4aWRKJwh9kQ2t%2Buw286brYsvBHsXP3ldlfpIlehG3gGf0Q05gkNac%2BvDLdqzULY11HNPktVzAxovbA2EZK%2BvXBYte2Q%3D%3D"

local DARKNESS = 0.50
local BLUR_SIZE = 12
local GUI_NAME = "NoobKeySystem"

-- CLEAN PREVIOUS INSTANCE
pcall(function()
    RunService:UnbindFromRenderStep("NoobFixedCamera")
end)

pcall(function()
    ContextActionService:UnbindAction("NoobInputLock")
end)

if CoreGui:FindFirstChild(GUI_NAME) then
    CoreGui[GUI_NAME]:Destroy()
end

local oldBlur = Lighting:FindFirstChild("NoobKeyBlur")
if oldBlur then
    oldBlur:Destroy()
end

-- PLAYER CONTROLS
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
Blur.Size = BLUR_SIZE
Blur.Parent = Lighting

-- SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

ScreenGui.Parent = CoreGui

-- FULL SCREEN INPUT BLOCKER + DARK OVERLAY
local Overlay = Instance.new("TextButton")
Overlay.Name = "FullScreenOverlay"
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.Position = UDim2.fromScale(0, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 1 - DARKNESS
Overlay.BorderSizePixel = 0
Overlay.Text = ""
Overlay.AutoButtonColor = false
Overlay.Active = true
Overlay.Modal = true
Overlay.ZIndex = 1
Overlay.Parent = ScreenGui

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0.9, 0, 0, 240)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local SizeConstraint = Instance.new("UISizeConstraint")
SizeConstraint.MaxSize = Vector2.new(440, 260)
SizeConstraint.MinSize = Vector2.new(280, 240)
SizeConstraint.Parent = MainFrame

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 52)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- TITLE
local function CreateLabel(name, text, position, size)
    local Label = Instance.new("TextLabel")
    Label.Name = name
    Label.Size = size
    Label.Position = position
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Gotham
    Label.Text = text
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextSize = 14
    Label.ZIndex = 6
    Label.Parent = MainFrame
    return Label
end

local Title = CreateLabel(
    "Title",
    "Key Required",
    UDim2.fromOffset(20, 20),
    UDim2.new(1, -40, 0, 30)
)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18

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
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.AutoButtonColor = true
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.Text = "Get Key (copies link to clipboard)"
GetKeyBtn.TextColor3 = Color3.new(1, 1, 1)
GetKeyBtn.TextSize = 14
GetKeyBtn.ZIndex = 7
GetKeyBtn.Parent = MainFrame

Instance.new("UICorner", GetKeyBtn).CornerRadius =
    UDim.new(0, 8)

-- KEY TEXTBOX
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -40, 0, 40)
InputBox.Position = UDim2.fromOffset(20, 140)
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
InputBox.BorderSizePixel = 0
InputBox.Font = Enum.Font.Gotham
InputBox.PlaceholderText = "Paste your key here..."
InputBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
InputBox.Text = ""
InputBox.TextColor3 = Color3.new(1, 1, 1)
InputBox.TextSize = 14
InputBox.ClearTextOnFocus = false
InputBox.ZIndex = 7
InputBox.Parent = MainFrame

Instance.new("UICorner", InputBox).CornerRadius =
    UDim.new(0, 8)

-- DISPLAY BUTTON (NO VERIFICATION)
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, -40, 0, 40)
VerifyBtn.Position = UDim2.fromOffset(20, 190)
VerifyBtn.BackgroundColor3 = Color3.new(1, 1, 1)
VerifyBtn.BorderSizePixel = 0
VerifyBtn.AutoButtonColor = false
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.Text = "Key System Active"
VerifyBtn.TextColor3 = Color3.fromRGB(24, 24, 28)
VerifyBtn.TextSize = 14
VerifyBtn.ZIndex = 7
VerifyBtn.Parent = MainFrame

Instance.new("UICorner", VerifyBtn).CornerRadius =
    UDim.new(0, 8)

-- CLIPBOARD
GetKeyBtn.MouseButton1Click:Connect(function()
    local success = pcall(function()
        assert(type(setclipboard) == "function",
            "Clipboard unavailable")
        setclipboard(KEY_LINK)
    end)

    if success then
        GetKeyBtn.Text = "Copied Link!"
    else
        GetKeyBtn.Text = "Copy Failed"
    end

    task.wait(2)

    if GetKeyBtn.Parent then
        GetKeyBtn.Text = "Get Key (copies link to clipboard)"
    end
end)

-- BLOCK COMMON GAMEPLAY INPUTS
local BlockedKeys = {
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,
    Enum.KeyCode.Up,
    Enum.KeyCode.Down,
    Enum.KeyCode.Left,
    Enum.KeyCode.Right,
    Enum.KeyCode.Space,
    Enum.KeyCode.LeftShift,
    Enum.KeyCode.RightShift,
    Enum.KeyCode.Q,
    Enum.KeyCode.E,
    Enum.KeyCode.R,
    Enum.KeyCode.F,
    Enum.KeyCode.Z,
    Enum.KeyCode.X,
    Enum.KeyCode.C,
    Enum.KeyCode.V,
    Enum.KeyCode.One,
    Enum.KeyCode.Two,
    Enum.KeyCode.Three,
    Enum.KeyCode.Four,
    Enum.KeyCode.Five,
    Enum.KeyCode.Slash
}

local function BlockInput(actionName, inputState, inputObject)
    -- Allow typing in the key textbox
    if InputBox:IsFocused() then
        return Enum.ContextActionResult.Pass
    end

    return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
    "NoobInputLock",
    BlockInput,
    false,
    9999,
    table.unpack(BlockedKeys)
)

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

-- FINISHED
print("Noob Key System Loaded")
print("Camera: Fixed")
print("Standard Controls: Disabled")
print("Key GUI: Persistent")
