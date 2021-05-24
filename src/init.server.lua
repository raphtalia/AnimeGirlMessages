local COOLDOWNS = {
    Default = 180,
    Error = 60,
    WindowFocused = 60,
}

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Roact = require(script.Roact)
local Flipper = require(script.Flipper)
local Messages = require(script.Messages)

local e = Roact.createElement
local clock = os.clock

local agmUI = Roact.PureComponent:extend("AnimeGirl")

local function wait(x)
    local waitStart = clock()
    repeat
        RunService.RenderStepped:Wait()
    until clock() - waitStart > x
end

local function randomSelect(tab)
    return tab[math.random(1, #tab)]
end

function agmUI:init()
    self.image, self.setImage = Roact.createBinding("")
    self.text, self.setText = Roact.createBinding("")

    self.motor = Flipper.SingleMotor.new(1)
    self.binding, self.setBinding = Roact.createBinding(self.motor:getValue())

    self.motor:onStep(self.setBinding)

    local lastMessages = {
        Default = clock(),
        Error = 0,
        WindowFocused = 0,
    }

    local lastAnimeGirl
    local localSound = Instance.new("Sound")
    local debounce = false
    local function sendMessage(messageType)
        if not debounce then
            debounce = true

            local animeGirl
            repeat
                -- Don't give the same one twice in a row
                animeGirl = randomSelect(Messages)
            until animeGirl ~= lastAnimeGirl

            local image = randomSelect(animeGirl.Images)
            local sound = randomSelect(animeGirl.Sounds)
            local message = randomSelect(animeGirl.Messages[messageType])

            self.setImage(image)
            self.setText(message)

            if RunService:IsEdit() then
                localSound.SoundId = sound
                SoundService:PlayLocalSound(localSound)
            end

            self.motor:setGoal(Flipper.Spring.new(0, {
                frequency = 5,
                dampingRatio = 1
            }))

            wait(2)

            self.motor:setGoal(Flipper.Spring.new(1, {
                frequency = 5,
                dampingRatio = 1
            }))

            lastMessages[messageType] = os.clock()
            lastAnimeGirl = animeGirl
            debounce = false
        end
    end

    -- Message for opening AutoRecovery
    if (game.Name):find("AutoRecovery") then
        sendMessage("AutoRecovery")
    end

    -- Periodic messages
    RunService.RenderStepped:Connect(function()
        if clock() - lastMessages.Default > COOLDOWNS.Default then
            sendMessage("Default")
        end
    end)

    -- Messages during console errors
    LogService.MessageOut:Connect(function(_, messageType)
        if messageType == Enum.MessageType.MessageError and clock() - lastMessages.Error > COOLDOWNS.Error then
            sendMessage("Error")
        end
    end)

    -- Message for tabbing back in
    UserInputService.WindowFocused:Connect(function()
        if clock() - lastMessages.WindowFocused > COOLDOWNS.WindowFocused then
            sendMessage("WindowFocused")
        end
    end)
end

function agmUI:render()
    return e(
        "ScreenGui",
        {},
        {
            e(
                "Frame",
                {
                    AnchorPoint = Vector2.new(1, 1),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.35, 0, 0.5, 0),
                    Position = self.binding:map(function(value)
                        return UDim2.new(1, 0, 1, 0):Lerp(UDim2.new(1, 0, 2, 0), value)
                    end)
                },
                {
                    e(
                        "UIAspectRatioConstraint",
                        {
                            AspectRatio = 1.5,
                        }
                    ),
                    e(
                        "ImageLabel",
                        {
                            AnchorPoint = Vector2.new(1, 1),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, 0, 1, 0),
                            Size = UDim2.new(0.7, 0, 1, 0),
                            Image = self.image,
                        }
                    ),
                    e(
                        "ImageLabel",
                        {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(-0.05, 0, -0.2, 0),
                            Size = UDim2.new(0.65, 0, 0.4, 0),
                            Image = "rbxassetid://6208622370",
                        },
                        {
                            e(
                                "UIAspectRatioConstraint",
                                {
                                    AspectRatio = 2.2,
                                }
                            ),
                            e(
                                "TextLabel",
                                {
                                    BackgroundTransparency = 1,
                                    Position = UDim2.new(0.05, 0, 0.15, 0),
                                    Size = UDim2.new(0.85, 0, 0.4, 0),
                                    Font = Enum.Font.IndieFlower,
                                    Text = self.text,
                                    TextColor3 = Color3.new(),
                                    TextScaled = true,
                                    TextStrokeTransparency = 1,
                                }
                            )
                        }
                    )
                }
            )
        }
    )
end

Roact.mount(e(agmUI), CoreGui, "AGM")