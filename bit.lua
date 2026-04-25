-- 手机端飞行脚本 (触屏操控版)
-- 使用游戏自带摇杆控制方向，屏幕按钮切换飞行状态

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- 飞行状态
local flying = false
local flySpeed = 50
local bodyGyro
local bodyVelocity

-- 用于接收摇杆移动方向
local moveDirection = Vector3.zero

-- 创建飞行的物理对象
local function startFlying()
    if flying then return end
    flying = true

    humanoid.PlatformStand = true

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = rootPart
end

local function stopFlying()
    if not flying then return end
    flying = false

    humanoid.PlatformStand = false
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
end

-- 监听手机自带摇杆的输入
-- Humanoid.MoveDirection 会随着摇杆的推动实时改变方向
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    moveDirection = humanoid.MoveDirection
end)

-- 创建屏幕上的飞行按钮
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileFlyGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0, 120, 0, 50)
flyButton.Position = UDim2.new(0.5, -60, 0.1, 0) -- 放在屏幕中上方
flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flyButton.TextColor3 = Color3.new(1, 1, 1)
flyButton.Text = "开启飞行"
flyButton.Font = Enum.Font.SourceSansBold
flyButton.TextSize = 20
flyButton.Parent = screenGui

-- 处理按钮点击
flyButton.MouseButton1Click:Connect(function()
    if flying then
        stopFlying()
        flyButton.Text = "开启飞行"
    else
        startFlying()
        flyButton.Text = "关闭飞行"
    end
end)

-- 每帧更新飞行移动
RunService.RenderStepped:Connect(function()
    if flying and bodyVelocity then
        local camera = workspace.CurrentCamera
        -- 将摇杆产生的本地方向，转换成基于摄像机朝向的世界方向
        local worldMove = camera.CFrame:VectorToWorldSpace(moveDirection)
        -- 只取水平方向的移动（忽略垂直分量），防止角色朝上朝下飞时方向紊乱
        local horizontalMove = Vector3.new(worldMove.X, 0, worldMove.Z)
        local finalVelocity = horizontalMove * flySpeed

        -- 高度控制：可以在屏幕上额外加两个小按钮，或者使用跳跃/下蹲
        -- 这里简单使用 Humanoid.Jump 和假的下蹲作为高度升降（需要手机上有跳跃键）
        -- 为了更直接，我们再用两个透明按钮实现上升/下降，下面提供一个优化版本
        bodyVelocity.Velocity = Vector3.new(finalVelocity.X, bodyVelocity.Velocity.Y, finalVelocity.Z)
        bodyGyro.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(180), 0) -- 让角色面朝屏幕方向
    end
end)

-- 为高度控制添加两个半透明按钮（可选的完整版）
local upButton = Instance.new("TextButton")
upButton.Size = UDim2.new(0, 60, 0, 60)
upButton.Position = UDim2.new(0.85, 0, 0.7, 0) -- 屏幕右侧
upButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
upButton.BackgroundTransparency = 0.5
upButton.Text = "↑"
upButton.TextColor3 = Color3.new(1, 1, 1)
upButton.TextSize = 30
upButton.Parent = screenGui

local downButton = Instance.new("TextButton")
downButton.Size = UDim2.new(0, 60, 0, 60)
downButton.Position = UDim2.new(0.85, 0, 0.8, 0) -- 右侧下方
downButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
downButton.BackgroundTransparency = 0.5
downButton.Text = "↓"
downButton.TextColor3 = Color3.new(1, 1, 1)
downButton.TextSize = 30
downButton.Parent = screenGui

-- 按住上升/下降按钮时修改速度的垂直分量
local upHeld = false
local downHeld = false
local verticalSpeed = 0

upButton.MouseButton1Down:Connect(function()
    upHeld = true
end)
upButton.MouseButton1Up:Connect(function()
    upHeld = false
end)

downButton.MouseButton1Down:Connect(function()
    downHeld = true
end)
downButton.MouseButton1Up:Connect(function()
    downHeld = false
end)

-- 在同一个RenderStepped里更新垂直速度
RunService.RenderStepped:Connect(function()
    if flying and bodyVelocity then
        verticalSpeed = 0
        if upHeld then
            verticalSpeed = flySpeed
        elseif downHeld then
            verticalSpeed = -flySpeed
        end
        bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, verticalSpeed - bodyVelocity.Velocity.Y, 0)
    end
end)
