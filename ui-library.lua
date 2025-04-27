-- SharkUI (ModuleScript)
-- Location: ReplicatedStorage or similar

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

local SharkUI = {}
SharkUI.__index = SharkUI

-- Default Animation settings (can be overridden)
local DEFAULT_ANIMATION_SPEED = 0.3
local DEFAULT_EASE_STYLE = Enum.EasingStyle.Quart
local DEFAULT_EASE_DIRECTION = Enum.EasingDirection.Out

-- Default Colors (can be overridden)
local DEFAULT_COLORS = {
	Background = Color3.fromRGB(20, 20, 25),
	TitleBar = Color3.fromRGB(15, 15, 20),
	Sidebar = Color3.fromRGB(25, 25, 30),
	Accent = Color3.fromRGB(78, 93, 234), -- Main theme color
	AccentHover = Color3.fromRGB(98, 113, 254),
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(150, 150, 150),
	ToggleOff = Color3.fromRGB(40, 40, 45),
	SliderTrack = Color3.fromRGB(40, 40, 45),
	PopupBackground = Color3.fromRGB(30, 30, 35),
	CloseHover = Color3.fromRGB(255, 100, 100),
	MinimizeHover = Color3.fromRGB(100, 200, 255),
	Stroke = Color3.fromRGB(255, 255, 255),
}

-- Helper function for creating instances with properties
local function createInstance(className, properties)
	local inst = Instance.new(className)
	for prop, value in pairs(properties or {}) do
		inst[prop] = value
	end
	return inst
end

-- ==================================================
-- Internal Component Creation Functions
-- ==================================================

local function createScrollingFrame(parent, name, position, size, colors)
	local scrollingFrame = createInstance("ScrollingFrame", {
		Name = name,
		Size = size,
		Position = position,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
		Parent = parent,
		ClipsDescendants = true, -- Important for contained elements
	})

	local listLayout = createInstance("UIListLayout", {
		Name = "ListLayout",
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = scrollingFrame,
	})

	createInstance("UIPadding", {
		Name = "Padding",
		PaddingTop = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		Parent = scrollingFrame,
	})

	-- Update canvas size automatically
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10) -- Add extra padding
	end)

	return scrollingFrame, listLayout
end

-- ==================================================
-- Library Public Interface
-- ==================================================

function SharkUI.new(options)
	options = options or {}
	local window = setmetatable({}, SharkUI)

	window.Name = options.Name or "SharkHackWindow"
	window.Title = options.Title or "SharkHack"
	window.Size = options.Size or UDim2.new(0, 500, 0, 350)
	window.Draggable = options.Draggable ~= false -- Default true
	window.Minimizable = options.Minimizable ~= false -- Default true
	window.Closable = options.Closable ~= false -- Default true
	window.StartVisible = options.StartVisible ~= false -- Default true
	window.ToggleKey = options.ToggleKey or Enum.KeyCode.Insert
	window.Colors = table.clone(DEFAULT_COLORS) -- Clone defaults
	if options.Colors then
		for k, v in pairs(options.Colors) do
			window.Colors[k] = v -- Override with user colors
		end
	end
	window.AnimationSpeed = options.AnimationSpeed or DEFAULT_ANIMATION_SPEED
	window.EaseStyle = options.EaseStyle or DEFAULT_EASE_STYLE
	window.EaseDirection = options.EaseDirection or DEFAULT_EASE_DIRECTION

	window._screenGui = nil
	window._mainFrame = nil
	window._titleBar = nil
	window._sidebar = nil
	window._contentArea = nil
	window._categories = {} -- Stores { button = ButtonFrame, section = SectionFrame, widgets = {} }
	window._menuButtons = {} -- Stores references to sidebar button parts { frame, icon, label, highlight }
	window._activeCategory = nil
	window._isMinimized = false
	window._dragging = false
	window._dragInput = nil
	window._dragStart = nil
	window._startPos = nil
	window._connections = {} -- To store event connections for later cleanup

	window:_createBaseUI()
	window:_setupInteractions()

	if window.StartVisible then
		window:Show()
	else
		window._screenGui.Enabled = false
		window._mainFrame.Visible = false -- Hide instantly if not starting visible
	end

	return window
end

-- ==================================================
-- Window Methods
-- ==================================================

function SharkUI:AddCategory(categoryName, iconData)
	if not self._sidebar or not self._contentArea then
		warn("SharkUI: Cannot add category before base UI is created.")
		return nil
	end
	if self._categories[categoryName] then
		warn("SharkUI: Category '" .. categoryName .. "' already exists.")
		return self._categories[categoryName]
	end

	local category = {}
	local index = #self._categories + 1
	local colors = self.Colors

	-- 1. Create Sidebar Button
	local buttonFrame = createInstance("Frame", {
		Name = categoryName .. "Button",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 110 + (#self._menuButtons) * 40),
		BackgroundTransparency = 1,
		Parent = self._sidebar,
	})

	local iconButton = createInstance("ImageButton", {
		Name = "Icon",
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(0, 30, 0.5, -12),
		BackgroundTransparency = 1,
		Image = iconData.Id or "rbxassetid://3926305904", -- Default icon if needed
		ImageRectOffset = iconData.Offset or Vector2.new(644, 364), -- Default icon offset
		ImageRectSize = iconData.Size or Vector2.new(36, 36),
		ImageColor3 = colors.TextMuted,
		Parent = buttonFrame,
	})

	local label = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 65, 0, 0),
		BackgroundTransparency = 1,
		Text = categoryName,
		TextColor3 = colors.TextMuted,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = buttonFrame,
	})

	local hoverHighlight = createInstance("Frame", {
		Name = "HoverHighlight",
		Size = UDim2.new(0.95, 0, 0.8, 0),
		Position = UDim2.new(0.025, 0, 0.1, 0),
		BackgroundColor3 = colors.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = buttonFrame,
	})
	createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hoverHighlight })

	self._menuButtons[categoryName] = {
		frame = buttonFrame,
		icon = iconButton,
		label = label,
		highlight = hoverHighlight,
	}

	-- 2. Create Content Section Frame
	local sectionFrame = createInstance("Frame", {
		Name = categoryName .. "Section",
		Size = UDim2.new(1, -20, 1, -20), -- Padding
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Visible = false, -- Initially hidden
		Parent = self._contentArea,
		ClipsDescendants = true,
	})

	local sectionTitle = createInstance("TextLabel", {
		Name = categoryName .. "Title",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = categoryName,
		TextColor3 = colors.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sectionFrame,
	})

	-- 3. Create Scrolling Frame inside Content Section
	local scrollFrame, listLayout = createScrollingFrame(sectionFrame, categoryName .. "Scroll", UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 1, -40), colors)

	-- 4. Store Category Data
	category.Name = categoryName
	category.SectionFrame = sectionFrame
	category.ScrollFrame = scrollFrame
	category.ListLayout = listLayout
	category.Widgets = {} -- Store widgets added to this category
	category._widgetCounter = 0 -- For LayoutOrder
	category._window = self -- Reference back to the window

	self._categories[categoryName] = category

	-- 5. Connect Sidebar Button Interaction
	local function handleClick()
		self:SelectCategory(categoryName)
	end

	local con1 = buttonFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			handleClick()
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(hoverHighlight, TweenInfo.new(0.2), { BackgroundTransparency = 0.8 }):Play()
		end
	end)
	local con2 = buttonFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(hoverHighlight, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		end
	end)
	local con3 = iconButton.MouseButton1Click:Connect(handleClick)
	table.insert(self._connections, con1)
	table.insert(self._connections, con2)
	table.insert(self._connections, con3)


	-- Select the first category added by default
	if not self._activeCategory then
		self:SelectCategory(categoryName, true) -- Select instantly
	end

	-- Return a category object for adding widgets
	return setmetatable(category, { __index = SharkUI.CategoryMethods })
end

function SharkUI:SelectCategory(categoryName, instant)
	local categoryData = self._categories[categoryName]
	if not categoryData or categoryName == self._activeCategory then
		return -- Do nothing if category doesn't exist or is already active
	end

	local colors = self.Colors
	local tweenInfo = instant and TweenInfo.new(0) or TweenInfo.new(self.AnimationSpeed / 2, self.EaseStyle, self.EaseDirection)

	-- Update Sidebar Buttons Visuals
	for name, buttonInfo in pairs(self._menuButtons) do
		local isSelected = (name == categoryName)
		local targetIconColor = isSelected and colors.Accent or colors.TextMuted
		local targetTextColor = isSelected and colors.Text or colors.TextMuted
		local targetHighlightTransparency = isSelected and 0.8 or 1

		TweenService:Create(buttonInfo.icon, tweenInfo, { ImageColor3 = targetIconColor }):Play()
		TweenService:Create(buttonInfo.label, tweenInfo, { TextColor3 = targetTextColor }):Play()
		TweenService:Create(buttonInfo.highlight, tweenInfo, { BackgroundTransparency = targetHighlightTransparency }):Play()
	end

	-- Hide previously active section (if any)
	if self._activeCategory and self._categories[self._activeCategory] then
		local oldSection = self._categories[self._activeCategory].SectionFrame
		if not instant then
			-- Optional: Add slide-out animation if desired
			-- TweenService:Create(oldSection, tweenInfo, { Position = UDim2.new(0, -20, 0, 10), Transparency = 1 }):Play()
			oldSection.Visible = false -- Simple hide for now
		else
			oldSection.Visible = false
		end
	end

	-- Show the new section
	local newSection = categoryData.SectionFrame
	if not instant then
		-- Optional: Add slide-in animation if desired
		-- newSection.Position = UDim2.new(0, 20, 0, 10)
		-- newSection.Transparency = 1
		newSection.Visible = true
		-- TweenService:Create(newSection, tweenInfo, { Position = UDim2.new(0, 10, 0, 10), Transparency = 0 }):Play()
	else
		newSection.Position = UDim2.new(0, 10, 0, 10)
		newSection.Transparency = 0
		newSection.Visible = true
	end


	self._activeCategory = categoryName
end

function SharkUI:Show(animate)
	if self._screenGui.Enabled and self._mainFrame.Visible and animate ~= false then return end -- Already visible

	animate = animate ~= false -- Default true
	local tweenInfo = TweenInfo.new(self.AnimationSpeed * 1.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Reset state before showing
	self._mainFrame.Size = animate and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 0) or self.Size
	self._mainFrame.Position = animate and UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, 0) or UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)
	self._mainFrame.Visible = true
	self._screenGui.Enabled = true

	if self._isMinimized then -- If minimized, just show title bar
		self._mainFrame.Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 30)
		self._mainFrame.Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2) -- Position correctly even when minimized
	else
		self._sidebar.Visible = true
		self._contentArea.Visible = true
		if animate then
			TweenService:Create(self._mainFrame, tweenInfo, {
				Size = self.Size,
				Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)
			}):Play()
		end
	end
end

function SharkUI:Hide(animate)
	if not self._screenGui.Enabled then return end -- Already hidden

	animate = animate ~= false -- Default true
	local tweenInfo = TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In)

	if animate then
		local targetPosition = self._isMinimized and self._mainFrame.Position or UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, 0)
		local targetSize = self._isMinimized and self._mainFrame.Size or UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 0)

		local tween = TweenService:Create(self._mainFrame, tweenInfo, {
			Size = targetSize,
			Position = targetPosition
		})
		tween.Completed:Connect(function()
			if self._screenGui then -- Check if not destroyed
				self._screenGui.Enabled = false
				self._mainFrame.Visible = false -- Ensure fully hidden
			end
		end)
		tween:Play()
	else
		self._screenGui.Enabled = false
		self._mainFrame.Visible = false
	end
end

function SharkUI:Toggle()
	if self._screenGui.Enabled then
		self:Hide()
	else
		self:Show()
	end
end

function SharkUI:Destroy()
	-- Disconnect all events
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self._connections = {} -- Clear the table

	if self._screenGui then
		self._screenGui:Destroy()
	end

	-- Clear references
	for k in pairs(self) do
		self[k] = nil
	end
	setmetatable(self, nil) -- Remove metatable
end

function SharkUI:SetColor(colorName, colorValue)
	if not DEFAULT_COLORS[colorName] then
		warn("SharkUI: Invalid color name '"..tostring(colorName).."'")
		return
	end
	self.Colors[colorName] = colorValue
	self:_updateColors() -- Apply the color change to the UI elements
end

-- ==================================================
-- Internal Helper Methods (_ prefix)
-- ==================================================

function SharkUI:_createBaseUI()
	local colors = self.Colors

	self._screenGui = createInstance("ScreenGui", {
		Name = self.Name .. "ScreenGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
		Enabled = false, -- Start disabled, enable with Show()
	})

	self._mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = self.Size,
		Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2),
		BackgroundColor3 = colors.Background,
		BorderSizePixel = 0,
		Parent = self._screenGui,
		Visible = false, -- Start invisible
		ClipsDescendants = true, -- Important for animations/minimize
	})

	self._titleBar = createInstance("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = colors.TitleBar,
		BorderSizePixel = 0,
		Parent = self._mainFrame,
	})

	local titleText = createInstance("TextLabel", {
		Name = "TitleText",
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = self.Title,
		TextColor3 = colors.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._titleBar,
	})

	if self.Closable then
		self._closeButton = createInstance("TextButton", {
			Name = "CloseButton",
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(1, -30, 0, 0),
			BackgroundTransparency = 1,
			Text = "✕",
			TextColor3 = colors.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Parent = self._titleBar,
		})
	end

	if self.Minimizable then
		self._minimizeButton = createInstance("TextButton", {
			Name = "MinimizeButton",
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(1, -60, 0, 0),
			BackgroundTransparency = 1,
			Text = "−",
			TextColor3 = colors.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Parent = self._titleBar,
		})
	end

	self._sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 165, 1, -30),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = colors.Sidebar,
		BorderSizePixel = 0,
		Parent = self._mainFrame,
	})

	-- Logo Area (Optional - customize as needed)
	local logoArea = createInstance("Frame", {
		Name = "LogoArea",
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundTransparency = 1,
		Parent = self._sidebar,
	})
	-- Add your specific logo elements here if desired, example:
	local logoText = createInstance("TextLabel", {
		Name = "LogoText", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, Text = self.Title, TextColor3 = colors.Text,
		TextSize = 18, Font = Enum.Font.GothamBold, Parent = logoArea
	})


	self._contentArea = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -165, 1, -30),
		Position = UDim2.new(0, 165, 0, 30),
		BackgroundTransparency = 1,
		Parent = self._mainFrame,
		ClipsDescendants = true,
	})
end

function SharkUI:_setupInteractions()
	local colors = self.Colors
	local tweenInfoHover = TweenInfo.new(0.2)

	-- Dragging
	if self.Draggable then
		local function updateDrag(input)
			local delta = input.Position - self._dragStart
			local targetPosition = UDim2.new(self._startPos.X.Scale, self._startPos.X.Offset + delta.X, self._startPos.Y.Scale, self._startPos.Y.Offset + delta.Y)
			-- Use Tween for smoother dragging, short duration
			TweenService:Create(self._mainFrame, TweenInfo.new(0.05), { Position = targetPosition }):Play()
		end

		local con1 = self._titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._dragging = true
				self._dragStart = input.Position
				self._startPos = self._mainFrame.Position
				TweenService:Create(self._titleBar, tweenInfoHover, { BackgroundColor3 = colors.TitleBar:Lerp(Color3.new(0,0,0), 0.2) }):Play() -- Darken slightly

				local connectionChanged
				connectionChanged = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						self._dragging = false
						TweenService:Create(self._titleBar, tweenInfoHover, { BackgroundColor3 = colors.TitleBar }):Play()
						connectionChanged:Disconnect() -- Disconnect self
						-- Remove from main connections table if tracked specifically
					end
				end)
                table.insert(self._connections, connectionChanged) -- Track for cleanup
			end
		end)
		table.insert(self._connections, con1)

		local con2 = self._titleBar.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				self._dragInput = input
			end
		end)
		table.insert(self._connections, con2)

		-- Use UserInputService for smoother global tracking while dragging
		local con3 = UserInputService.InputChanged:Connect(function(input)
			if input == self._dragInput and self._dragging then
				updateDrag(input)
			end
		end)
        table.insert(self._connections, con3)

        -- Need to handle mouse button up globally too in case mouse is released outside titlebar
		local con4 = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and self._dragging then
                self._dragging = false
				TweenService:Create(self._titleBar, tweenInfoHover, { BackgroundColor3 = colors.TitleBar }):Play()
            end
		end)
        table.insert(self._connections, con4)
	end

	-- Close Button
	if self.Closable and self._closeButton then
		local btn = self._closeButton
		local con1 = btn.MouseEnter:Connect(function() TweenService:Create(btn, tweenInfoHover, { TextColor3 = colors.CloseHover }):Play() end)
		local con2 = btn.MouseLeave:Connect(function() TweenService:Create(btn, tweenInfoHover, { TextColor3 = colors.Text }):Play() end)
		local con3 = btn.MouseButton1Click:Connect(function() self:Destroy() end) -- Destroy by default, or call a callback if needed
		table.insert(self._connections, con1)
		table.insert(self._connections, con2)
		table.insert(self._connections, con3)
	end

	-- Minimize Button
	if self.Minimizable and self._minimizeButton then
		local btn = self._minimizeButton
		local con1 = btn.MouseEnter:Connect(function() TweenService:Create(btn, tweenInfoHover, { TextColor3 = colors.MinimizeHover }):Play() end)
		local con2 = btn.MouseLeave:Connect(function() TweenService:Create(btn, tweenInfoHover, { TextColor3 = colors.Text }):Play() end)
		local con3 = btn.MouseButton1Click:Connect(function() self:_toggleMinimize() end)
		table.insert(self._connections, con1)
		table.insert(self._connections, con2)
		table.insert(self._connections, con3)
	end

	-- Keybind Toggle
	if self.ToggleKey then
		local con = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == self.ToggleKey then
				self:Toggle()
			end
		end)
		table.insert(self._connections, con)
	end
end

function SharkUI:_toggleMinimize()
	local colors = self.Colors
	local tweenInfo = TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, self._isMinimized and Enum.EasingDirection.Out or Enum.EasingDirection.In)
	local targetSize
	local targetSidebarVisible
	local targetContentVisible
	local targetButtonText

	if self._isMinimized then
		targetSize = self.Size
		targetSidebarVisible = true
		targetContentVisible = true
		targetButtonText = "−"
	else
		targetSize = UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 30) -- Title bar height
		targetSidebarVisible = false
		targetContentVisible = false
		targetButtonText = "+"
	end

	self._isMinimized = not self._isMinimized

	-- Hide content instantly before animating size
	if not targetSidebarVisible then
		self._sidebar.Visible = false
		self._contentArea.Visible = false
	end

	local tween = TweenService:Create(self._mainFrame, tweenInfo, { Size = targetSize })
	tween.Completed:Connect(function()
		-- Show content after animation completes if restoring
		if targetSidebarVisible then
			self._sidebar.Visible = true
			self._contentArea.Visible = true
		end
		if self._minimizeButton then self._minimizeButton.Text = targetButtonText end
	end)
	tween:Play()
end

function SharkUI:_updateColors()
	-- This function needs to iterate through relevant UI elements and apply the new colors
	-- from self.Colors. This can be complex if you want to update everything live.
	-- Example snippets:
	local colors = self.Colors
	if self._mainFrame then self._mainFrame.BackgroundColor3 = colors.Background end
	if self._titleBar then self._titleBar.BackgroundColor3 = colors.TitleBar end
	if self._sidebar then self._sidebar.BackgroundColor3 = colors.Sidebar end
	if self._titleBar and self._titleBar:FindFirstChild("TitleText") then self._titleBar.TitleText.TextColor3 = colors.Text end
	if self._closeButton then self._closeButton.TextColor3 = colors.Text end -- Reset hover state logic needed
	if self._minimizeButton then self._minimizeButton.TextColor3 = colors.Text end -- Reset hover state logic needed

	-- Update category buttons
	for name, buttonInfo in pairs(self._menuButtons) do
		local isSelected = (name == self._activeCategory)
		buttonInfo.icon.ImageColor3 = isSelected and colors.Accent or colors.TextMuted
		buttonInfo.label.TextColor3 = isSelected and colors.Text or colors.TextMuted
		buttonInfo.highlight.BackgroundColor3 = colors.Accent
	end

	-- Update widgets (requires iterating through all widgets in all categories)
	for _, category in pairs(self._categories) do
		for _, widget in pairs(category.Widgets) do
			if widget.Type == "Toggle" and widget.Elements.toggleButton then
				widget.Elements.toggleButton.BackgroundColor3 = widget.Value and colors.Accent or colors.ToggleOff
				widget.Elements.optionLabel.TextColor3 = colors.Text
			elseif widget.Type == "Slider" and widget.Elements.fill then
				widget.Elements.fill.BackgroundColor3 = colors.Accent
				widget.Elements.track.BackgroundColor3 = colors.SliderTrack
				widget.Elements.label.TextColor3 = colors.Text
				widget.Elements.valueLabel.TextColor3 = colors.Text
			elseif widget.Type == "ColorPicker" and widget.Elements.preview then
				widget.Elements.preview.BackgroundColor3 = widget.Value -- Value is the Color3
				widget.Elements.label.TextColor3 = colors.Text
				-- Update popup colors too if needed
			end
		end
		-- Update scrollbar color
		if category.ScrollFrame then category.ScrollFrame.ScrollBarImageColor3 = colors.Accent end
	end

	-- Update theme-dependent colors (like the accent color in color pickers)
	-- You might need more specific logic here depending on how deep the color changes go.
	print("SharkUI: Colors updated (basic implementation).")
end

-- ==================================================
-- Category Methods (Accessed via Category object)
-- ==================================================
SharkUI.CategoryMethods = {}

function SharkUI.CategoryMethods:AddToggle(optionName, defaultValue, callback)
	local category = self
	local window = category._window
	local colors = window.Colors
	category._widgetCounter = category._widgetCounter + 1

	local isEnabled = defaultValue == true
	local elements = {} -- Store references to UI elements for this widget

	local optionFrame = createInstance("Frame", {
		Name = optionName .. "Option",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = category._widgetCounter,
		Parent = category.ScrollFrame,
	})
	elements.frame = optionFrame

	local optionLabel = createInstance("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -50, 1, 0),
		BackgroundTransparency = 1,
		Text = optionName,
		TextColor3 = colors.Text,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = optionFrame,
	})
	elements.optionLabel = optionLabel

	local toggleButton = createInstance("Frame", {
		Name = "ToggleButton",
		Size = UDim2.new(0, 40, 0, 20),
		Position = UDim2.new(1, -45, 0.5, -10),
		BackgroundColor3 = isEnabled and colors.Accent or colors.ToggleOff,
		BorderSizePixel = 0,
		Parent = optionFrame,
	})
	elements.toggleButton = toggleButton
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleButton })

	local toggleIndicator = createInstance("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 16, 0, 16),
		Position = isEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
		BackgroundColor3 = colors.Text, -- White indicator
		BorderSizePixel = 0,
		Parent = toggleButton,
	})
	elements.indicator = toggleIndicator
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleIndicator })

	local widgetData = {
		Name = optionName,
		Type = "Toggle",
		Value = isEnabled,
		Callback = callback,
		Elements = elements
	}
	table.insert(category.Widgets, widgetData)

	-- Interaction
	local con = toggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			widgetData.Value = not widgetData.Value -- Toggle the internal state

			-- Animate
			local newColor = widgetData.Value and colors.Accent or colors.ToggleOff
			local newPosition = widgetData.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			local tweenInfo = TweenInfo.new(0.2)

			TweenService:Create(toggleButton, tweenInfo, { BackgroundColor3 = newColor }):Play()
			TweenService:Create(toggleIndicator, tweenInfo, { Position = newPosition }):Play()

			-- Execute callback
			if widgetData.Callback then
				task.spawn(widgetData.Callback, widgetData.Value) -- Use task.spawn for safety
			end
		end
	end)
	table.insert(window._connections, con) -- Track connection

	return widgetData -- Return widget data for potential external control
end


function SharkUI.CategoryMethods:AddSlider(sliderName, minValue, maxValue, defaultValue, callback)
	local category = self
	local window = category._window
	local colors = window.Colors
	category._widgetCounter = category._widgetCounter + 1

	defaultValue = math.clamp(defaultValue, minValue, maxValue)
	local currentRatio = (defaultValue - minValue) / (maxValue - minValue)
	local elements = {}
	local isDragging = false

	local sliderFrame = createInstance("Frame", {
		Name = sliderName .. "Slider",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		LayoutOrder = category._widgetCounter,
		Parent = category.ScrollFrame,
	})
	elements.frame = sliderFrame

	local sliderLabel = createInstance("TextLabel", {
		Name = "Label", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
		Text = sliderName, TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = sliderFrame,
	})
	elements.label = sliderLabel

	local valueLabel = createInstance("TextLabel", {
		Name = "Value", Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -50, 0, 0),
		BackgroundTransparency = 1, Text = string.format("%.1f", defaultValue), TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = sliderFrame,
	})
	elements.valueLabel = valueLabel

	local sliderTrack = createInstance("Frame", {
		Name = "Track", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 25),
		BackgroundColor3 = colors.SliderTrack, BorderSizePixel = 0, Parent = sliderFrame,
	})
	elements.track = sliderTrack
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderTrack })

	local sliderFill = createInstance("Frame", {
		Name = "Fill", Size = UDim2.new(currentRatio, 0, 1, 0), BackgroundColor3 = colors.Accent,
		BorderSizePixel = 0, Parent = sliderTrack,
	})
	elements.fill = sliderFill
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })

	local sliderKnob = createInstance("Frame", {
		Name = "Knob", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(currentRatio, -8, 0.5, -8),
		BackgroundColor3 = colors.Text, BorderSizePixel = 0, ZIndex = 2, Parent = sliderTrack,
	})
	elements.knob = sliderKnob
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderKnob })

	local widgetData = {
		Name = sliderName,
		Type = "Slider",
		Value = defaultValue,
		Min = minValue,
		Max = maxValue,
		Callback = callback,
		Elements = elements
	}
	table.insert(category.Widgets, widgetData)

	-- Interaction Logic
	local function updateSlider(inputPosition)
		local trackAbsPos = sliderTrack.AbsolutePosition
		local trackAbsSize = sliderTrack.AbsoluteSize
		local mouseX = inputPosition.X

		local ratio = math.clamp((mouseX - trackAbsPos.X) / trackAbsSize.X, 0, 1)
		local newValue = minValue + ratio * (maxValue - minValue)
		newValue = math.floor(newValue * 10 + 0.5) / 10 -- Round to one decimal place

		if newValue ~= widgetData.Value then -- Only update if value changed
			widgetData.Value = newValue

			-- Update UI (use tweens for smoothness)
			local tweenInfo = TweenInfo.new(0.05) -- Short tween for responsiveness
			TweenService:Create(sliderFill, tweenInfo, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
			TweenService:Create(sliderKnob, tweenInfo, { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()
			valueLabel.Text = string.format("%.1f", newValue)

			-- Execute callback
			if widgetData.Callback then
				task.spawn(widgetData.Callback, widgetData.Value)
			end
		end
	end

	local con1 = sliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			updateSlider(input.Position)
			TweenService:Create(sliderKnob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0,1,0,1) }):Play() -- Enlarge knob
		end
	end)
	local con2 = sliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			TweenService:Create(sliderKnob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18), Position = sliderKnob.Position - UDim2.new(0,1,0,1) }):Play() -- Enlarge knob
		end
	end)

	-- Global listeners for dragging and release
	local dragMoveConn, dragEndConn
	dragMoveConn = UserInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position)
		end
	end)
	dragEndConn = UserInputService.InputEnded:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
			TweenService:Create(sliderKnob, TweenInfo.new(0.1), { Size = UDim2.new(0, 16, 0, 16), Position = sliderKnob.Position + UDim2.new(0,1,0,1) }):Play() -- Shrink knob
		end
	end)

	-- Track all connections
	table.insert(window._connections, con1)
	table.insert(window._connections, con2)
	table.insert(window._connections, dragMoveConn)
	table.insert(window._connections, dragEndConn)

	return widgetData
end

function SharkUI.CategoryMethods:AddColorPicker(colorName, defaultColor, callback)
	local category = self
	local window = category._window
	local colors = window.Colors
	category._widgetCounter = category._widgetCounter + 1

	local elements = {}

	-- Main Option Frame
	local colorFrame = createInstance("Frame", {
		Name = colorName .. "Color", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
		LayoutOrder = category._widgetCounter, Parent = category.ScrollFrame,
	})
	elements.frame = colorFrame

	local colorLabel = createInstance("TextLabel", {
		Name = "Label", Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = colorName,
		TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = colorFrame,
	})
	elements.label = colorLabel

	local colorPreview = createInstance("Frame", {
		Name = "Preview", Size = UDim2.new(0, 30, 0, 18), Position = UDim2.new(1, -35, 0.5, -9),
		BackgroundColor3 = defaultColor, BorderSizePixel = 1, BorderColor3 = colors.TextMuted, Parent = colorFrame, -- Added border
	})
	elements.preview = colorPreview
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorPreview })

	local pickerButton = createInstance("TextButton", { -- Button overlay for clicking
		Name = "PickerButton", Size = UDim2.new(0, 30, 0, 18), Position = UDim2.new(1, -35, 0.5, -9),
		BackgroundTransparency = 1, Text = "", Parent = colorFrame, ZIndex = 2,
	})
	elements.button = pickerButton

	-- Color Picker Popup (created once per picker, initially hidden)
	local popupFrame = createInstance("Frame", {
		Name = colorName .. "Popup", Size = UDim2.new(0, 220, 0, 285), BackgroundColor3 = colors.PopupBackground,
		BorderSizePixel = 1, BorderColor3 = colors.TitleBar, -- Added border
		Visible = false, ZIndex = 100, Parent = window._mainFrame, -- Parent to main frame for positioning
		ClipsDescendants = true,
	})
	elements.popup = popupFrame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = popupFrame })

	local popupContainer = createInstance("Frame", { Name = "Container", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = popupFrame })
	createInstance("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), Parent = popupContainer })

	-- Popup Contents
	local pickerTitle = createInstance("TextLabel", { Name = "Title", Size = UDim2.new(1, -30, 0, 30), BackgroundTransparency = 1, Text = colorName, TextColor3 = colors.Text, TextSize = 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = popupContainer })
	local popupCloseButton = createInstance("TextButton", { Name = "CloseButton", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -24, 0, 3), BackgroundTransparency = 1, Text = "✕", TextColor3 = colors.Text, TextSize = 16, Font = Enum.Font.GothamBold, ZIndex = 101, Parent = popupContainer })
	local popupPreview = createInstance("Frame", { Name = "PopupPreview", Size = UDim2.new(0, 60, 0, 30), Position = UDim2.new(0.5, -30, 0, 40), BackgroundColor3 = defaultColor, BorderSizePixel = 1, BorderColor3 = colors.TextMuted, Parent = popupContainer })
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = popupPreview })

	local rgbSliders = {} -- To store R, G, B slider widgetData

	-- Internal function to create sliders within the popup
	local function createPopupSlider(sliderLetter, initialValue, yPos)
		local sliderElements = {}
		local sliderIsDragging = false

		local sliderContainer = createInstance("Frame", { Name = sliderLetter .. "Container", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, yPos), BackgroundTransparency = 1, Parent = popupContainer })
		local sliderLabel = createInstance("TextLabel", { Name = "Label", Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, Text = sliderLetter, TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.GothamBold, Parent = sliderContainer })
		local valueLabel = createInstance("TextLabel", { Name = "Value", Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(initialValue), TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Right, Parent = sliderContainer })
		local sliderTrack = createInstance("Frame", { Name = "Track", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 25), BackgroundColor3 = colors.SliderTrack, BorderSizePixel = 0, Parent = sliderContainer })
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderTrack })
		local sliderFill = createInstance("Frame", { Name = "Fill", Size = UDim2.new(initialValue/255, 0, 1, 0), BackgroundColor3 = (sliderLetter == "R" and Color3.new(1,0,0)) or (sliderLetter == "G" and Color3.new(0,1,0)) or Color3.new(0,0,1), BorderSizePixel = 0, Parent = sliderTrack })
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderFill })
		local sliderKnob = createInstance("Frame", { Name = "Knob", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(initialValue/255, -8, 0.5, -8), BackgroundColor3 = colors.Text, BorderSizePixel = 0, ZIndex = 101, Parent = sliderTrack })
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderKnob })

		sliderElements = {track = sliderTrack, fill = sliderFill, knob = sliderKnob, valueLabel = valueLabel}

		local sliderWidgetData = { Value = initialValue, Elements = sliderElements }

		-- Interaction Logic for Popup Slider
		local function updatePopupSlider(inputPosition)
			local trackAbsPos = sliderTrack.AbsolutePosition
			local trackAbsSize = sliderTrack.AbsoluteSize
			local mouseX = inputPosition.X

			local ratio = math.clamp((mouseX - trackAbsPos.X) / trackAbsSize.X, 0, 1)
			local newValue = math.floor(ratio * 255 + 0.5)

			if newValue ~= sliderWidgetData.Value then
				sliderWidgetData.Value = newValue
				local tweenInfo = TweenInfo.new(0.05)
				TweenService:Create(sliderFill, tweenInfo, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
				TweenService:Create(sliderKnob, tweenInfo, { Position = UDim2.new(ratio, -8, 0.5, -8) }):Play()
				valueLabel.Text = tostring(newValue)

				-- Update popup preview color based on all sliders
				local r = rgbSliders.R.Value
				local g = rgbSliders.G.Value
				local b = rgbSliders.B.Value
				popupPreview.BackgroundColor3 = Color3.fromRGB(r, g, b)
			end
		end

		local scon1 = sliderTrack.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderIsDragging = true; updatePopupSlider(input.Position) end end)
		local scon2 = sliderKnob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderIsDragging = true end end)
		-- Global listeners (use separate ones for popup sliders to avoid conflicts)
		local sdragMoveConn, sdragEndConn
		sdragMoveConn = UserInputService.InputChanged:Connect(function(input) if sliderIsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updatePopupSlider(input.Position) end end)
		sdragEndConn = UserInputService.InputEnded:Connect(function(input) if sliderIsDragging and input.UserInputType == Enum.UserInputType.MouseButton1 then sliderIsDragging = false end end)

		table.insert(window._connections, scon1)
		table.insert(window._connections, scon2)
		table.insert(window._connections, sdragMoveConn)
		table.insert(window._connections, sdragEndConn)

		return sliderWidgetData
	end

	-- Create R, G, B sliders
	rgbSliders.R = createPopupSlider("R", math.floor(defaultColor.R * 255 + 0.5), 80)
	rgbSliders.G = createPopupSlider("G", math.floor(defaultColor.G * 255 + 0.5), 130)
	rgbSliders.B = createPopupSlider("B", math.floor(defaultColor.B * 255 + 0.5), 180)

	-- Apply Button
	local applyButton = createInstance("TextButton", { Name = "ApplyButton", Size = UDim2.new(0, 100, 0, 30), Position = UDim2.new(0.5, -50, 1, -40), BackgroundColor3 = colors.Accent, BorderSizePixel = 0, Text = "Apply", TextColor3 = colors.Text, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 101, Parent = popupContainer })
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = applyButton })
	local applyCon1 = applyButton.MouseEnter:Connect(function() TweenService:Create(applyButton, TweenInfo.new(0.2), { BackgroundColor3 = colors.AccentHover }):Play() end)
	local applyCon2 = applyButton.MouseLeave:Connect(function() TweenService:Create(applyButton, TweenInfo.new(0.2), { BackgroundColor3 = colors.Accent }):Play() end)
	table.insert(window._connections, applyCon1)
	table.insert(window._connections, applyCon2)

	-- Store widget data
	local widgetData = {
		Name = colorName,
		Type = "ColorPicker",
		Value = defaultColor,
		Callback = callback,
		Elements = elements,
		_rgbSliders = rgbSliders -- Internal reference
	}
	table.insert(category.Widgets, widgetData)

	-- Show/Hide Popup Logic
	local function togglePopup()
		local isVisible = popupFrame.Visible
		-- Hide all other popups first
		for _, otherCategory in pairs(window._categories) do
			for _, otherWidget in pairs(otherCategory.Widgets) do
				if otherWidget.Type == "ColorPicker" and otherWidget.Elements.popup ~= popupFrame then
					otherWidget.Elements.popup.Visible = false
				end
			end
		end

		if isVisible then
			popupFrame.Visible = false
		else
			-- Position popup near the button, clamping to screen edges
			local mainFrameAbsPos = window._mainFrame.AbsolutePosition
			local mainFrameAbsSize = window._mainFrame.AbsoluteSize
			local previewAbsPos = colorPreview.AbsolutePosition
			local popupSize = popupFrame.AbsoluteSize

			local idealX = previewAbsPos.X - popupSize.X / 2 -- Center on preview
			local idealY = previewAbsPos.Y - popupSize.Y - 10 -- Position above preview

			-- Clamp X position within main frame bounds
			local finalX = math.clamp(idealX, mainFrameAbsPos.X + 5, mainFrameAbsPos.X + mainFrameAbsSize.X - popupSize.X - 5)
			-- Clamp Y position
			local finalY = math.clamp(idealY, mainFrameAbsPos.Y + 5, mainFrameAbsPos.Y + mainFrameAbsSize.Y - popupSize.Y - 5)

			-- Convert back to Offset relative to MainFrame
			popupFrame.Position = UDim2.new(0, finalX - mainFrameAbsPos.X, 0, finalY - mainFrameAbsPos.Y)
			popupFrame.Visible = true
		end
	end

	local con1 = pickerButton.MouseButton1Click:Connect(togglePopup)
	local con2 = popupCloseButton.MouseButton1Click:Connect(function() popupFrame.Visible = false end)
	table.insert(window._connections, con1)
	table.insert(window._connections, con2)

	-- Apply Button Logic
	local con3 = applyButton.MouseButton1Click:Connect(function()
		local r = rgbSliders.R.Value
		local g = rgbSliders.G.Value
		local b = rgbSliders.B.Value
		local newColor = Color3.fromRGB(r, g, b)

		widgetData.Value = newColor         -- Update internal value
		colorPreview.BackgroundColor3 = newColor -- Update the small preview
		popupFrame.Visible = false          -- Hide popup

		-- Execute callback
		if widgetData.Callback then
			task.spawn(widgetData.Callback, newColor)
		end
	end)
	table.insert(window._connections, con3)

	return widgetData
end


return SharkUI -- Return the library table
