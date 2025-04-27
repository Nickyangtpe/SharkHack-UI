-- SharkLib ModuleScript
-- Located in ReplicatedStorage or another suitable location

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharkLib = {}
SharkLib.__index = SharkLib

-- Default Animation Settings (can be overridden per window)
local DEFAULT_ANIMATION_SPEED = 0.3
local DEFAULT_EASE_STYLE = Enum.EasingStyle.Quart
local DEFAULT_EASE_DIRECTION = Enum.EasingDirection.Out

-- Helper function for creating UI elements with properties
local function createInstance(className, properties)
	local instance = Instance.new(className)
	for prop, value in pairs(properties) do
		instance[prop] = value
	end
	return instance
end

-- Helper: Simple Event System
local function createEvent()
	local listeners = {}
	return {
		Connect = function(callback)
			table.insert(listeners, callback)
			return {
				Disconnect = function()
					local index = table.find(listeners, callback)
					if index then
						table.remove(listeners, index)
					end
				end
			}
		end,
		Fire = function(...)
			for _, callback in ipairs(listeners) do
				task.spawn(callback, ...) -- Use task.spawn for safety
			end
		end
	}
end


--[[****************************************************************************
*                                WINDOW CREATION                               *
****************************************************************************]]--

function SharkLib.new(options)
	options = options or {}
	local self = setmetatable({}, SharkLib)

	-- Configuration
	self.Title = options.Title or "SharkLib Window"
	self.Size = options.Size or UDim2.new(0, 500, 0, 350)
	self.Position = options.Position or UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)
	self.Draggable = options.Draggable ~= false -- Default true
	self.Closable = options.Closable ~= false   -- Default true
	self.Minimizable = options.Minimizable ~= false -- Default true
	self.ToggleKey = options.ToggleKey or Enum.KeyCode.Insert
	self.ResetOnSpawn = options.ResetOnSpawn == true -- Default false
	self.ZIndexBehavior = options.ZIndexBehavior or Enum.ZIndexBehavior.Sibling
	self.InitialCategory = options.InitialCategory -- Name of the category to show first
	self.AnimationSpeed = options.AnimationSpeed or DEFAULT_ANIMATION_SPEED
	self.EasingStyle = options.EasingStyle or DEFAULT_EASE_STYLE
	self.EasingDirection = options.EasingDirection or DEFAULT_EASE_DIRECTION

	-- Internal State
	self._screenGui = nil
	self._mainFrame = nil
	self._titleBar = nil
	self._titleText = nil
	self._closeButton = nil
	self._minimizeButton = nil
	self._sidebar = nil
	self._logoArea = nil
	self._contentArea = nil
	self._sidebarButtons = {} -- [name] = { frame, icon, label, highlight }
	self._sections = {}       -- [name] = { frame, scrollFrame, uiListLayout, elements = {} }
	self._colorPickers = {}   -- To manage popups
	self._currentCategory = nil
	self._isMinimized = false
	self._isVisible = false -- Start hidden, animate in
	self._connections = {}    -- To store event connections for cleanup

	-- Events
	self.Events = {
		ToggleChanged = createEvent(),     -- (elementName, sectionName, isEnabled)
		SliderChanged = createEvent(),     -- (elementName, sectionName, value)
		ColorChanged = createEvent(),      -- (elementName, sectionName, color)
		CategorySelected = createEvent(),  -- (categoryName)
		WindowOpened = createEvent(),
		WindowClosed = createEvent(),      -- (reason: "button" or "destroy")
		WindowMinimized = createEvent(),
		WindowRestored = createEvent()
	}

	-- Build the UI
	self:_buildWindow()
	self:_setupInteractions()

	-- Set initial category if specified
	if self.InitialCategory and self._sidebarButtons[self.InitialCategory] then
		self:SelectCategory(self.InitialCategory, true) -- Select without animation initially
	elseif #self._sidebarButtons > 0 then
		-- Select the first added category if no initial one is set
		local firstCategoryName = next(self._sidebarButtons)
		self:SelectCategory(firstCategoryName, true)
	end

    -- Apply initial theme color if provided
    if options.ThemeColor then
        self:ApplyThemeColor(options.ThemeColor, true) -- Apply immediately
    end
    if options.BackgroundColor then
        self:ApplyBackgroundColor(options.BackgroundColor, true)
    end

	-- Initial visibility (starts hidden, then animates in)
	self:Show()

	return self
end

--[[--------------------------------------------------------------------------]]
--|                             Internal Builders                            |
--[[--------------------------------------------------------------------------]]

function SharkLib:_buildWindow()
	-- ScreenGui
	self._screenGui = createInstance("ScreenGui", {
		Name = self.Title:gsub("%s+", "") .. "GUI", -- Remove spaces for Name
		ResetOnSpawn = self.ResetOnSpawn,
		ZIndexBehavior = self.ZIndexBehavior,
		Enabled = false, -- Start disabled, enable when shown
		Parent = PlayerGui,
	})

	-- Main Frame (starts small for entry animation)
	self._mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 0), -- Start height 0
		Position = UDim2.new(self.Position.X.Scale, self.Position.X.Offset, self.Position.Y.Scale, self.Position.Y.Offset + self.Size.Y.Offset / 2), -- Start centered vertically
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BorderSizePixel = 0,
		ClipsDescendants = true, -- Important for minimize/entry animations
		Parent = self._screenGui,
	})

	-- Title Bar
	self._titleBar = createInstance("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(15, 15, 20),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self._mainFrame,
	})

	-- Title Text
	self._titleText = createInstance("TextLabel", {
		Name = "TitleText",
		Size = UDim2.new(1, -100, 1, 0), -- Leave space for buttons
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = self.Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = self._titleBar,
	})

	-- Close Button
	self._closeButton = createInstance("TextButton", {
		Name = "CloseButton",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -30, 0, 0),
		BackgroundTransparency = 1,
		Text = "✕",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Visible = self.Closable,
		ZIndex = 3,
		Parent = self._titleBar,
	})

	-- Minimize Button
	self._minimizeButton = createInstance("TextButton", {
		Name = "MinimizeButton",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -60, 0, 0), -- Position relative to close button
		BackgroundTransparency = 1,
		Text = "−",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Visible = self.Minimizable,
		ZIndex = 3,
		Parent = self._titleBar,
	})

	-- Left Sidebar
	self._sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 165, 1, -30), -- Account for title bar
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = self._mainFrame,
	})

	-- Logo Area
	self._logoArea = createInstance("Frame", {
		Name = "LogoArea",
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundTransparency = 1,
		Parent = self._sidebar,
	})
    self:SetLogo("SharkHack") -- Default logo

	-- Content Area
	self._contentArea = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -165, 1, -30), -- Account for sidebar and title bar
		Position = UDim2.new(0, 165, 0, 30),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = self._mainFrame,
	})

	-- UIPadding for Content Area
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = self._contentArea,
	})
end

--[[--------------------------------------------------------------------------]]
--|                        Interaction Setup (Internal)                      |
--[[--------------------------------------------------------------------------]]

function SharkLib:_setupInteractions()
	local connections = self._connections -- Local reference for easier access

	-- Dragging
	if self.Draggable then
		local dragging = false
		local dragInput
		local dragStart
		local startPos

		local function updateDrag(input)
			if not dragging then return end
			local delta = input.Position - dragStart
			local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

            -- Clamp position to screen bounds (optional, but good practice)
            local vpSize = workspace.CurrentCamera.ViewportSize
            targetPosition = UDim2.new(
                targetPosition.X.Scale,
                math.clamp(targetPosition.X.Offset, 0, vpSize.X - self._mainFrame.AbsoluteSize.X),
                targetPosition.Y.Scale,
                math.clamp(targetPosition.Y.Offset, 0, vpSize.Y - self._mainFrame.AbsoluteSize.Y)
            )

			-- Use RenderStepped for smoother dragging instead of Tween
            -- TweenService:Create(self._mainFrame, TweenInfo.new(0.05), { Position = targetPosition }):Play()
            self._mainFrame.Position = targetPosition
		end

		connections.TitleDragBegan = self._titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = self._mainFrame.Position
				TweenService:Create(self._titleBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(10, 10, 15) }):Play()
			end
		end)

		connections.TitleDragEnded = self._titleBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if dragging then
                    dragging = false
				    TweenService:Create(self._titleBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(15, 15, 20) }):Play()
                end
			end
		end)

        -- Use UserInputService for InputChanged for more reliable dragging outside the TitleBar bounds
		connections.DragInputChanged = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateDrag(input)
			end
		end)

        connections.DragInputEndedGlobal = UserInputService.InputEnded:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
                 dragging = false
				 TweenService:Create(self._titleBar, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(15, 15, 20) }):Play()
            end
        end)

	end

	-- Close Button
	if self.Closable then
		connections.CloseEnter = self._closeButton.MouseEnter:Connect(function()
			TweenService:Create(self._closeButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 100, 100) }):Play()
		end)
		connections.CloseLeave = self._closeButton.MouseLeave:Connect(function()
			TweenService:Create(self._closeButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end)
		connections.CloseClick = self._closeButton.MouseButton1Click:Connect(function()
			self:Hide("button")
		end)
	end

	-- Minimize Button
	if self.Minimizable then
		connections.MinimizeEnter = self._minimizeButton.MouseEnter:Connect(function()
			TweenService:Create(self._minimizeButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(100, 200, 255) }):Play()
		end)
		connections.MinimizeLeave = self._minimizeButton.MouseLeave:Connect(function()
			TweenService:Create(self._minimizeButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end)
		connections.MinimizeClick = self._minimizeButton.MouseButton1Click:Connect(function()
			self:_toggleMinimize()
		end)
	end

	-- Toggle Keybind
	if self.ToggleKey then
		connections.ToggleKeyInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == self.ToggleKey then
				self:ToggleVisibility()
			end
		end)
	end
end

--[[****************************************************************************
*                               PUBLIC METHODS                                 *
****************************************************************************]]--

--[[--------------------------------------------------------------------------]]
--|                           Window Management                              |
--[[--------------------------------------------------------------------------]]

function SharkLib:Show()
	if self._isVisible then return end
	self._isVisible = true
	self._screenGui.Enabled = true

	-- Entrance Animation
	self._mainFrame.Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 0)
	self._mainFrame.Position = UDim2.new(self.Position.X.Scale, self.Position.X.Offset, self.Position.Y.Scale, self.Position.Y.Offset + self.Size.Y.Offset / 2)

	local tweenInfo = TweenInfo.new(
		self.AnimationSpeed * 1.5, -- Slightly longer for entrance
		Enum.EasingStyle.Back, -- Use Back easing for a nice pop
		Enum.EasingDirection.Out
	)
	local goal = {
		Size = self.Size,
		Position = self.Position
	}
	local tween = TweenService:Create(self._mainFrame, tweenInfo, goal)
	tween:Play()
    tween.Completed:Wait() -- Wait for animation to mostly finish

	self.Events.WindowOpened:Fire()
end

function SharkLib:Hide(reason)
	if not self._isVisible then return end
    reason = reason or "script"
	self._isVisible = false

	-- Hide all color picker popups immediately
	for _, cpData in pairs(self._colorPickers) do
		if cpData.popup then
			cpData.popup.Visible = false
		end
	end

	-- Exit Animation
	local tweenInfo = TweenInfo.new(
		self.AnimationSpeed,
		Enum.EasingStyle.Back, -- Use Back easing for exit too
		Enum.EasingDirection.In -- Reverse direction
	)
	local goal = {
		Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 0),
		Position = UDim2.new(self.Position.X.Scale, self.Position.X.Offset, self.Position.Y.Scale, self.Position.Y.Offset + self.Size.Y.Offset / 2)
	}
	local tween = TweenService:Create(self._mainFrame, tweenInfo, goal)
	tween:Play()
	tween.Completed:Wait() -- Wait for animation

	self._screenGui.Enabled = false
	self.Events.WindowClosed:Fire(reason)
end

function SharkLib:ToggleVisibility()
	if self._isVisible then
		self:Hide("toggle")
	else
		self:Show()
	end
end

function SharkLib:Destroy()
    self:Hide("destroy") -- Trigger close event with destroy reason

	-- Disconnect all events
	for _, connection in pairs(self._connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self._connections = {} -- Clear the table

    -- Destroy UI elements
	if self._screenGui then
		self._screenGui:Destroy()
	end

	-- Clear internal references
	for k, _ in pairs(self) do
        if k ~= "__index" then -- Avoid clearing metatable stuff
		    self[k] = nil
        end
	end
    setmetatable(self, nil) -- Break metatable link
end

function SharkLib:SetTitle(title)
	self.Title = title or "SharkLib Window"
	if self._titleText then
		self._titleText.Text = self.Title
	end
    if self._screenGui then
        self._screenGui.Name = self.Title:gsub("%s+", "") .. "GUI"
    end
end

function SharkLib:SetLogo(text, imageId, imageColor)
    -- Clear previous logo elements
    if self._logoArea then
        self._logoArea:ClearAllChildren()
    else
        warn("LogoArea not found in SharkLib:SetLogo")
        return
    end

    if imageId then
        local logoImage = createInstance("ImageLabel", {
            Name = "LogoImage",
            Size = UDim2.new(0, 60, 0, 60),
            Position = UDim2.new(0.5, -30, 0, 15),
            BackgroundTransparency = 1,
            Image = imageId,
            ImageColor3 = imageColor or Color3.new(1,1,1),
            Parent = self._logoArea
        })
    else -- Default text/shape logo if no image
        local sharkLogoFrame = createInstance("Frame", {
            Name = "SharkLogoFrame",
            Size = UDim2.new(0, 60, 0, 60),
            Position = UDim2.new(0.5, -30, 0, 15),
            BackgroundTransparency = 1,
            Parent = self._logoArea
        })
        local logoTriangle = createInstance("Frame", {
            Name = "LogoTriangle",
            Size = UDim2.new(0, 50, 0, 40),
            Position = UDim2.new(0.5, -25, 0.5, -20),
            BackgroundTransparency = 1,
            Parent = sharkLogoFrame
        })
        createInstance("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(0.5001, 1), NumberSequenceKeypoint.new(1, 1)
            }),
            Rotation = 45,
            Parent = logoTriangle
        })
        createInstance("UIStroke", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Parent = logoTriangle
        })
    end

    local logoText = createInstance("TextLabel", {
        Name = "LogoText",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        Text = text or "Library",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = self._logoArea
    })
end


function SharkLib:_toggleMinimize()
	if self._isMinimized then
		-- Restore
		self._isMinimized = false
		self._minimizeButton.Text = "−"

		local tweenInfo = TweenInfo.new(self.AnimationSpeed, self.EasingStyle, self.EasingDirection)
		local goal = { Size = self.Size }
		local tween = TweenService:Create(self._mainFrame, tweenInfo, goal)
		tween:Play()

		-- Wait a short moment before making children visible for smoother transition
		task.wait(self.AnimationSpeed * 0.1)
		self._sidebar.Visible = true
		self._contentArea.Visible = true

		self.Events.WindowRestored:Fire()

	else
		-- Minimize
		self._isMinimized = true
		self._minimizeButton.Text = "+"

		-- Hide children immediately before shrinking
		self._sidebar.Visible = false
		self._contentArea.Visible = false

        -- Hide all color picker popups
        for _, cpData in pairs(self._colorPickers) do
            if cpData.popup then
                cpData.popup.Visible = false
            end
        end

		local tweenInfo = TweenInfo.new(self.AnimationSpeed, self.EasingStyle, self.EasingDirection)
		local minimizedSize = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, self._titleBar.AbsoluteSize.Y)
		local goal = { Size = minimizedSize }
		local tween = TweenService:Create(self._mainFrame, tweenInfo, goal)
		tween:Play()
		self.Events.WindowMinimized:Fire()
	end
end

--[[--------------------------------------------------------------------------]]
--|                         Sidebar & Category Management                    |
--[[--------------------------------------------------------------------------]]

function SharkLib:AddSidebarButton(name, icon, iconOffset, iconSize)
    if not self._sidebar then
        warn("SharkLib: Sidebar not initialized.")
        return
    end
    if self._sidebarButtons[name] then
		warn("SharkLib: Sidebar button '" .. name .. "' already exists.")
		return
	end

    local numButtons = 0
    for _ in pairs(self._sidebarButtons) do numButtons = numButtons + 1 end

	local buttonFrame = createInstance("Frame", {
		Name = name .. "Button",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, self._logoArea.Size.Y.Offset + numButtons * 40),
		BackgroundTransparency = 1,
        LayoutOrder = numButtons,
		Parent = self._sidebar,
	})

	local iconButton = createInstance("ImageButton", {
		Name = "Icon",
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(0, 30, 0.5, -12),
		BackgroundTransparency = 1,
		Image = icon or "",
		ImageRectOffset = iconOffset or Vector2.new(0, 0),
		ImageRectSize = iconSize or Vector2.new(36, 36),
		ImageColor3 = Color3.fromRGB(150, 150, 150), -- Default inactive color
        ScaleType = Enum.ScaleType.Slice, -- Or Fit, depending on icon needs
        SliceCenter = Rect.new(iconSize.X/2-1,iconSize.Y/2-1,iconSize.X/2+1,iconSize.Y/2+1), -- Example for slicing
		Parent = buttonFrame,
	})

	local label = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 65, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Color3.fromRGB(150, 150, 150), -- Default inactive color
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = buttonFrame,
	})

	-- Add hover effect highlight
	local hoverHighlight = createInstance("Frame", {
		Name = "HoverHighlight",
		Size = UDim2.new(0.95, 0, 0.8, 0),
		Position = UDim2.new(0.025, 0, 0.1, 0),
		BackgroundColor3 = Color3.fromRGB(78, 93, 234), -- Theme color
		BackgroundTransparency = 1, -- Initially hidden
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = buttonFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hoverHighlight })

    -- Store button data
	self._sidebarButtons[name] = {
		frame = buttonFrame,
		icon = iconButton,
		label = label,
		highlight = hoverHighlight,
	}

    -- Add Connections
    local connections = self._connections
    local buttonId = "Sidebar_" .. name .. "_"

    connections[buttonId.."FrameBegan"] = buttonFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SelectCategory(name)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Hover animation only if not selected
            if self._currentCategory ~= name then
                 TweenService:Create(hoverHighlight, TweenInfo.new(0.2), { BackgroundTransparency = 0.8 }):Play()
            end
        end
    end)

    connections[buttonId.."FrameEnded"] = buttonFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Unhover animation only if not selected
            if self._currentCategory ~= name then
                TweenService:Create(hoverHighlight, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            end
        end
    end)

    connections[buttonId.."IconClick"] = iconButton.MouseButton1Click:Connect(function()
        self:SelectCategory(name)
    end)

    -- If this is the first button added and no initial category was set, select it
    if numButtons == 0 and not self.InitialCategory then
        self:SelectCategory(name, true) -- Select without animation
    end

    return self._sidebarButtons[name]
end


function SharkLib:AddSection(name)
	if self._sections[name] then
		warn("SharkLib: Section '" .. name .. "' already exists.")
		return self._sections[name] -- Return existing section
	end

	local sectionFrame = createInstance("Frame", {
		Name = name .. "Section",
		Size = UDim2.new(1, 0, 1, 0), -- Fill content area (padding handled by ContentArea)
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false, -- Initially hidden
		Parent = self._contentArea,
	})

	local sectionTitle = createInstance("TextLabel", {
		Name = name .. "Title",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sectionFrame,
	})

	-- Create the ScrollingFrame for content within this section
	local scrollFrame = createInstance("ScrollingFrame", {
		Name = name .. "ScrollingContent",
		Size = UDim2.new(1, 0, 1, -sectionTitle.AbsoluteSize.Y - 10), -- Adjust size based on title and add padding
		Position = UDim2.new(0, 0, 0, sectionTitle.AbsoluteSize.Y + 5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.fromRGB(78, 93, 234), -- Theme color
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
		CanvasSize = UDim2.new(0,0,0,0), -- Start small, will be updated by layout
        AutomaticCanvasSize = Enum.AutomaticSize.Y, -- Let UIListLayout handle height
		Parent = sectionFrame,
	})

	-- Add UIListLayout to the ScrollingFrame for automatic element positioning
	local uiListLayout = createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = scrollFrame,
	})

    -- Add padding within the scroll frame's canvas
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5), -- Padding for scrollbar
        PaddingBottom = UDim.new(0, 5),
		Parent = scrollFrame
	})


	self._sections[name] = {
		frame = sectionFrame,
        title = sectionTitle,
		scrollFrame = scrollFrame,
		uiListLayout = uiListLayout,
		elements = {}, -- Store elements added to this section { elementName = elementData }
	}

	return self._sections[name] -- Return the created section data
end

function SharkLib:SelectCategory(categoryName, instant)
	if not self._sidebarButtons[categoryName] or self._currentCategory == categoryName then
		return -- Category doesn't exist or is already selected
	end

    local prevCategory = self._currentCategory
	self._currentCategory = categoryName

	local themeColor = Color3.fromRGB(78, 93, 234) -- Default theme color
    -- Find current theme color (check an active button or a default element if needed)
    local activeSidebarButton = self._sidebarButtons[categoryName]
    if activeSidebarButton and activeSidebarButton.highlight.BackgroundColor3 ~= Color3.fromRGB(78, 93, 234) then
         -- Attempt to get theme from the highlight itself, assuming it's been set
         themeColor = activeSidebarButton.highlight.BackgroundColor3
    else
        -- Fallback or find theme color from another source if necessary (e.g., a stored variable)
        -- This part might need refinement based on how theme colors are managed globally
    end


	local inactiveColor = Color3.fromRGB(150, 150, 150)
	local activeTextColor = Color3.fromRGB(255, 255, 255)

	local tweenInfo = TweenInfo.new(instant and 0 or self.AnimationSpeed * 0.5, self.EasingStyle, self.EasingDirection)

	-- Update Sidebar Buttons
	for name, buttonData in pairs(self._sidebarButtons) do
		local isSelected = (name == categoryName)
		local targetIconColor = isSelected and themeColor or inactiveColor
		local targetLabelColor = isSelected and activeTextColor or inactiveColor
		local targetHighlightTransparency = isSelected and 0.8 or 1

		if instant then
			buttonData.icon.ImageColor3 = targetIconColor
			buttonData.label.TextColor3 = targetLabelColor
			buttonData.highlight.BackgroundTransparency = targetHighlightTransparency
		else
			TweenService:Create(buttonData.icon, tweenInfo, { ImageColor3 = targetIconColor }):Play()
			TweenService:Create(buttonData.label, tweenInfo, { TextColor3 = targetLabelColor }):Play()
            -- Don't tween highlight transparency if mouse is hovering over it
            if not buttonData.frame.MouseEnter:Wait(0) then -- Quick check, might not be perfect
                 TweenService:Create(buttonData.highlight, tweenInfo, { BackgroundTransparency = targetHighlightTransparency }):Play()
            else
                -- If hovered, just set instantly if needed
                buttonData.highlight.BackgroundTransparency = targetHighlightTransparency
            end
		end
	end

	-- Show/Hide Sections (with potential fade/slide, simple visibility toggle for now)
	for name, sectionData in pairs(self._sections) do
		sectionData.frame.Visible = (name == categoryName)
        -- TODO: Add optional transition animation here (e.g., fade in/out)
	end

	-- Hide all color picker popups when switching categories
	for _, cpData in pairs(self._colorPickers) do
		if cpData.popup then
			cpData.popup.Visible = false
		end
	end

	self.Events.CategorySelected:Fire(categoryName, prevCategory)
end

--[[--------------------------------------------------------------------------]]
--|                           UI Element Creation                            |
--[[--------------------------------------------------------------------------]]
-- These functions now take the section object returned by AddSection

function SharkLib:AddToggle(section, elementName, options)
    if not section or not section.scrollFrame then warn("SharkLib: Invalid section provided for AddToggle"); return end
    if section.elements[elementName] then warn("SharkLib: Toggle '"..elementName.."' already exists in section '"..section.title.Text.."'"); return end

	options = options or {}
	local isEnabled = options.Default or false
	local labelText = options.Text or elementName -- Use elementName if Text not provided
    local layoutOrder = options.LayoutOrder or #section.scrollFrame:GetChildren() -- Auto layout order


	local optionFrame = createInstance("Frame", {
		Name = elementName .. "Option",
		Size = UDim2.new(1, 0, 0, 30), -- Automatic width, fixed height
        AutomaticSize = Enum.AutomaticSize.X, -- Let content determine width if needed? No, use full width.
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
		Parent = section.scrollFrame,
	})

	local optionLabel = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -50, 1, 0), -- Leave space for toggle button
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = optionFrame,
	})

	-- Toggle button Frame
	local toggleButtonFrame = createInstance("Frame", {
		Name = "ToggleButton",
		Size = UDim2.new(0, 40, 0, 20),
		Position = UDim2.new(1, -45, 0.5, -10), -- Positioned to the right
		BackgroundColor3 = isEnabled and Color3.fromRGB(78, 93, 234) or Color3.fromRGB(40, 40, 45), -- Theme or inactive
		BorderSizePixel = 0,
		Parent = optionFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleButtonFrame })

	-- Toggle indicator circle
	local toggleIndicator = createInstance("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 16, 0, 16),
		Position = isEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), -- Right or Left
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleButtonFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleIndicator })

    -- Store element data
    local elementData = {
        type = "Toggle",
        frame = optionFrame,
        button = toggleButtonFrame,
        indicator = toggleIndicator,
        label = optionLabel,
        value = isEnabled,
        sectionName = section.title.Text,
        elementName = elementName,
    }
    section.elements[elementName] = elementData

	-- Interaction
    local connections = self._connections
    local elementId = "Element_" .. section.title.Text .. "_" .. elementName .. "_"

	connections[elementId.."Click"] = toggleButtonFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			elementData.value = not elementData.value -- Toggle internal state first

			local themeColor = self:GetThemeColor() -- Get current theme color
			local newColor = elementData.value and themeColor or Color3.fromRGB(40, 40, 45)
			local newPosition = elementData.value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)

			local tweenInfo = TweenInfo.new(0.2)
			TweenService:Create(toggleButtonFrame, tweenInfo, { BackgroundColor3 = newColor }):Play()
			TweenService:Create(toggleIndicator, tweenInfo, { Position = newPosition }):Play()

			-- Fire event
			self.Events.ToggleChanged:Fire(elementName, section.title.Text, elementData.value)

            -- Call specific callback if provided
            if options.Callback and typeof(options.Callback) == "function" then
                task.spawn(options.Callback, elementData.value)
            end
		end
	end)

	return elementData
end

function SharkLib:AddSlider(section, elementName, options)
    if not section or not section.scrollFrame then warn("SharkLib: Invalid section provided for AddSlider"); return end
    if section.elements[elementName] then warn("SharkLib: Slider '"..elementName.."' already exists in section '"..section.title.Text.."'"); return end

	options = options or {}
	local minValue = options.Min or 0
	local maxValue = options.Max or 100
	local defaultValue = math.clamp(options.Default or (minValue + maxValue) / 2, minValue, maxValue)
    local precision = options.Precision or 1 -- Decimal places (0 for integer)
    local factor = 10^precision
    local labelText = options.Text or elementName
    local layoutOrder = options.LayoutOrder or #section.scrollFrame:GetChildren()

    -- Round default value to precision
    defaultValue = math.floor(defaultValue * factor) / factor

	local sliderFrame = createInstance("Frame", {
		Name = elementName .. "Slider",
		Size = UDim2.new(1, 0, 0, 50), -- Automatic width, fixed height
        AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
		Parent = section.scrollFrame,
	})

	local sliderLabel = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -60, 0, 20), -- Leave space for value label
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sliderFrame,
	})

	-- Value display Label
	local valueLabel = createInstance("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0, 50, 0, 20),
		Position = UDim2.new(1, -50, 0, 0), -- Positioned top right
		BackgroundTransparency = 1,
		Text = string.format("%."..precision.."f", defaultValue), -- Format to precision
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = sliderFrame,
	})

	-- Slider track Frame
	local sliderTrack = createInstance("Frame", {
		Name = "Track",
		Size = UDim2.new(1, 0, 0, 6), -- Full width, fixed height
		Position = UDim2.new(0, 0, 0, 30), -- Position below labels
		BackgroundColor3 = Color3.fromRGB(40, 40, 45), -- Inactive color
		BorderSizePixel = 0,
		Parent = sliderFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderTrack })

	-- Slider fill Frame
    local initialRatio = (defaultValue - minValue) / (maxValue - minValue)
	local sliderFill = createInstance("Frame", {
		Name = "Fill",
		Size = UDim2.new(initialRatio, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(78, 93, 234), -- Theme color
		BorderSizePixel = 0,
		Parent = sliderTrack,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })

	-- Slider knob Frame
	local sliderKnob = createInstance("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(initialRatio, -8, 0.5, -8), -- Centered on ratio
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- White knob
		BorderSizePixel = 0,
        ZIndex = 2, -- Above fill/track
		Parent = sliderTrack,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderKnob })

    -- Store element data
    local elementData = {
        type = "Slider",
        frame = sliderFrame,
        track = sliderTrack,
        fill = sliderFill,
        knob = sliderKnob,
        label = sliderLabel,
        valueLabel = valueLabel,
        value = defaultValue,
        min = minValue,
        max = maxValue,
        precision = precision,
        sectionName = section.title.Text,
        elementName = elementName,
    }
    section.elements[elementName] = elementData

	-- Interaction
	local isDragging = false
    local connections = self._connections
    local elementId = "Element_" .. section.title.Text .. "_" .. elementName .. "_"

	local function updateSlider(inputPosition)
		local trackAbsPos = sliderTrack.AbsolutePosition
		local trackAbsSize = sliderTrack.AbsoluteSize

		-- Calculate the position ratio (0 to 1) based on mouse X relative to track
		local ratio = math.clamp((inputPosition.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)

		-- Calculate the actual value based on ratio, min, max, and precision
		local newValue = minValue + ratio * (maxValue - minValue)
        local factor = 10^precision
		newValue = math.floor(newValue * factor) / factor

        -- Only update if value actually changed (avoids excessive updates/event firing)
        if newValue == elementData.value then return end

        elementData.value = newValue -- Update internal state

		-- Update UI elements (use Tween for smooth visual update)
		local tweenInfo = TweenInfo.new(0.05) -- Quick tween for responsiveness
		TweenService:Create(sliderFill, tweenInfo, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		TweenService:Create(sliderKnob, tweenInfo, { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()
		valueLabel.Text = string.format("%."..precision.."f", newValue)

		-- Fire event
		self.Events.SliderChanged:Fire(elementName, section.title.Text, newValue)

        -- Call specific callback if provided
        if options.Callback and typeof(options.Callback) == "function" then
             task.spawn(options.Callback, newValue)
        end
	end

    -- Handle dragging start on track or knob
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			updateSlider(input.Position) -- Initial update on click position

			-- Animate knob grow
			TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 18, 0, 18),
				Position = sliderKnob.Position - UDim2.new(0, 1, 0, 1) -- Adjust for size change
			}):Play()
		end
    end

	connections[elementId.."TrackBegan"] = sliderTrack.InputBegan:Connect(startDrag)
    connections[elementId.."KnobBegan"] = sliderKnob.InputBegan:Connect(startDrag)

    -- Use UserInputService for global move and end detection
	connections[elementId.."InputChanged"] = UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(input.Position)
		end
	end)

	connections[elementId.."InputEnded"] = UserInputService.InputEnded:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
			-- Animate knob shrink
			TweenService:Create(sliderKnob, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 16, 0, 16),
				Position = sliderKnob.Position + UDim2.new(0, 1, 0, 1) -- Adjust back
			}):Play()
		end
	end)

	return elementData
end

function SharkLib:AddColorPicker(section, elementName, options)
    if not section or not section.scrollFrame then warn("SharkLib: Invalid section provided for AddColorPicker"); return end
    if section.elements[elementName] then warn("SharkLib: ColorPicker '"..elementName.."' already exists in section '"..section.title.Text.."'"); return end

	options = options or {}
	local defaultColor = options.Default or Color3.fromRGB(78, 93, 234) -- Default to theme color
    local labelText = options.Text or elementName
    local layoutOrder = options.LayoutOrder or #section.scrollFrame:GetChildren()

	local colorFrame = createInstance("Frame", {
		Name = elementName .. "Color",
		Size = UDim2.new(1, 0, 0, 30), -- Automatic width, fixed height
        AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,
		Parent = section.scrollFrame,
	})

	local colorLabel = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -50, 1, 0), -- Leave space for color preview
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = colorFrame,
	})

	-- Color preview Frame (acts as the button trigger)
	local colorPreviewButton = createInstance("TextButton", { -- Use TextButton for click detection
		Name = "PreviewButton",
		Size = UDim2.new(0, 30, 0, 18),
		Position = UDim2.new(1, -35, 0.5, -9), -- Positioned to the right
		BackgroundColor3 = defaultColor,
		BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(50,50,50), -- Subtle border
        Text = "",
		AutoButtonColor = false, -- Disable default button color changes
		Parent = colorFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorPreviewButton })

    -- Store element data BEFORE creating the popup
    local elementData = {
        type = "ColorPicker",
        frame = colorFrame,
        previewButton = colorPreviewButton,
        label = colorLabel,
        value = defaultColor,
        popup = nil, -- Will be created on demand or below
        sectionName = section.title.Text,
        elementName = elementName,
        -- Popup-specific elements will be added later
    }
    section.elements[elementName] = elementData
    self._colorPickers[elementName .. "_" .. section.title.Text] = elementData -- Store globally for popup management

	-- Create Color Picker Popup (initially hidden, parented to MainFrame for ZIndex control)
	local popupName = elementName .. "Popup"
	local colorPickerPopup = createInstance("Frame", {
		Name = popupName,
		Size = UDim2.new(0, 220, 0, 285), -- Fixed size for the popup
        Position = UDim2.new(0,0,0,0), -- Will be positioned on open
		BackgroundColor3 = Color3.fromRGB(30, 30, 35), -- Dark background for popup
		BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(50,50,55),
		Visible = false, -- Initially hidden
		ZIndex = 100, -- High ZIndex to appear over other elements
		Parent = self._mainFrame, -- Parent to main frame
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = colorPickerPopup })
    elementData.popup = colorPickerPopup -- Link popup to element data

	-- Container for popup content with padding
	local popupContainer = createInstance("Frame", {
		Name = "Container",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = colorPickerPopup,
	})
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15),
		Parent = popupContainer
	})

	-- Popup Title
	local pickerTitle = createInstance("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -30, 0, 30), -- Space for close button
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = popupContainer,
	})

	-- Popup Close Button
	local popupCloseButton = createInstance("TextButton", {
		Name = "CloseButton",
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -24, 0, 3),
		BackgroundTransparency = 1,
		Text = "✕",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 16,
		Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
		Parent = popupContainer,
	})

    -- Popup Close Button Interaction
    popupCloseButton.MouseEnter:Connect(function() popupCloseButton.TextColor3 = Color3.fromRGB(255, 100, 100) end)
    popupCloseButton.MouseLeave:Connect(function() popupCloseButton.TextColor3 = Color3.fromRGB(200, 200, 200) end)
    popupCloseButton.MouseButton1Click:Connect(function() colorPickerPopup.Visible = false end)

	-- Popup Color Preview
	local popupPreview = createInstance("Frame", {
		Name = "PopupPreview",
		Size = UDim2.new(0, 60, 0, 30),
		Position = UDim2.new(0.5, -30, 0, 40), -- Below title
		BackgroundColor3 = defaultColor,
		BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(60,60,65),
		Parent = popupContainer,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = popupPreview })
    elementData.popupPreview = popupPreview -- Store reference

	-- Internal function to create R, G, B sliders within the popup
	local function createColorSlider(sliderName, initialValue, yPos)
		local sliderContainer = createInstance("Frame", {
			Name = sliderName .. "Container", Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, yPos), BackgroundTransparency = 1, Parent = popupContainer
		})
		local label = createInstance("TextLabel", {
			Name = "Label", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1, Text = sliderName, TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14, Font = Enum.Font.GothamBold, Parent = sliderContainer
		})
		local valueLabel = createInstance("TextLabel", {
			Name = "Value", Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -40, 0, 0),
			BackgroundTransparency = 1, Text = tostring(math.floor(initialValue * 255)), TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, Parent = sliderContainer
		})
		local track = createInstance("Frame", {
			Name = "Track", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 25),
			BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0, Parent = sliderContainer
		})
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
		local fillColor = sliderName == "R" and Color3.fromRGB(255, 50, 50) or sliderName == "G" and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(50, 50, 255)
		local fill = createInstance("Frame", {
			Name = "Fill", Size = UDim2.new(initialValue, 0, 1, 0), BackgroundColor3 = fillColor,
			BorderSizePixel = 0, Parent = track
		})
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
		local knob = createInstance("Frame", {
			Name = "Knob", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(initialValue, -8, 0.5, -8),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = track.ZIndex + 1, Parent = track
		})
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

		-- Slider Interaction Logic (similar to main slider, simplified for popup)
		local isDraggingSlider = false
        local currentSliderValue = initialValue -- Store as 0-1 ratio

		local function updatePopupSlider(inputPos)
			local trackAbsPos = track.AbsolutePosition
			local trackAbsSize = track.AbsoluteSize
			local ratio = math.clamp((inputPos.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)

            if ratio == currentSliderValue then return end -- No change
            currentSliderValue = ratio

            local value255 = math.floor(ratio * 255)
            valueLabel.Text = tostring(value255)

			local tweenInfo = TweenInfo.new(0.05)
			TweenService:Create(fill, tweenInfo, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
			TweenService:Create(knob, tweenInfo, { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()

            -- Update the popup preview color immediately
			local r = tonumber(elementData.rSlider.valueLabel.Text) / 255
			local g = tonumber(elementData.gSlider.valueLabel.Text) / 255
			local b = tonumber(elementData.bSlider.valueLabel.Text) / 255
			popupPreview.BackgroundColor3 = Color3.new(r, g, b)
		end

        local function startPopupDrag(input)
             if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDraggingSlider = true
                updatePopupSlider(input.Position)
                -- Optional: Knob animation on drag start
            end
        end

        track.InputBegan:Connect(startPopupDrag)
        knob.InputBegan:Connect(startPopupDrag)

        -- Use global input listeners tied to this specific slider's dragging state
        local inputChangedConn, inputEndedConn
        inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updatePopupSlider(input.Position)
            end
        end)
        inputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDraggingSlider = false
                -- Optional: Knob animation on drag end
            end
        end)

        -- Store connections for potential cleanup if the popup is destroyed/recreated
        elementData[sliderName:lower()..'SliderConnections'] = {inputChangedConn, inputEndedConn}


		return { container = sliderContainer, valueLabel = valueLabel, track = track, fill = fill, knob = knob }
	end

	-- Create R, G, B sliders
	elementData.rSlider = createColorSlider("R", defaultColor.R, 80)
	elementData.gSlider = createColorSlider("G", defaultColor.G, 130)
	elementData.bSlider = createColorSlider("B", defaultColor.B, 180)

	-- Apply Button
	local applyButton = createInstance("TextButton", {
		Name = "ApplyButton",
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(0.5, -50, 1, -40), -- Centered at the bottom
		BackgroundColor3 = Color3.fromRGB(78, 93, 234), -- Theme color
		BorderSizePixel = 0,
		Text = "Apply",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
		Parent = popupContainer,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = applyButton })
    elementData.popupApplyButton = applyButton -- Store reference

    -- Apply button Interaction
    local themeColor = self:GetThemeColor()
    applyButton.MouseEnter:Connect(function() TweenService:Create(applyButton, TweenInfo.new(0.2), { BackgroundColor3 = themeColor:Lerp(Color3.new(1,1,1), 0.2) }):Play() end)
    applyButton.MouseLeave:Connect(function() TweenService:Create(applyButton, TweenInfo.new(0.2), { BackgroundColor3 = themeColor }):Play() end)
	applyButton.MouseButton1Click:Connect(function()
		-- Get color from popup sliders
		local r = tonumber(elementData.rSlider.valueLabel.Text) / 255
		local g = tonumber(elementData.gSlider.valueLabel.Text) / 255
		local b = tonumber(elementData.bSlider.valueLabel.Text) / 255
		local newColor = Color3.new(r, g, b)

        if newColor == elementData.value then -- No change
            colorPickerPopup.Visible = false
            return
        end

		elementData.value = newColor -- Update internal state

		-- Update the main preview button color
		colorPreviewButton.BackgroundColor3 = newColor

		-- Hide popup
		colorPickerPopup.Visible = false

		-- Fire event
		self.Events.ColorChanged:Fire(elementName, section.title.Text, newColor)

        -- Call specific callback if provided
        if options.Callback and typeof(options.Callback) == "function" then
             task.spawn(options.Callback, newColor)
        end
	end)

	-- Toggle Popup Visibility (connected to the main preview button)
    local connections = self._connections
    local elementId = "Element_" .. section.title.Text .. "_" .. elementName .. "_"

	connections[elementId.."TogglePopup"] = colorPreviewButton.MouseButton1Click:Connect(function()
        local shouldOpen = not colorPickerPopup.Visible

		-- Close all *other* popups first
		for key, cpData in pairs(self._colorPickers) do
            if cpData.popup and cpData.popup ~= colorPickerPopup then
			    cpData.popup.Visible = false
            end
		end

        if shouldOpen then
            -- Update popup preview and sliders to match current value before showing
            local currentColor = elementData.value
            popupPreview.BackgroundColor3 = currentColor
            local r, g, b = currentColor.R, currentColor.G, currentColor.B
            local r255, g255, b255 = math.floor(r*255), math.floor(g*255), math.floor(b*255)

            elementData.rSlider.valueLabel.Text = tostring(r255)
            elementData.gSlider.valueLabel.Text = tostring(g255)
            elementData.bSlider.valueLabel.Text = tostring(b255)

            local tweenInfo = TweenInfo.new(0.05)
            TweenService:Create(elementData.rSlider.fill, tweenInfo, {Size = UDim2.new(r,0,1,0)}):Play()
            TweenService:Create(elementData.rSlider.knob, tweenInfo, {Position = UDim2.new(r,-8,0.5,-8)}):Play()
            TweenService:Create(elementData.gSlider.fill, tweenInfo, {Size = UDim2.new(g,0,1,0)}):Play()
            TweenService:Create(elementData.gSlider.knob, tweenInfo, {Position = UDim2.new(g,-8,0.5,-8)}):Play()
            TweenService:Create(elementData.bSlider.fill, tweenInfo, {Size = UDim2.new(b,0,1,0)}):Play()
            TweenService:Create(elementData.bSlider.knob, tweenInfo, {Position = UDim2.new(b,-8,0.5,-8)}):Play()


            -- Position the popup relative to the button
            local previewAbsPos = colorPreviewButton.AbsolutePosition
            local previewAbsSize = colorPreviewButton.AbsoluteSize
            local mainFramePos = self._mainFrame.AbsolutePosition
            local mainFrameSize = self._mainFrame.AbsoluteSize
            local popupSize = colorPickerPopup.AbsoluteSize

            -- Calculate desired position (e.g., above or below the button)
            local targetX = previewAbsPos.X + previewAbsSize.X / 2 - popupSize.X / 2
            local targetY = previewAbsPos.Y - popupSize.Y - 5 -- Position above by default

            -- Check if positioning above goes off-screen, if so, position below
            if targetY < mainFramePos.Y then
                targetY = previewAbsPos.Y + previewAbsSize.Y + 5
            end

            -- Clamp position within the main frame bounds
            targetX = math.clamp(targetX, mainFramePos.X + 5, mainFramePos.X + mainFrameSize.X - popupSize.X - 5)
            targetY = math.clamp(targetY, mainFramePos.Y + 5, mainFramePos.Y + mainFrameSize.Y - popupSize.Y - 5)

            -- Convert absolute position back to offset relative to MainFrame
            colorPickerPopup.Position = UDim2.new(0, targetX - mainFramePos.X, 0, targetY - mainFramePos.Y)
		    colorPickerPopup.Visible = true
        else
            -- If clicking again while open, just close it
            colorPickerPopup.Visible = false
        end
	end)

	return elementData
end

--[[--------------------------------------------------------------------------]]
--|                             Getters / Setters                            |
--[[--------------------------------------------------------------------------]]

function SharkLib:GetElementValue(sectionName, elementName)
    local section = self._sections[sectionName]
    if not section then warn("SharkLib: Section '"..sectionName.."' not found in GetElementValue"); return nil end
    local element = section.elements[elementName]
    if not element then warn("SharkLib: Element '"..elementName.."' not found in section '"..sectionName.."' for GetElementValue"); return nil end

    return element.value
end

-- Add SetElementValue if needed, ensuring UI updates and events are handled correctly

function SharkLib:GetElement(sectionName, elementName)
    local section = self._sections[sectionName]
    if not section then warn("SharkLib: Section '"..sectionName.."' not found in GetElement"); return nil end
    return section.elements[elementName] -- Return the full element data table
end

function SharkLib:GetAllElements(sectionName)
    local section = self._sections[sectionName]
    if not section then warn("SharkLib: Section '"..sectionName.."' not found in GetAllElements"); return nil end
    return section.elements -- Return the table of all elements in the section
end

function SharkLib:GetThemeColor()
    -- Attempt to get theme color from a reliable source, e.g., the first sidebar button's icon if selected
    if self._currentCategory and self._sidebarButtons[self._currentCategory] then
        return self._sidebarButtons[self._currentCategory].icon.ImageColor3
    end
    -- Fallback: Check a known themed element like a slider fill or color picker apply button
    for _, sectionData in pairs(self._sections) do
        for _, elementData in pairs(sectionData.elements) do
            if elementData.type == "Slider" and elementData.fill then
                return elementData.fill.BackgroundColor3
            elseif elementData.type == "ColorPicker" and elementData.popupApplyButton then
                 return elementData.popupApplyButton.BackgroundColor3
            end
        end
    end
    -- Absolute fallback
    return Color3.fromRGB(78, 93, 234)
end

function SharkLib:ApplyThemeColor(color, instant)
    local tweenInfo = TweenInfo.new(instant and 0 or 0.2)

    -- Update sidebar buttons (icons and highlights)
    for name, buttonData in pairs(self._sidebarButtons) do
        if name == self._currentCategory then
            TweenService:Create(buttonData.icon, tweenInfo, { ImageColor3 = color }):Play()
        end
         -- Only change highlight color, not transparency
        TweenService:Create(buttonData.highlight, tweenInfo, { BackgroundColor3 = color }):Play()
    end

    -- Update other themed elements (scrollbars, slider fills, toggle backgrounds, apply buttons)
    for _, sectionData in pairs(self._sections) do
        if sectionData.scrollFrame then
             TweenService:Create(sectionData.scrollFrame, tweenInfo, { ScrollBarImageColor3 = color }):Play()
        end
        for _, elementData in pairs(sectionData.elements) do
            if elementData.type == "Toggle" and elementData.value then
                TweenService:Create(elementData.button, tweenInfo, { BackgroundColor3 = color }):Play()
            elseif elementData.type == "Slider" then
                 TweenService:Create(elementData.fill, tweenInfo, { BackgroundColor3 = color }):Play()
            elseif elementData.type == "ColorPicker" and elementData.popupApplyButton then
                 TweenService:Create(elementData.popupApplyButton, tweenInfo, { BackgroundColor3 = color }):Play()
            end
        end
    end
end

function SharkLib:ApplyBackgroundColor(color, instant)
     local tweenInfo = TweenInfo.new(instant and 0 or 0.2)
     if self._mainFrame then
         TweenService:Create(self._mainFrame, tweenInfo, { BackgroundColor3 = color }):Play()
     end
     -- Potentially update other related background elements (Sidebar, TitleBar?) if desired
     -- if self._sidebar then TweenService:Create(self._sidebar, tweenInfo, { BackgroundColor3 = color:Lerp(Color3.new(), 0.1) }):Play() end
     -- if self._titleBar then TweenService:Create(self._titleBar, tweenInfo, { BackgroundColor3 = color:Lerp(Color3.new(), 0.2) }):Play() end
end


return SharkLib
