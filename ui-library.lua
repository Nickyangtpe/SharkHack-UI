-- ModuleScript: SharkGUILibrary

local CoreGUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Default styles (can be customized when calling functions)
local styles = {
    MainBackground = Color3.fromRGB(20, 20, 25),
    TitleBarBackground = Color3.fromRGB(15, 15, 20),
    SidebarBackground = Color3.fromRGB(25, 25, 30),
    AccentColor = Color3.fromRGB(78, 93, 234), -- Theme color
    SecondaryColor = Color3.fromRGB(40, 40, 45), -- Toggle off, slider track
    TextColor = Color3.fromRGB(255, 255, 255),
    MutedTextColor = Color3.fromRGB(150, 150, 150),
    RedColor = Color3.fromRGB(255, 0, 0),
    GreenColor = Color3.fromRGB(0, 255, 0),
    BlueColor = Color3.fromRGB(0, 0, 255),
    WarningColor = Color3.fromRGB(255, 100, 100), -- Close button hover
    InfoColor = Color3.fromRGB(100, 200, 255), -- Minimize button hover
    Font = Enum.Font.Gotham,
    BoldFont = Enum.Font.GothamBold,
    TextSize = 14,
    TitleTextSize = 16,
    LogoTextSize = 18,
    AnimationSpeed = 0.2, -- Short animations
    LongAnimationSpeed = 0.3, -- Window animations
    EaseStyle = Enum.EasingStyle.Quart,
    EaseDirection = Enum.EasingDirection.Out,
    WindowEaseStyle = Enum.EasingStyle.Back,
    WindowEaseDirectionIn = Enum.EasingDirection.In,
    WindowEaseDirectionOut = Enum.EasingDirection.Out,
    Padding = UDim.new(0, 5),
    InnerPadding = UDim.new(0, 10),
    SectionPadding = UDim.new(0, 20), -- Padding around sections
    CornerRadius = UDim.new(0, 6),
    SmallCornerRadius = UDim.new(0, 4),
    RoundCornerRadius = UDim.new(1, 0),
}

-- Store references to dynamically created popups (like color pickers)
local dynamicPopups = {}

-- Helper function to create a basic frame
local function createBaseFrame(parent, name, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size or UDim2.new(0, 100, 0, 100)
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = color or styles.MainBackground
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.Parent = parent
    return frame
end

-- Helper function to create a text label
local function createBaseLabel(parent, name, size, position, text, textColor, textSize, font, xAlign, yAlign)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = textColor or styles.TextColor
    label.TextSize = textSize or styles.TextSize
    label.Font = font or styles.Font
    label.TextXAlignment = xAlign or Enum.TextXAlignment.Center
    label.TextYAlignment = yAlign or Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

-- Helper function to create a text button
local function createBaseButton(parent, name, size, position, text, textColor, textSize, font, xAlign, yAlign)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 100, 0, 30)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = text or ""
    button.TextColor3 = textColor or styles.TextColor
    button.TextSize = textSize or styles.TextSize
    button.Font = font or styles.Font
    button.TextXAlignment = xAlign or Enum.TextXAlignment.Center
    button.TextYAlignment = yAlign or Enum.TextYAlignment.Center
    button.Parent = parent
    return button
end


-- Function to create the main draggable window
-- Returns: MainFrame, Sidebar, ContentArea
function CoreGUI.createWindow(title, size, initialPosition, onClose, onMinimizeToggle)
    local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local playerGui = player:WaitForChild("PlayerGui")

    -- Create the ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = title:gsub(" ", "") .. "GUI" -- Use a name friendly for instance naming
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- Main frame
    local mainFrame = createBaseFrame(
        screenGui,
        "MainFrame",
        size or UDim2.new(0, 500, 0, 350),
        initialPosition or UDim2.new(0.5, -250, 0.5, -175),
        styles.MainBackground
    )

    -- Add window title bar
    local titleBar = createBaseFrame(
        mainFrame,
        "TitleBar",
        UDim2.new(1, 0, 0, 30),
        UDim2.new(0, 0, 0, 0),
        styles.TitleBarBackground
    )

    -- Title text
    createBaseLabel(
        titleBar,
        "TitleText",
        UDim2.new(1, -100, 1, 0),
        UDim2.new(0, 10, 0, 0),
        title,
        styles.TextColor,
        styles.TitleTextSize,
        styles.BoldFont,
        Enum.TextXAlignment.Left
    )

    -- Close button
    local closeButton = createBaseButton(
        titleBar,
        "CloseButton",
        UDim2.new(0, 30, 0, 30),
        UDim2.new(1, -30, 0, 0),
        "✕",
        styles.TextColor,
        styles.TitleTextSize,
        styles.BoldFont
    )
    closeButton.ZIndex = 2 -- Ensure buttons are above title bar

    -- Minimize button
    local minimizeButton = createBaseButton(
        titleBar,
        "MinimizeButton",
        UDim2.new(0, 30, 0, 30),
        UDim2.new(1, -60, 0, 0),
        "−",
        styles.TextColor,
        styles.TitleTextSize,
        styles.BoldFont
    )
    minimizeButton.ZIndex = 2 -- Ensure buttons are above title bar

    -- Left sidebar
    local sidebar = createBaseFrame(
        mainFrame,
        "Sidebar",
        UDim2.new(0, 165, 1, -30),
        UDim2.new(0, 0, 0, 30),
        styles.SidebarBackground
    )

    -- Content area
    local contentArea = createBaseFrame(
        mainFrame,
        "ContentArea",
        UDim2.new(1, -165, 1, -30),
        UDim2.new(0, 165, 0, 30),
        nil, -- Transparent background
        1
    )

    -- Add window dragging
    local dragging = false
    local dragStartPos
    local initialFramePos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartPos = input.Position
            initialFramePos = mainFrame.Position

            -- Animate title bar on click
            TweenService:Create(titleBar, TweenInfo.new(styles.AnimationSpeed), { BackgroundColor3 = styles.TitleBarBackground - Color3.new(0.05, 0.05, 0.05) }):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- Animate title bar on release
                    TweenService:Create(titleBar, TweenInfo.new(styles.AnimationSpeed), { BackgroundColor3 = styles.TitleBarBackground }):Play()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPos
            local targetPosition = UDim2.new(initialFramePos.X.Scale, initialFramePos.X.Offset + delta.X, initialFramePos.Y.Scale, initialFramePos.Y.Offset + delta.Y)

            -- Clamp position to keep window on screen
            local maxPosX = playerGui.AbsoluteSize.X - mainFrame.AbsoluteSize.X
            local maxPosY = playerGui.AbsoluteSize.Y - mainFrame.AbsoluteSize.Y
            targetPosition = UDim2.new(
                0, math.clamp(targetPosition.X.Offset, 0, maxPosX),
                0, math.clamp(targetPosition.Y.Offset, 0, maxPosY)
            )


            TweenService:Create(mainFrame, TweenInfo.new(0.05), { Position = targetPosition }):Play()
        end
    end)


    -- Close button functionality
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.WarningColor }):Play()
    end)

    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.TextColor }):Play()
    end)

    closeButton.MouseButton1Click:Connect(function()
        -- Animate closing
        TweenService:Create(mainFrame, TweenInfo.new(styles.LongAnimationSpeed, styles.WindowEaseStyle, styles.WindowEaseDirectionIn), {
            Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0), -- Collapse height
            Position = UDim2.new(initialPosition.X.Scale, initialPosition.X.Offset, initialPosition.Y.Scale, initialPosition.Y.Offset + size.Y.Offset/2) -- Collapse towards center
        }):Play()

        if onClose then
            wait(styles.LongAnimationSpeed)
            onClose() -- Call external close handler
        else
             wait(styles.LongAnimationSpeed)
            screenGui:Destroy()
        end
    end)

    -- Minimize button functionality
    local isMinimized = false
    local originalSize = size or UDim2.new(0, 500, 0, 350)

    minimizeButton.MouseEnter:Connect(function()
        TweenService:Create(minimizeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.InfoColor }):Play()
    end)

    minimizeButton.MouseLeave:Connect(function()
        TweenService:Create(minimizeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.TextColor }):Play()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        if isMinimized then
            -- Restore with animation
            TweenService:Create(mainFrame, TweenInfo.new(styles.LongAnimationSpeed, styles.WindowEaseStyle, styles.WindowEaseDirectionOut), {
                Size = originalSize
            }):Play()

            wait(styles.LongAnimationSpeed * 0.3) -- Slight delay for visibility
            sidebar.Visible = true
            contentArea.Visible = true
            minimizeButton.Text = "−"
        else
            -- Minimize with animation
            sidebar.Visible = false
            contentArea.Visible = false

            TweenService:Create(mainFrame, TweenInfo.new(styles.LongAnimationSpeed, styles.WindowEaseStyle, styles.WindowEaseDirectionIn), {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 30) -- Collapse to title bar height
            }):Play()

            minimizeButton.Text = "+"
        end
        isMinimized = not isMinimized

        if onMinimizeToggle then
             onMinimizeToggle(isMinimized) -- Call external handler
        end
    end)

    return screenGui, mainFrame, sidebar, contentArea
end

-- Function to create sidebar logo area
function CoreGUI.createSidebarLogo(parent, title, iconImageId, iconOffset, iconSize)
    local logoArea = createBaseFrame(
        parent,
        "LogoArea",
        UDim2.new(1, 0, 0, 110),
        UDim2.new(0, 0, 0, 0),
        nil, -- Transparent
        1
    )

    -- Create shark logo (simplified, you can add the triangle UIGradient/UIStroke)
    local sharkLogo = createBaseFrame(
        logoArea,
        "Logo",
        iconSize or UDim2.new(0, 60, 0, 60),
        UDim2.new(0.5, -(iconSize and iconSize.X.Offset/2 or 30), 0, 15),
        nil, -- Transparent
        1
    )

    -- Add Image if iconImageId is provided
    if iconImageId then
        local image = Instance.new("ImageLabel")
        image.Name = "Icon"
        image.Size = UDim2.new(1, 0, 1, 0)
        image.Image = iconImageId
        image.ImageRectOffset = iconOffset or Vector2.zero
        image.ImageRectSize = iconSize and Vector2.new(iconSize.X.Offset, iconSize.Y.Offset) or Vector2.new(60, 60) -- Adjust rect size if icon size is different
        image.BackgroundTransparency = 1
        image.Parent = sharkLogo
    else
        -- Original triangle shape logic (needs UIGradient/UIStroke instances here)
        local LogoTriangle = createBaseFrame(
            sharkLogo,
            "LogoTriangle",
            UDim2.new(0, 50, 0, 40),
            UDim2.new(0.5, -25, 0.5, -20),
             nil, -- Transparent
            1
        )
         local UIGradient = Instance.new("UIGradient")
        UIGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(0.5001, 1),
            NumberSequenceKeypoint.new(1, 1)
        })
        UIGradient.Rotation = 45
        UIGradient.Parent = LogoTriangle

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Color = styles.TextColor
        UIStroke.Thickness = 2
        UIStroke.Parent = LogoTriangle
    end


    -- Logo text
    createBaseLabel(
        logoArea,
        "LogoText",
        UDim2.new(1, 0, 0, 30),
        UDim2.new(0, 0, 0, 80),
        title,
        styles.TextColor,
        styles.LogoTextSize,
        styles.BoldFont
    )

    return logoArea
end


-- Function to create a menu button in the sidebar
-- Returns: Button Frame, Icon ImageButton, Label TextLabel, Highlight Frame
function CoreGUI.createMenuButton(parent, name, iconImageId, iconRectOffset, iconRectSize, layoutOrder, onActivated)
    local button = createBaseFrame(
        parent,
        name .. "Button",
        UDim2.new(1, 0, 0, 40),
        nil, -- Position managed by UIListLayout or explicit Y
        nil, -- Transparent
        1
    )
    button.LayoutOrder = layoutOrder

    local iconButton = Instance.new("ImageButton") -- Using ImageButton for potential click area on icon
    iconButton.Name = "Icon"
    iconButton.Size = UDim2.new(0, iconRectSize.X, 0, iconRectSize.Y) or UDim2.new(0, 24, 0, 24)
    iconButton.Position = UDim2.new(0, 30, 0.5, -iconButton.Size.Y.Offset / 2)
    iconButton.BackgroundTransparency = 1
    iconButton.Image = iconImageId
    iconButton.ImageRectOffset = iconRectOffset or Vector2.zero
    iconButton.ImageRectSize = iconRectSize or Vector2.new(36, 36) -- Default size match example
    iconButton.ImageColor3 = styles.MutedTextColor
    iconButton.Parent = button

    local label = createBaseLabel(
        button,
        "Label",
        UDim2.new(0, 100, 1, 0),
        UDim2.new(0, 65, 0, 0),
        name,
        styles.MutedTextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Left
    )

    local hoverHighlight = createBaseFrame(
        button,
        "HoverHighlight",
        UDim2.new(0.95, 0, 0.8, 0),
        UDim2.new(0.025, 0, 0.1, 0),
        styles.AccentColor,
        1 -- Start transparent
    )
    hoverHighlight.ZIndex = 0

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = styles.CornerRadius
    UICorner.Parent = hoverHighlight

    -- Add hover effect
    button.MouseEnter:Connect(function()
         -- Don't fade if already selected
        if hoverHighlight.BackgroundTransparency == 1 then
            TweenService:Create(hoverHighlight, TweenInfo.new(styles.AnimationSpeed), { BackgroundTransparency = 0.8 }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
         -- Don't fade out if selected
         if hoverHighlight.BackgroundTransparency > 0 then -- Check if it's the hover transparency, not selected transparency
             TweenService:Create(hoverHighlight, TweenInfo.new(styles.AnimationSpeed), { BackgroundTransparency = 1 }):Play()
         end
    end)

    -- Add click functionality
    local function onClick()
        if onActivated then
            onActivated(name) -- Call the callback with the button's name
        end
    end

    button.MouseButton1Click:Connect(onClick)
    iconButton.MouseButton1Click:Connect(onClick) -- Icon is also clickable

    return {
        frame = button,
        icon = iconButton,
        label = label,
        highlight = hoverHighlight
    }
end

-- Function to create a scrolling frame for content sections
-- Returns: ScrollingFrame
function CoreGUI.createScrollingFrame(parent, size, position)
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "ScrollingContent"
    scrollingFrame.Size = size
    scrollingFrame.Position = position
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.ScrollBarImageColor3 = styles.AccentColor -- Use accent color for scrollbar
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Initialize canvas size
    scrollingFrame.Parent = parent

    -- Create a UIListLayout for automatic positioning
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = styles.Padding
    listLayout.Parent = scrollingFrame

    -- Create padding inside the scrolling frame
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, 5)
    uiPadding.PaddingBottom = UDim.new(0, 5)
    uiPadding.PaddingLeft = UDim.new(0, 5)
    uiPadding.PaddingRight = UDim.new(0, 5)
    uiPadding.Parent = scrollingFrame

    -- Update canvas size when children change
    listLayout.LayoutApplied:Connect(function() -- Use LayoutApplied for more reliable updates
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + (uiPadding.PaddingTop.Offset + uiPadding.PaddingBottom.Offset))
    end)
     -- Initial CanvasSize adjustment
     task.defer(function()
         scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + (uiPadding.PaddingTop.Offset + uiPadding.PaddingBottom.Offset))
     end)


    return scrollingFrame
end

-- Function to create a toggle option
-- Returns: Frame, the current state
function CoreGUI.createToggle(parent, optionName, defaultState, layoutOrder, onChanged)
    local optionFrame = createBaseFrame(
        parent,
        optionName:gsub(" ", "") .. "Option",
        UDim2.new(1, 0, 0, 30),
        nil, -- Position managed by UIListLayout
        nil, -- Transparent
        1
    )
    optionFrame.LayoutOrder = layoutOrder

    createBaseLabel(
        optionFrame,
        "Label",
        UDim2.new(1, -50, 1, 0),
        UDim2.new(0, 0, 0, 0),
        optionName,
        styles.TextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Left
    )

    -- Toggle button (frame acting as button)
    local toggleButton = createBaseFrame(
        optionFrame,
        "ToggleButton",
        UDim2.new(0, 40, 0, 20),
        UDim2.new(1, -45, 0.5, -10),
        defaultState and styles.AccentColor or styles.SecondaryColor -- Initial color
    )
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = styles.RoundCornerRadius
    UICorner.Parent = toggleButton

    -- Toggle indicator (knob)
    local toggleIndicator = createBaseFrame(
        toggleButton,
        "Indicator",
        UDim2.new(0, 16, 0, 16),
        defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), -- Initial position
        styles.TextColor
    )
    local UICornerIndicator = Instance.new("UICorner")
    UICornerIndicator.CornerRadius = styles.RoundCornerRadius
    UICornerIndicator.Parent = toggleIndicator

    local currentState = defaultState

    -- Make toggle interactive
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            currentState = not currentState

            local newColor = currentState and styles.AccentColor or styles.SecondaryColor
            local newPosition = currentState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)

            TweenService:Create(toggleButton, TweenInfo.new(styles.AnimationSpeed), { BackgroundColor3 = newColor }):Play()
            TweenService:Create(toggleIndicator, TweenInfo.new(styles.AnimationSpeed), { Position = newPosition }):Play()

            if onChanged then
                onChanged(optionName, currentState)
            end
        end
    end)

    return optionFrame, currentState
end

-- Function to create a slider
-- Returns: Frame, the value label
function CoreGUI.createSlider(parent, sliderName, defaultValue, minValue, maxValue, layoutOrder, onChanged)
    local sliderFrame = createBaseFrame(
        parent,
        sliderName:gsub(" ", "") .. "Slider",
        UDim2.new(1, 0, 0, 50),
        nil, -- Position managed by UIListLayout
        nil, -- Transparent
        1
    )
    sliderFrame.LayoutOrder = layoutOrder

    createBaseLabel(
        sliderFrame,
        "Label",
        UDim2.new(1, 0, 0, 20),
        UDim2.new(0, 0, 0, 0),
        sliderName,
        styles.TextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Left
    )

    -- Slider track
    local sliderTrack = createBaseFrame(
        sliderFrame,
        "Track",
        UDim2.new(1, -60, 0, 6),
        UDim2.new(0, 0, 0, 30),
        styles.SecondaryColor
    )
    local UICornerTrack = Instance.new("UICorner")
    UICornerTrack.CornerRadius = styles.RoundCornerRadius
    UICornerTrack.Parent = sliderTrack

    -- Slider fill
    local initialRatio = math.clamp((defaultValue - minValue) / (maxValue - minValue), 0, 1)
    local sliderFill = createBaseFrame(
        sliderTrack,
        "Fill",
        UDim2.new(initialRatio, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        styles.AccentColor
    )
    local UICornerFill = Instance.new("UICorner")
    UICornerFill.CornerRadius = styles.RoundCornerRadius
    UICornerFill.Parent = sliderFill

    -- Slider knob
    local sliderKnob = createBaseFrame(
        sliderTrack,
        "Knob",
        UDim2.new(0, 16, 0, 16),
        UDim2.new(initialRatio, -8, 0.5, -8),
        styles.TextColor
    )
    sliderKnob.ZIndex = 2 -- Ensure knob is above track/fill
    local UICornerKnob = Instance.new("UICorner")
    UICornerKnob.CornerRadius = styles.RoundCornerRadius
    UICornerKnob.Parent = sliderKnob

    -- Value display
    local valueLabel = createBaseLabel(
        sliderFrame,
        "Value",
        UDim2.new(0, 50, 0, 20),
        UDim2.new(1, -50, 0, 23),
        tostring(defaultValue),
        styles.TextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Right
    )

    local isDragging = false
    local currentValue = defaultValue

    local function updateSlider(input)
        local trackPosition = sliderTrack.AbsolutePosition.X
        local trackWidth = sliderTrack.AbsoluteSize.X
        local mousePosition = input.Position.X

        -- Calculate the position ratio (0 to 1)
        local ratio = math.clamp((mousePosition - trackPosition) / trackWidth, 0, 1)

        -- Calculate the actual value
        currentValue = minValue + ratio * (maxValue - minValue)
        currentValue = math.floor(currentValue * 10 + 0.5) / 10 -- Round to 1 decimal place (more robust)

        -- Update UI with animation (subtle tween)
        TweenService:Create(sliderFill, TweenInfo.new(0.05), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
        TweenService:Create(sliderKnob, TweenInfo.new(0.05), { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()
        valueLabel.Text = tostring(currentValue)

        -- Call the callback
        if onChanged then
            onChanged(sliderName, currentValue)
        end
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input)
            -- Animate knob on click
             TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)

    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
             isDragging = true
             -- Animate knob on click
             TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
            isDragging = false
             -- Animate knob on release
             TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 16, 0, 16), Position = sliderKnob.Position + UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

     -- Allow clicking anywhere on the track to jump the knob
    sliderTrack.MouseButton1Click:Connect(function(x, y, input)
        if not isDragging then -- Only jump if not currently dragging
             updateSlider(input)
        end
    end)
     -- Make knob clickable like a button if not dragging
    sliderKnob.MouseButton1Click:Connect(function(x, y, input)
         if not isDragging then -- Only jump if not currently dragging (should be covered by InputBegan/Ended)
             -- This might not fire reliably if InputBegan starts drag.
             -- The main dragging logic handles positioning. This can be left out.
         end
    end)


    return sliderFrame, valueLabel
end


-- Helper for Color Picker Sliders
local function createColorSliderInternal(parent, sliderName, defaultValue, yPosition, baseColor)
    local sliderContainer = createBaseFrame(parent, sliderName .. "Container", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, yPosition), nil, 1)

    createBaseLabel(
        sliderContainer,
        "Label",
        UDim2.new(0, 20, 0, 20),
        UDim2.new(0, 0, 0, 0),
        sliderName,
        styles.TextColor,
        styles.TextSize,
        styles.BoldFont,
        Enum.TextXAlignment.Left
    )

    local valueLabel = createBaseLabel(
        sliderContainer,
        "Value",
        UDim2.new(0, 40, 0, 20),
        UDim2.new(1, -40, 0, 0),
        tostring(math.floor(defaultValue)),
        styles.TextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Right
    )

    -- Slider track
    local sliderTrack = createBaseFrame(sliderContainer, "Track", UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0, 25), styles.SecondaryColor)
    local UICornerTrack = Instance.new("UICorner")
    UICornerTrack.CornerRadius = styles.RoundCornerRadius
    UICornerTrack.Parent = sliderTrack

    -- Slider fill
    local initialRatio = math.clamp(defaultValue / 255, 0, 1)
    local sliderFill = createBaseFrame(sliderTrack, "Fill", UDim2.new(initialRatio, 0, 1, 0), UDim2.new(0, 0, 0, 0), baseColor or styles.AccentColor)
    local UICornerFill = Instance.new("UICorner")
    UICornerFill.CornerRadius = styles.RoundCornerRadius
    UICornerFill.Parent = sliderFill

    -- Slider knob
    local sliderKnob = createBaseFrame(sliderTrack, "Knob", UDim2.new(0, 16, 0, 16), UDim2.new(initialRatio, -8, 0.5, -8), styles.TextColor)
    sliderKnob.ZIndex = 2 -- Above track/fill
    local UICornerKnob = Instance.new("UICorner")
    UICornerKnob.CornerRadius = styles.RoundCornerRadius
    UICornerKnob.Parent = sliderKnob

     local isDragging = false
     local currentValue = defaultValue

     local function updateSlider(input)
         local trackPosition = sliderTrack.AbsolutePosition.X
         local trackWidth = sliderTrack.AbsoluteSize.X
         local mousePosition = input.Position.X

         local ratio = math.clamp((mousePosition - trackPosition) / trackWidth, 0, 1)

         currentValue = math.floor(ratio * 255)

         -- Update UI
         TweenService:Create(sliderFill, TweenInfo.new(0.05), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
         TweenService:Create(sliderKnob, TweenInfo.new(0.05), { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()
         valueLabel.Text = tostring(currentValue)

         -- This function will be called by the main color picker function
         -- to update the preview.
     end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input)
             TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)

     sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
             isDragging = true
             TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)


    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
            isDragging = false
            TweenService:Create(sliderKnob, TweenInfo.new(styles.AnimationSpeed),
                { Size = UDim2.new(0, 16, 0, 16), Position = sliderKnob.Position + UDim2.new(0, 1, 0, 1) }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

     -- Allow clicking anywhere on the track to jump the knob
    sliderTrack.MouseButton1Click:Connect(function(x, y, input)
        if not isDragging then
             updateSlider(input)
        end
    end)


    return sliderContainer, valueLabel -- Return container and value label
end


-- Function to create a color picker
-- Returns: Frame, ColorPreview Frame
function CoreGUI.createColorPicker(parent, colorName, defaultColor, layoutOrder, onChanged)
    local colorFrame = createBaseFrame(
        parent,
        colorName:gsub(" ", "") .. "Color",
        UDim2.new(1, 0, 0, 30),
        nil, -- Position managed by UIListLayout
        nil, -- Transparent
        1
    )
    colorFrame.LayoutOrder = layoutOrder

    createBaseLabel(
        colorFrame,
        "Label",
        UDim2.new(1, -50, 1, 0),
        UDim2.new(0, 0, 0, 0),
        colorName,
        styles.TextColor,
        styles.TextSize,
        styles.Font,
        Enum.TextXAlignment.Left
    )

    -- Color preview
    local colorPreview = createBaseFrame(
        colorFrame,
        "Preview",
        UDim2.new(0, 30, 0, 18),
        UDim2.new(1, -35, 0.5, -9),
        defaultColor
    )
    local UICornerPreview = Instance.new("UICorner")
    UICornerPreview.CornerRadius = styles.SmallCornerRadius
    UICornerPreview.Parent = colorPreview

    -- Color picker button (transparent, covers preview)
    local pickerButton = createBaseButton(
         colorFrame,
         "PickerButton",
         UDim2.new(0, 30, 0, 18),
         UDim2.new(1, -35, 0.5, -9),
         "" -- No text
    )
     pickerButton.ZIndex = 2 -- Above preview frame

    -- Create a unique name for the popup
    local popupName = colorName:gsub(" ", "") .. "Popup"

     -- Check if a popup with this name already exists and remove it
     local existingPopup = colorFrame:FindFirstChild(popupName) -- Check within the color frame's parent (the scrolling frame)
     if existingPopup then
        existingPopup:Destroy()
     end
     -- Note: Popups should ideally be parented higher up, like to the MainFrame,
     -- so they aren't clipped by the scrolling frame. We'll parent it to the MainFrame.
     local mainFrame = parent:FindFirstAncestor("MainFrame") -- Find the main frame


    -- Create color picker popup (initially hidden)
    local colorPickerPopup = createBaseFrame(
        mainFrame, -- Parent to MainFrame to avoid clipping
        popupName,
        UDim2.new(0, 220, 0, 285),
        UDim2.new(0, 0, 0, 0), -- Initial position (will be updated on click)
        styles.TitleBarBackground -- Slightly different background for popup
    )
    colorPickerPopup.Visible = false
    colorPickerPopup.ZIndex = 100 -- Ensure it's on top

    local UICornerPopup = Instance.new("UICorner")
    UICornerPopup.CornerRadius = styles.CornerRadius
    UICornerPopup.Parent = colorPickerPopup

    -- Add a container for content with padding
    local popupContainer = createBaseFrame(colorPickerPopup, "Container", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), nil, 1)
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingTop = styles.InnerPadding
    UIPadding.PaddingBottom = styles.InnerPadding
    UIPadding.PaddingLeft = styles.InnerPadding
    UIPadding.PaddingRight = styles.InnerPadding
    UIPadding.Parent = popupContainer


    -- Color picker title
    createBaseLabel(
        popupContainer,
        "Title",
        UDim2.new(1, -30, 0, 30),
        UDim2.new(0, 0, 0, 0),
        colorName,
        styles.TextColor,
        styles.TitleTextSize,
        styles.BoldFont,
        Enum.TextXAlignment.Left
    )

    -- Close button
    local closeButton = createBaseButton(
        popupContainer,
        "CloseButton",
        UDim2.new(0, 24, 0, 24),
        UDim2.new(1, -24, 0, 3),
        "✕",
        styles.TextColor,
        styles.TextSize + 2, -- Slightly larger X
        styles.BoldFont
    )
     closeButton.ZIndex = 2 -- Above title

     closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.WarningColor }):Play()
    end)
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(styles.AnimationSpeed), { TextColor3 = styles.TextColor }):Play()
    end)


    -- Color preview in popup
    local popupPreview = createBaseFrame(
        popupContainer,
        "PopupPreview",
        UDim2.new(0, 60, 0, 30),
        UDim2.new(0.5, -30, 0, 40),
        defaultColor
    )
    local UICornerPopupPreview = Instance.new("UICorner")
    UICornerPopupPreview.CornerRadius = styles.SmallCornerRadius
    UICornerPopupPreview.Parent = popupPreview


    -- Create RGB sliders
    local redSliderContainer, redValueLabel = createColorSliderInternal(popupContainer, "R", defaultColor.R * 255, 80, styles.RedColor)
    local greenSliderContainer, greenValueLabel = createColorSliderInternal(popupContainer, "G", defaultColor.G * 255, 130, styles.GreenColor)
    local blueSliderContainer, blueValueLabel = createColorSliderInternal(popupContainer, "B", defaultColor.B * 255, 180, styles.BlueColor)

    -- Function to update popup preview based on slider values
    local function updatePopupPreview()
        local r = tonumber(redValueLabel.Text) or 0
        local g = tonumber(greenValueLabel.Text) or 0
        local b = tonumber(blueValueLabel.Text) or 0
        popupPreview.BackgroundColor3 = Color3.fromRGB(r, g, b)
    end

     -- Connect slider value changes to update the popup preview
     redValueLabel.Changed:Connect(function() updatePopupPreview() end)
     greenValueLabel.Changed:Connect(function() updatePopupPreview() end)
     blueValueLabel.Changed:Connect(function() updatePopupPreview() end)

     -- Initial update for popup preview
     updatePopupPreview()


    -- Apply button
    local applyButton = createBaseButton(
        popupContainer,
        "ApplyButton",
        UDim2.new(0, 100, 0, 30),
        UDim2.new(0.5, -50, 1, -40), -- Position relative to container bottom
        "Apply",
        styles.TextColor,
        styles.TextSize,
        styles.BoldFont
    )
    applyButton.BackgroundColor3 = styles.AccentColor
    local UICornerApply = Instance.new("UICorner")
    UICornerApply.CornerRadius = styles.SmallCornerRadius
    UICornerApply.Parent = applyButton

     applyButton.MouseEnter:Connect(function()
        TweenService:Create(applyButton, TweenInfo.new(styles.AnimationSpeed), { BackgroundColor3 = styles.AccentColor + Color3.new(0.1, 0.1, 0.1) }):Play()
    end)
    applyButton.MouseLeave:Connect(function()
        TweenService:Create(applyButton, TweenInfo.new(styles.AnimationSpeed), { BackgroundColor3 = styles.AccentColor }):Play()
    end)

    -- Toggle color picker popup
    pickerButton.MouseButton1Click:Connect(function()
        -- Hide all other dynamic popups before showing this one
        for name, popup in pairs(dynamicPopups) do
            if popup ~= colorPickerPopup and popup.Parent and popup.Parent == mainFrame then
                popup.Visible = false
            end
        end

        local isVisible = colorPickerPopup.Visible
        colorPickerPopup.Visible = not isVisible

        if not isVisible then
            -- Position the popup near the color preview relative to the MainFrame
            local previewAbsPos = colorPreview.AbsolutePosition
            local mainFrameAbsPos = mainFrame.AbsolutePosition

            -- Calculate position relative to MainFrame
            local relativeX = previewAbsPos.X - mainFrameAbsPos.X
            local relativeY = previewAbsPos.Y - mainFrameAbsPos.Y

            -- Adjust position to the left/above the preview and center it roughly
            local desiredX = relativeX - colorPickerPopup.Size.X.Offset - 5 -- To the left
            local desiredY = relativeY - colorPickerPopup.Size.Y.Offset/2 -- Vertically centered relative to preview

            -- Clamp position to stay within the MainFrame bounds
            local maxX = mainFrame.AbsoluteSize.X - colorPickerPopup.Size.X.Offset
            local maxY = mainFrame.AbsoluteSize.Y - colorPickerPopup.Size.Y.Offset
            local clampedX = math.clamp(desiredX, 0, maxX)
            local clampedY = math.clamp(desiredY, 0, maxY)


             -- Adjust X again if clamping happened (e.g., if it hit the left edge)
             -- Try positioning to the right if left is clamped near 0
             if desiredX < 0 and clampedX < 5 then
                clampedX = relativeX + colorPreview.Size.X.Offset + 5 -- Position to the right
                clampedX = math.clamp(clampedX, 0, maxX) -- Clamp again for right side
             end
             -- Adjust Y again if clamping happened (e.g., if it hit the top edge)
             if desiredY < 0 and clampedY < 5 then
                  clampedY = relativeY + colorPreview.Size.Y.Offset/2 -- Position below preview vertically
                  clampedY = math.clamp(clampedY, 0, maxY)
             end


            colorPickerPopup.Position = UDim2.new(0, clampedX, 0, clampedY)
        end
    end)

    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        colorPickerPopup.Visible = false
    end)

    -- Apply color
    applyButton.MouseButton1Click:Connect(function()
        local r = tonumber(redValueLabel.Text) / 255
        local g = tonumber(greenValueLabel.Text) / 255
        local b = tonumber(blueValueLabel.Text) / 255
        local newColor = Color3.new(r, g, b)

        -- Update color preview
        colorPreview.BackgroundColor3 = newColor

        -- Hide popup
        colorPickerPopup.Visible = false

        -- Execute color change functionality
        if onChanged then
            onChanged(colorName, newColor)
        end
    end)

    -- Store popup reference
     dynamicPopups[popupName] = colorPickerPopup

    return colorFrame, colorPreview
end


-- Function to create a content section frame
-- Returns: Frame (the section)
function CoreGUI.createContentSection(parent, name)
    local sectionFrame = createBaseFrame(
        parent,
        name .. "Section",
        UDim2.new(1, -styles.SectionPadding.Offset, 1, -styles.SectionPadding.Offset),
        UDim2.new(0, styles.SectionPadding.Offset / 2, 0, styles.SectionPadding.Offset / 2),
        nil, -- Transparent
        1
    )
    sectionFrame.Visible = false -- Hidden by default

    createBaseLabel(
        sectionFrame,
        name .. "Title",
        UDim2.new(1, 0, 0, 30),
        UDim2.new(0, 0, 0, 0),
        name,
        styles.TextColor,
        styles.TitleTextSize,
        styles.BoldFont,
        Enum.TextXAlignment.Left
    )

    return sectionFrame
end


-- Function to get current styles (for external use if needed)
function CoreGUI.getStyles()
    return styles
end

-- Function to update a style property (e.g., AccentColor)
function CoreGUI.updateStyle(styleName, value)
    if styles[styleName] ~= nil then
        styles[styleName] = value
        -- Note: Updating UI elements that *already exist* requires
        -- iterating through them in the main script, as the library
        -- doesn't keep a global list of all created elements.
        -- The main script should handle re-applying colors based on the updated styles.
    end
end


return CoreGUI
