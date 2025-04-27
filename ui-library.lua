-- ModuleScript in ReplicatedStorage named "SharkHackLib"
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}

-- Default Settings (can be overridden)
Library.Settings = {
	AnimationSpeed = 0.3,
	EaseStyle = Enum.EasingStyle.Quart,
	EaseDirection = Enum.EasingDirection.Out,
	ThemeColor = Color3.fromRGB(78, 93, 234),
	AccentColor = Color3.fromRGB(255, 255, 255),
	BackgroundColor = Color3.fromRGB(20, 20, 25),
	SecondaryBackgroundColor = Color3.fromRGB(25, 25, 30),
	InactiveColor = Color3.fromRGB(150, 150, 150),
	TitleBarColor = Color3.fromRGB(15, 15, 20),
    TextColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    ToggleOffColor = Color3.fromRGB(40, 40, 45),
    SliderTrackColor = Color3.fromRGB(40, 40, 45),
    ScrollBarThickness = 4,
}

-- Internal helper for tweening
local function tween(instance, properties, overrideInfo)
	local info = overrideInfo or TweenInfo.new(
        Library.Settings.AnimationSpeed,
        Library.Settings.EaseStyle,
        Library.Settings.EaseDirection
    )
	return TweenService:Create(instance, info, properties)
end

--[[
	Creates the main window structure.
	@param title The text displayed in the title bar.
	@param size The UDim2 size of the window.
	@param position The UDim2 position of the window.
	@returns A table containing { screenGui, mainFrame, titleBar, contentArea, sidebarContainer }
]]
function Library.CreateWindow(title, size, position)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SharkHackGUI_LibInstance" -- Give unique name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = size
	mainFrame.Position = position
	mainFrame.BackgroundColor3 = Library.Settings.BackgroundColor
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true -- Important for minimize animation
	mainFrame.Parent = screenGui

	-- Add window title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Library.Settings.TitleBarColor
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	-- Title text
	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleText"
	titleText.Size = UDim2.new(1, -100, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = title
	titleText.TextColor3 = Library.Settings.TextColor
	titleText.TextSize = 16
	titleText.Font = Library.Settings.FontBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -30, 0, 0)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "✕"
	closeButton.TextColor3 = Library.Settings.TextColor
	closeButton.TextSize = 16
	closeButton.Font = Library.Settings.FontBold
	closeButton.Parent = titleBar

	-- Minimize button
	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -60, 0, 0)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "−"
	minimizeButton.TextColor3 = Library.Settings.TextColor
	minimizeButton.TextSize = 16
	minimizeButton.Font = Library.Settings.FontBold
	minimizeButton.Parent = titleBar

	-- Container for the sidebar (allows easy positioning)
	local sidebarContainer = Instance.new("Frame")
	sidebarContainer.Name = "SidebarContainer"
	sidebarContainer.Size = UDim2.new(0, 165, 1, -30)
	sidebarContainer.Position = UDim2.new(0, 0, 0, 30)
	sidebarContainer.BackgroundTransparency = 1 -- Container is transparent
	sidebarContainer.BorderSizePixel = 0
	sidebarContainer.Parent = mainFrame

	-- Content area
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -165, 1, -30)
	contentArea.Position = UDim2.new(0, 165, 0, 30)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	-- Make window draggable
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function updateDrag(input)
		local delta = input.Position - dragStart
		local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		tween(mainFrame, { Position = targetPosition }, TweenInfo.new(0.05)):Play() -- Faster tween for dragging
	end

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			tween(titleBar, { BackgroundColor3 = Library.Settings.TitleBarColor:Lerp(Color3.new(0,0,0), 0.3) }, TweenInfo.new(0.1)):Play()

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					tween(titleBar, { BackgroundColor3 = Library.Settings.TitleBarColor }, TweenInfo.new(0.1)):Play()
				end
			end)
		end
	end)

	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			updateDrag(input)
		end
	end)

	-- Close button behavior
	closeButton.MouseEnter:Connect(function() tween(closeButton, { TextColor3 = Color3.fromRGB(255, 100, 100) }, TweenInfo.new(0.2)):Play() end)
	closeButton.MouseLeave:Connect(function() tween(closeButton, { TextColor3 = Library.Settings.TextColor }, TweenInfo.new(0.2)):Play() end)
	closeButton.MouseButton1Click:Connect(function()
		tween(mainFrame, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 0), Position = UDim2.new(position.X.Scale, position.X.Offset, 0.5, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)):Play()
		task.wait(0.3)
		screenGui:Destroy()
	end)

	-- Minimize button behavior
	local isMinimized = false
	minimizeButton.MouseEnter:Connect(function() tween(minimizeButton, { TextColor3 = Color3.fromRGB(100, 200, 255) }, TweenInfo.new(0.2)):Play() end)
	minimizeButton.MouseLeave:Connect(function() tween(minimizeButton, { TextColor3 = Library.Settings.TextColor }, TweenInfo.new(0.2)):Play() end)
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			sidebarContainer.Visible = false
			contentArea.Visible = false
			tween(mainFrame, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 30) }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)):Play()
			minimizeButton.Text = "+"
		else
			tween(mainFrame, { Size = size }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)):Play()
			task.wait(0.1) -- Wait slightly for frame to resize before making children visible
			sidebarContainer.Visible = true
			contentArea.Visible = true
			minimizeButton.Text = "−"
		end
	end)

	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		titleBar = titleBar,
		contentArea = contentArea,
		sidebarContainer = sidebarContainer,
        closeButton = closeButton,
        minimizeButton = minimizeButton
	}
end

--[[
	Adds the sidebar frame itself.
	@param sidebarContainer The container frame returned by CreateWindow.
	@returns The sidebar frame.
]]
function Library.AddSidebar(sidebarContainer)
    local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(1, 0, 1, 0) -- Fill the container
	sidebar.BackgroundColor3 = Library.Settings.SecondaryBackgroundColor
	sidebar.BorderSizePixel = 0
	sidebar.Parent = sidebarContainer
    return sidebar
end

--[[
	Adds a logo area to the sidebar.
	@param sidebar The sidebar frame returned by AddSidebar.
	@param logoText The text to display below the logo.
]]
function Library.AddLogo(sidebar, logoText)
	local logoArea = Instance.new("Frame")
	logoArea.Name = "LogoArea"
	logoArea.Size = UDim2.new(1, 0, 0, 110)
	logoArea.BackgroundTransparency = 1
	logoArea.Parent = sidebar

	local sharkLogo = Instance.new("Frame")
	sharkLogo.Name = "SharkLogo"
	sharkLogo.Size = UDim2.new(0, 60, 0, 60)
	sharkLogo.Position = UDim2.new(0.5, -30, 0, 15)
	sharkLogo.BackgroundTransparency = 1
	sharkLogo.Parent = logoArea

	local logoTriangle = Instance.new("Frame")
	logoTriangle.Name = "LogoTriangle"
	logoTriangle.Size = UDim2.new(0, 50, 0, 40)
	logoTriangle.Position = UDim2.new(0.5, -25, 0.5, -20)
	logoTriangle.BackgroundTransparency = 1
	logoTriangle.Parent = sharkLogo

	local uiGradient = Instance.new("UIGradient")
	uiGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0),NumberSequenceKeypoint.new(0.5, 0),NumberSequenceKeypoint.new(0.5001, 1),NumberSequenceKeypoint.new(1, 1)})
	uiGradient.Rotation = 45
	uiGradient.Parent = logoTriangle

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Library.Settings.TextColor
	uiStroke.Thickness = 2
	uiStroke.Parent = logoTriangle

	local logoTextLabel = Instance.new("TextLabel")
	logoTextLabel.Name = "LogoText"
	logoTextLabel.Size = UDim2.new(1, 0, 0, 30)
	logoTextLabel.Position = UDim2.new(0, 0, 0, 80)
	logoTextLabel.BackgroundTransparency = 1
	logoTextLabel.Text = logoText
	logoTextLabel.TextColor3 = Library.Settings.TextColor
	logoTextLabel.TextSize = 18
	logoTextLabel.Font = Library.Settings.FontBold
	logoTextLabel.Parent = logoArea

    return logoArea
end

--[[
	Adds a category button to the sidebar.
	@param sidebar The sidebar frame.
	@param name The category name (used for identification and label).
	@param iconData Table containing { id, offset, size } for the icon.
	@param layoutOrder The LayoutOrder for this button.
	@param onClickCallback Function to call when the button is clicked, passes `name`.
    @returns Table containing { buttonFrame, iconButton, label, highlight }
]]
function Library.AddCategoryButton(sidebar, name, iconData, layoutOrder, onClickCallback)
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Name = name .. "Button"
	buttonFrame.Size = UDim2.new(1, 0, 0, 40)
	-- Position will be handled by UIListLayout in the calling script
	buttonFrame.BackgroundTransparency = 1
    buttonFrame.LayoutOrder = layoutOrder
	buttonFrame.Parent = sidebar

	local iconButton = Instance.new("ImageButton")
	iconButton.Name = "Icon"
	iconButton.Size = UDim2.new(0, 24, 0, 24)
	iconButton.Position = UDim2.new(0, 30, 0.5, -12)
	iconButton.BackgroundTransparency = 1
	iconButton.Image = iconData.id
	iconButton.ImageRectOffset = iconData.offset
	iconButton.ImageRectSize = iconData.size or Vector2.new(36, 36) -- Default size
	iconButton.ImageColor3 = Library.Settings.InactiveColor -- Start inactive
	iconButton.Parent = buttonFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 100, 1, 0)
	label.Position = UDim2.new(0, 65, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Library.Settings.InactiveColor -- Start inactive
	label.TextSize = 14
	label.Font = Library.Settings.Font
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = buttonFrame

	local hoverHighlight = Instance.new("Frame")
	hoverHighlight.Name = "HoverHighlight"
	hoverHighlight.Size = UDim2.new(0.95, 0, 0.8, 0)
	hoverHighlight.Position = UDim2.new(0.025, 0, 0.1, 0)
	hoverHighlight.BackgroundColor3 = Library.Settings.ThemeColor
	hoverHighlight.BackgroundTransparency = 1 -- Start hidden
	hoverHighlight.BorderSizePixel = 0
	hoverHighlight.ZIndex = 0
	hoverHighlight.Parent = buttonFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = hoverHighlight

    local isSelected = false -- Track selection state

    local function updateVisuals(selected)
        local iconColor = selected and Library.Settings.ThemeColor or Library.Settings.InactiveColor
        local textColor = selected and Library.Settings.TextColor or Library.Settings.InactiveColor
        local highlightTransparency = selected and 0.8 or 1

        -- Apply immediately (no tween needed for selection state change)
        iconButton.ImageColor3 = iconColor
        label.TextColor3 = textColor
        hoverHighlight.BackgroundTransparency = highlightTransparency
    end

	buttonFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if onClickCallback then onClickCallback(name) end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			if not isSelected then -- Only show hover if not selected
                tween(hoverHighlight, { BackgroundTransparency = 0.8 }, TweenInfo.new(0.2)):Play()
            end
		end
	end)

	buttonFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
            if not isSelected then -- Only hide hover if not selected
			    tween(hoverHighlight, { BackgroundTransparency = 1 }, TweenInfo.new(0.2)):Play()
            end
		end
	end)

	iconButton.MouseButton1Click:Connect(function()
		if onClickCallback then onClickCallback(name) end
	end)

	return {
		buttonFrame = buttonFrame,
		iconButton = iconButton,
		label = label,
		highlight = hoverHighlight,
        -- Function to visually update the button based on selection state
        SetSelected = function(selected)
            isSelected = selected
            updateVisuals(selected)
        end
	}
end

--[[
	Adds a content section (usually a scrolling frame) to the content area.
	@param contentArea The content area frame returned by CreateWindow.
	@param sectionName The name for the section frame.
    @param isVisible Should this section be visible initially?
	@returns Table containing { sectionFrame, scrollFrame, listLayout }
]]
function Library.AddSection(contentArea, sectionName, isVisible)
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = sectionName .. "Section"
	sectionFrame.Size = UDim2.new(1, -20, 1, -20)
	sectionFrame.Position = UDim2.new(0, 10, 0, 10)
	sectionFrame.BackgroundTransparency = 1
	sectionFrame.Visible = isVisible
	sectionFrame.Parent = contentArea

	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Name = sectionName .. "Title"
	sectionTitle.Size = UDim2.new(1, 0, 0, 30)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.Text = sectionName
	sectionTitle.TextColor3 = Library.Settings.TextColor
	sectionTitle.TextSize = 16
	sectionTitle.Font = Library.Settings.FontBold
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.Parent = sectionFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollingContent"
	scrollFrame.Size = UDim2.new(1, 0, 1, -40)
	scrollFrame.Position = UDim2.new(0, 0, 0, 40)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = Library.Settings.ScrollBarThickness
	scrollFrame.ScrollBarImageColor3 = Library.Settings.ThemeColor
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	scrollFrame.Parent = sectionFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scrollFrame

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 5)
	uiPadding.PaddingLeft = UDim.new(0, 5)
	uiPadding.PaddingRight = UDim.new(0, 5)
	uiPadding.Parent = scrollFrame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	return {
		sectionFrame = sectionFrame,
		scrollFrame = scrollFrame,
		listLayout = listLayout
	}
end

--[[
	Adds a toggle switch element.
	@param parent The parent frame (usually a scrollFrame).
	@param optionName The label text and identifier.
	@param isEnabledDefault The initial state of the toggle.
	@param layoutOrder The LayoutOrder for this element.
	@param onChangeCallback Function called when toggled, passes `optionName, isEnabled`.
	@returns Table containing { optionFrame, toggleButton, indicator, label }
]]
function Library.AddToggle(parent, optionName, isEnabledDefault, layoutOrder, onChangeCallback)
	local optionFrame = Instance.new("Frame")
	optionFrame.Name = optionName .. "Option"
	optionFrame.Size = UDim2.new(1, 0, 0, 30)
	optionFrame.BackgroundTransparency = 1
	optionFrame.LayoutOrder = layoutOrder
	optionFrame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -50, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = optionName
	label.TextColor3 = Library.Settings.TextColor
	label.TextSize = 14
	label.Font = Library.Settings.Font
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = optionFrame

	local toggleButton = Instance.new("Frame") -- Using Frame for better visual control
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 40, 0, 20)
	toggleButton.Position = UDim2.new(1, -45, 0.5, -10)
	toggleButton.BackgroundColor3 = isEnabledDefault and Library.Settings.ThemeColor or Library.Settings.ToggleOffColor
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = optionFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = toggleButton

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 16, 0, 16)
	indicator.Position = isEnabledDefault and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	indicator.BackgroundColor3 = Library.Settings.AccentColor
	indicator.BorderSizePixel = 0
	indicator.Parent = toggleButton

	local uiCornerIndicator = Instance.new("UICorner")
	uiCornerIndicator.CornerRadius = UDim.new(1, 0)
	uiCornerIndicator.Parent = indicator

    -- Use a TextButton overlay for input detection
    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "ClickDetector"
    clickDetector.Size = UDim2.new(1,0,1,0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 2 -- Make sure it's above the frame/indicator
    clickDetector.Parent = toggleButton

	clickDetector.MouseButton1Click:Connect(function()
		local isCurrentlyEnabled = toggleButton.BackgroundColor3 == Library.Settings.ThemeColor
		local newState = not isCurrentlyEnabled

		local newColor = newState and Library.Settings.ThemeColor or Library.Settings.ToggleOffColor
		local newPosition = newState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)

		tween(toggleButton, { BackgroundColor3 = newColor }, TweenInfo.new(0.2)):Play()
		tween(indicator, { Position = newPosition }, TweenInfo.new(0.2)):Play()

		if onChangeCallback then onChangeCallback(optionName, newState) end
	end)

	return {
		optionFrame = optionFrame,
		toggleButton = toggleButton,
		indicator = indicator,
		label = label
	}
end

--[[
	Adds a slider element.
	@param parent The parent frame.
	@param sliderName The label text and identifier.
	@param defaultValue The initial value.
	@param minValue The minimum value.
	@param maxValue The maximum value.
    @param increment The step value (e.g., 0.1, 1). Defaults to 1.
	@param layoutOrder The LayoutOrder.
	@param onChangeCallback Function called when value changes, passes `sliderName, value`.
	@returns Table containing { sliderFrame, valueLabel, sliderValue }
]]
function Library.AddSlider(parent, sliderName, defaultValue, minValue, maxValue, increment, layoutOrder, onChangeCallback)
	increment = increment or 1 -- Default increment to 1 if not provided
    local numDecimalPlaces = 0
    if increment < 1 then
        numDecimalPlaces = -math.log10(increment)
    end

    local function roundValue(value)
        local factor = 10^numDecimalPlaces
        return math.floor(value / increment + 0.5) * increment
        --return math.floor((value / increment) + 0.5) * increment
        --return math.floor( (value / increment) + 0.5 ) * increment --math.floor(value * factor + 0.5) / factor
    end

    local currentValue = roundValue(math.clamp(defaultValue, minValue, maxValue))

	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = sliderName .. "Slider"
	sliderFrame.Size = UDim2.new(1, 0, 0, 50)
	sliderFrame.BackgroundTransparency = 1
	sliderFrame.LayoutOrder = layoutOrder
	sliderFrame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = sliderName
	label.TextColor3 = Library.Settings.TextColor
	label.TextSize = 14
	label.Font = Library.Settings.Font
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = sliderFrame

	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "Track"
	sliderTrack.Size = UDim2.new(1, -60, 0, 6)
	sliderTrack.Position = UDim2.new(0, 0, 0, 30)
	sliderTrack.BackgroundColor3 = Library.Settings.SliderTrackColor
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Parent = sliderFrame

	local uiCornerTrack = Instance.new("UICorner")
	uiCornerTrack.CornerRadius = UDim.new(1, 0)
	uiCornerTrack.Parent = sliderTrack

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
    local initialRatio = (currentValue - minValue) / (maxValue - minValue)
	fill.Size = UDim2.new(initialRatio, 0, 1, 0)
	fill.BackgroundColor3 = Library.Settings.ThemeColor
	fill.BorderSizePixel = 0
	fill.Parent = sliderTrack

	local uiCornerFill = Instance.new("UICorner")
	uiCornerFill.CornerRadius = UDim.new(1, 0)
	uiCornerFill.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = UDim2.new(initialRatio, -8, 0.5, -8)
	knob.BackgroundColor3 = Library.Settings.AccentColor
	knob.BorderSizePixel = 0
    knob.ZIndex = 2
	knob.Parent = sliderTrack

	local uiCornerKnob = Instance.new("UICorner")
	uiCornerKnob.CornerRadius = UDim.new(1, 0)
	uiCornerKnob.Parent = knob

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0, 50, 0, 20)
	valueLabel.Position = UDim2.new(1, -50, 0, 23)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = string.format("%."..numDecimalPlaces.."f", currentValue) -- Format based on increment
	valueLabel.TextColor3 = Library.Settings.TextColor
	valueLabel.TextSize = 14
	valueLabel.Font = Library.Settings.Font
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = sliderFrame

	local isDragging = false

	local function updateSlider(inputPosition)
		local trackPosition = sliderTrack.AbsolutePosition.X
		local trackWidth = sliderTrack.AbsoluteSize.X
		local mousePosition = inputPosition.X

		local ratio = math.clamp((mousePosition - trackPosition) / trackWidth, 0, 1)
		local newValueRaw = minValue + ratio * (maxValue - minValue)
        local newValueRounded = roundValue(newValueRaw)

        -- Only update if the rounded value actually changed
		if newValueRounded ~= currentValue then
            currentValue = newValueRounded
            local displayRatio = (currentValue - minValue) / (maxValue - minValue) -- Use rounded value for display ratio

            tween(fill, { Size = UDim2.new(displayRatio, 0, 1, 0) }, TweenInfo.new(0.05)):Play()
            tween(knob, { Position = UDim2.new(displayRatio, -8, 0.5, -8) }, TweenInfo.new(0.05)):Play()
            valueLabel.Text = string.format("%."..numDecimalPlaces.."f", currentValue)

            if onChangeCallback then onChangeCallback(sliderName, currentValue) end
        end
	end

    -- Use TextButtons for input detection on track and knob
    local trackButton = Instance.new("TextButton")
    trackButton.Name = "TrackButton"
    trackButton.Size = UDim2.new(1,0,3,0) -- Make slightly larger vertically for easier clicking
    trackButton.Position = UDim2.new(0,0,0.5,-1.5 * trackButton.AbsoluteSize.Y)
    trackButton.BackgroundTransparency = 1
    trackButton.Text = ""
    trackButton.ZIndex = 1
    trackButton.Parent = sliderTrack

    local knobButton = Instance.new("TextButton")
    knobButton.Name = "KnobButton"
    knobButton.Size = UDim2.new(1,0,1,0)
    knobButton.BackgroundTransparency = 1
    knobButton.Text = ""
    knobButton.ZIndex = 3 -- Above knob visual
    knobButton.Parent = knob


	trackButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			updateSlider(input.Position)
			tween(knob, { Size = UDim2.new(0, 18, 0, 18), Position = knob.Position - UDim2.new(0, 1, 0, 1) }, TweenInfo.new(0.1)):Play()
		end
	end)

	knobButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			tween(knob, { Size = UDim2.new(0, 18, 0, 18), Position = knob.Position - UDim2.new(0, 1, 0, 1) }, TweenInfo.new(0.1)):Play()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
			isDragging = false
			tween(knob, { Size = UDim2.new(0, 16, 0, 16), Position = knob.Position + UDim2.new(0, 1, 0, 1) }, TweenInfo.new(0.1)):Play()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position)
		end
	end)

	return {
		sliderFrame = sliderFrame,
		valueLabel = valueLabel,
		sliderValue = function() return currentValue end -- Return a function to get current value
	}
end


--[[
	Adds a color picker element.
	@param parent The parent frame.
    @param rootInstance The top-level frame (MainFrame) to parent the popup to.
	@param colorName The label text and identifier.
	@param defaultColor The initial Color3 value.
	@param layoutOrder The LayoutOrder.
	@param onChangeCallback Function called when color is applied, passes `colorName, newColor`.
	@returns Table containing { colorFrame, preview }
]]
function Library.AddColorPicker(parent, rootInstance, colorName, defaultColor, layoutOrder, onChangeCallback)
    local currentColor = defaultColor

    local colorFrame = Instance.new("Frame")
    colorFrame.Name = colorName .. "Color"
    colorFrame.Size = UDim2.new(1, 0, 0, 30)
    colorFrame.BackgroundTransparency = 1
    colorFrame.LayoutOrder = layoutOrder
    colorFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = colorName
    label.TextColor3 = Library.Settings.TextColor
    label.TextSize = 14
    label.Font = Library.Settings.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = colorFrame

    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Size = UDim2.new(0, 30, 0, 18)
    preview.Position = UDim2.new(1, -35, 0.5, -9)
    preview.BackgroundColor3 = currentColor
    preview.BorderSizePixel = 1
    preview.BorderColor3 = Color3.fromRGB(80, 80, 80)
    preview.Parent = colorFrame

    local uiCornerPreview = Instance.new("UICorner")
    uiCornerPreview.CornerRadius = UDim.new(0, 4)
    uiCornerPreview.Parent = preview

    local pickerButton = Instance.new("TextButton")
    pickerButton.Name = "PickerButton"
    pickerButton.Size = UDim2.new(1,0,1,0) -- Cover the whole preview area
    pickerButton.Position = UDim2.new(0,0,0,0)
    pickerButton.BackgroundTransparency = 1
    pickerButton.Text = ""
    pickerButton.ZIndex = 2
    pickerButton.Parent = preview

    -- Create color picker popup (initially hidden) - Parent to rootInstance
    local popup = Instance.new("Frame")
    popup.Name = colorName .. "Popup"
    popup.Size = UDim2.new(0, 220, 0, 285) -- Adjusted size for better layout
    popup.BackgroundColor3 = Library.Settings.SecondaryBackgroundColor:Lerp(Color3.new(0,0,0), 0.1) -- Slightly darker popup
    popup.BorderSizePixel = 1
    popup.BorderColor3 = Color3.fromRGB(50,50,50)
    popup.Visible = false
    popup.ZIndex = 100 -- Ensure it's above other elements
    popup.ClipsDescendants = true
    popup.Parent = rootInstance -- Parent to main window frame

    local uiCornerPopup = Instance.new("UICorner")
    uiCornerPopup.CornerRadius = UDim.new(0, 6)
    uiCornerPopup.Parent = popup

    local popupContainer = Instance.new("Frame")
    popupContainer.Name = "Container"
    popupContainer.Size = UDim2.new(1, 0, 1, 0)
    popupContainer.BackgroundTransparency = 1
    popupContainer.Parent = popup

    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, 10)
    uiPadding.PaddingBottom = UDim.new(0, 10)
    uiPadding.PaddingLeft = UDim.new(0, 15)
    uiPadding.PaddingRight = UDim.new(0, 15)
    uiPadding.Parent = popupContainer

    local pickerTitle = Instance.new("TextLabel")
	pickerTitle.Name = "Title"
	pickerTitle.Size = UDim2.new(1, -30, 0, 30)
	pickerTitle.Position = UDim2.new(0, 0, 0, 0)
	pickerTitle.BackgroundTransparency = 1
	pickerTitle.Text = colorName
	pickerTitle.TextColor3 = Library.Settings.TextColor
	pickerTitle.TextSize = 16
	pickerTitle.Font = Library.Settings.FontBold
	pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
	pickerTitle.Parent = popupContainer

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -24, 0, 3)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = Library.Settings.InactiveColor
    closeButton.TextSize = 16
    closeButton.Font = Library.Settings.FontBold
    closeButton.ZIndex = 101
    closeButton.Parent = popupContainer

	closeButton.MouseEnter:Connect(function() tween(closeButton, { TextColor3 = Library.Settings.TextColor }, TweenInfo.new(0.1)):Play() end)
	closeButton.MouseLeave:Connect(function() tween(closeButton, { TextColor3 = Library.Settings.InactiveColor }, TweenInfo.new(0.1)):Play() end)
    closeButton.MouseButton1Click:Connect(function() popup.Visible = false end)


    local popupPreview = Instance.new("Frame")
    popupPreview.Name = "PopupPreview"
    popupPreview.Size = UDim2.new(0, 60, 0, 30)
    popupPreview.Position = UDim2.new(0.5, -30, 0, 40)
    popupPreview.BackgroundColor3 = currentColor
    popupPreview.BorderSizePixel = 1
    popupPreview.BorderColor3 = Color3.fromRGB(80, 80, 80)
    popupPreview.Parent = popupContainer

    local uiCornerPopupPreview = Instance.new("UICorner")
    uiCornerPopupPreview.CornerRadius = UDim.new(0, 4)
    uiCornerPopupPreview.Parent = popupPreview

    -- Helper for color sliders inside the popup
    local function createColorSlider(container, sliderName, initialValue, yPos, color)
        local value = math.floor(initialValue * 255)

        local sliderContainer = Instance.new("Frame")
        sliderContainer.Name = sliderName .. "Container"
        sliderContainer.Size = UDim2.new(1, 0, 0, 40)
        sliderContainer.Position = UDim2.new(0, 0, 0, yPos)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.Parent = container

        local sliderLabel = Instance.new("TextLabel")
        sliderLabel.Name = "Label"
        sliderLabel.Size = UDim2.new(0, 20, 0, 20)
        sliderLabel.Position = UDim2.new(0, 0, 0, 0)
        sliderLabel.BackgroundTransparency = 1
        sliderLabel.Text = sliderName
        sliderLabel.TextColor3 = Library.Settings.TextColor
        sliderLabel.TextSize = 14
        sliderLabel.Font = Library.Settings.FontBold
        sliderLabel.Parent = sliderContainer

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(0, 40, 0, 20)
        valueLabel.Position = UDim2.new(1, -40, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(value)
        valueLabel.TextColor3 = Library.Settings.TextColor
        valueLabel.TextSize = 14
        valueLabel.Font = Library.Settings.Font
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = sliderContainer

        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Size = UDim2.new(1, 0, 0, 6)
        sliderTrack.Position = UDim2.new(0, 0, 0, 25)
        sliderTrack.BackgroundColor3 = Library.Settings.SliderTrackColor
        sliderTrack.BorderSizePixel = 0
        sliderTrack.Parent = sliderContainer

        local uiCornerTrack = Instance.new("UICorner")
        uiCornerTrack.CornerRadius = UDim.new(1, 0)
        uiCornerTrack.Parent = sliderTrack

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new(value / 255, 0, 1, 0)
        fill.BackgroundColor3 = color
        fill.BorderSizePixel = 0
        fill.Parent = sliderTrack

        local uiCornerFill = Instance.new("UICorner")
        uiCornerFill.CornerRadius = UDim.new(1, 0)
        uiCornerFill.Parent = fill

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(value / 255, -8, 0.5, -8)
        knob.BackgroundColor3 = Library.Settings.AccentColor
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = sliderTrack

        local uiCornerKnob = Instance.new("UICorner")
        uiCornerKnob.CornerRadius = UDim.new(1, 0)
        uiCornerKnob.Parent = knob

        local isDragging = false

        local function updateColorSlider(inputPosition)
            local trackPosition = sliderTrack.AbsolutePosition.X
            local trackWidth = sliderTrack.AbsoluteSize.X
            local mousePosition = inputPosition.X

            local ratio = math.clamp((mousePosition - trackPosition) / trackWidth, 0, 1)
            local newValue = math.floor(ratio * 255)

            if newValue ~= tonumber(valueLabel.Text) then
                valueLabel.Text = tostring(newValue)
                tween(fill, { Size = UDim2.new(ratio, 0, 1, 0) }, TweenInfo.new(0.05)):Play()
                tween(knob, { Position = UDim2.new(ratio, -8, 0.5, -8) }, TweenInfo.new(0.05)):Play()

                -- Update popup preview immediately
                local r = tonumber(popupContainer.RContainer.Value.Text) or 0
                local g = tonumber(popupContainer.GContainer.Value.Text) or 0
                local b = tonumber(popupContainer.BContainer.Value.Text) or 0
                popupPreview.BackgroundColor3 = Color3.fromRGB(r, g, b)
            end
        end

        -- Input Buttons
        local trackButton = Instance.new("TextButton")
        trackButton.Name = "TrackButton"
        trackButton.Size = UDim2.new(1,0,3,0)
        trackButton.Position = UDim2.new(0,0,0.5,-1.5 * trackButton.AbsoluteSize.Y)
        trackButton.BackgroundTransparency = 1
        trackButton.Text = ""
        trackButton.ZIndex = 1
        trackButton.Parent = sliderTrack

        local knobButton = Instance.new("TextButton")
        knobButton.Name = "KnobButton"
        knobButton.Size = UDim2.new(1,0,1,0)
        knobButton.BackgroundTransparency = 1
        knobButton.Text = ""
        knobButton.ZIndex = 3
        knobButton.Parent = knob

        trackButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; updateColorSlider(input.Position); end end)
        knobButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false; end end)
        UserInputService.InputChanged:Connect(function(input) if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateColorSlider(input.Position); end end)

        return { container = sliderContainer, valueLabel = valueLabel }
    end

    -- Create RGB sliders
    local redSlider = createColorSlider(popupContainer, "R", currentColor.R, 80, Color3.fromRGB(255, 50, 50))
    local greenSlider = createColorSlider(popupContainer, "G", currentColor.G, 130, Color3.fromRGB(50, 255, 50))
    local blueSlider = createColorSlider(popupContainer, "B", currentColor.B, 180, Color3.fromRGB(50, 50, 255))

    -- Apply button
    local applyButton = Instance.new("TextButton")
    applyButton.Name = "ApplyButton"
    applyButton.Size = UDim2.new(0, 100, 0, 30)
    applyButton.Position = UDim2.new(0.5, -50, 1, -40)
    applyButton.BackgroundColor3 = Library.Settings.ThemeColor
    applyButton.BorderSizePixel = 0
    applyButton.Text = "Apply"
    applyButton.TextColor3 = Library.Settings.TextColor
    applyButton.TextSize = 14
    applyButton.Font = Library.Settings.FontBold
    applyButton.ZIndex = 100
    applyButton.Parent = popupContainer

    local uiCornerApply = Instance.new("UICorner")
    uiCornerApply.CornerRadius = UDim.new(0, 4)
    uiCornerApply.Parent = applyButton

    applyButton.MouseEnter:Connect(function() tween(applyButton, { BackgroundColor3 = Library.Settings.ThemeColor:Lerp(Color3.new(1,1,1), 0.2) }, TweenInfo.new(0.1)):Play() end)
    applyButton.MouseLeave:Connect(function() tween(applyButton, { BackgroundColor3 = Library.Settings.ThemeColor }, TweenInfo.new(0.1)):Play() end)

    applyButton.MouseButton1Click:Connect(function()
        local r = tonumber(redSlider.valueLabel.Text) / 255
        local g = tonumber(greenSlider.valueLabel.Text) / 255
        local b = tonumber(blueSlider.valueLabel.Text) / 255
        local newColor = Color3.new(r, g, b)

        currentColor = newColor
        preview.BackgroundColor3 = newColor
        popup.Visible = false

        if onChangeCallback then onChangeCallback(colorName, newColor) end
    end)

    -- Toggle popup visibility
    pickerButton.MouseButton1Click:Connect(function()
         -- Hide all other popups first
        for _, child in ipairs(rootInstance:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("Popup$") and child ~= popup then
                child.Visible = false
            end
        end

        -- Position and show/hide this popup
        local previewAbsPos = preview.AbsolutePosition
        local previewAbsSize = preview.AbsoluteSize
        local rootAbsSize = rootInstance.AbsoluteSize
        local popupSize = popup.AbsoluteSize

        -- Attempt to position below and centered, fallback to above
        local targetX = previewAbsPos.X + previewAbsSize.X / 2 - popupSize.X / 2
        local targetY = previewAbsPos.Y + previewAbsSize.Y + 5 -- Below

        -- Adjust if off-screen
        if targetX < 5 then targetX = 5 end
        if targetX + popupSize.X > rootAbsSize.X - 5 then targetX = rootAbsSize.X - 5 - popupSize.X end
        if targetY + popupSize.Y > rootAbsSize.Y - 5 then targetY = previewAbsPos.Y - popupSize.Y - 5 end -- Above
        if targetY < 5 then targetY = 5 end -- Fallback if still offscreen

        popup.Position = UDim2.fromOffset(targetX, targetY)
        popup.Visible = not popup.Visible

        -- If becoming visible, reset sliders to current color
        if popup.Visible then
            redSlider.valueLabel.Text = tostring(math.floor(currentColor.R * 255))
            greenSlider.valueLabel.Text = tostring(math.floor(currentColor.G * 255))
            blueSlider.valueLabel.Text = tostring(math.floor(currentColor.B * 255))
            local rRatio, gRatio, bRatio = currentColor.R, currentColor.G, currentColor.B
            popupContainer.RContainer.Track.Fill.Size = UDim2.new(rRatio, 0, 1, 0)
            popupContainer.GContainer.Track.Fill.Size = UDim2.new(gRatio, 0, 1, 0)
            popupContainer.BContainer.Track.Fill.Size = UDim2.new(bRatio, 0, 1, 0)
            popupContainer.RContainer.Track.Knob.Position = UDim2.new(rRatio, -8, 0.5, -8)
            popupContainer.GContainer.Track.Knob.Position = UDim2.new(gRatio, -8, 0.5, -8)
            popupContainer.BContainer.Track.Knob.Position = UDim2.new(bRatio, -8, 0.5, -8)
            popupPreview.BackgroundColor3 = currentColor
        end
    end)

    return {
        colorFrame = colorFrame,
        preview = preview,
        popup = popup -- Return popup in case user wants to manage visibility externally
    }
end


--[[
	Applies entrance animation to the window.
	@param windowElements The table returned by CreateWindow.
]]
function Library.AnimateEntrance(windowElements)
    local mainFrame = windowElements.mainFrame
    local originalSize = mainFrame.Size
    local originalPosition = mainFrame.Position

    mainFrame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)
    mainFrame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 0.5, 0)
    windowElements.screenGui.Enabled = true

    tween(mainFrame, { Size = originalSize, Position = originalPosition }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)):Play()
end

--[[
	Applies exit animation and toggles visibility.
	@param windowElements The table returned by CreateWindow.
    @param callback Optional function to call after animation completes.
]]
function Library.AnimateToggleVisibility(windowElements, callback)
    local mainFrame = windowElements.mainFrame
    local screenGui = windowElements.screenGui
    local originalSize = mainFrame.Size -- Assuming it's currently visible
    local originalPosition = mainFrame.Position

    if screenGui.Enabled then
        -- Hide
        tween(mainFrame, { Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0), Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 0.5, 0) }, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)):Play()
        task.wait(0.3)
        screenGui.Enabled = false
    else
        -- Show
        mainFrame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)
        mainFrame.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 0.5, 0)
        screenGui.Enabled = true
        tween(mainFrame, { Size = originalSize, Position = originalPosition }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)):Play()
    end

    if callback then
        task.wait(0.5) -- Wait for potential show animation
        callback()
    end
end

return Library
