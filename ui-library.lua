-- SharkUI_Library (ModuleScript)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Library table to be returned
local SharkUI = {}
SharkUI.__index = SharkUI

-- =============================================
-- Internal Helper Functions
-- =============================================

local function createRoundedFrame(name, parent, size, position, color, radius, transparency, zIndex)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size or UDim2.new(1, 0, 1, 0)
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.ZIndex = zIndex or 1
    frame.Parent = parent

    if radius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = radius
        corner.Parent = frame
    end
    return frame
end

local function createTextLabel(name, parent, size, position, text, textColor, textSize, font, alignment, transparency, zIndex)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = transparency or 1
    label.Text = text or ""
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.TextSize = textSize or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    label.ZIndex = zIndex or 1
    label.Parent = parent
    return label
end

local function createTextButton(name, parent, size, position, text, textColor, textSize, font, transparency, zIndex)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(1, 0, 1, 0)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = transparency or 1
    button.Text = text or ""
    button.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    button.TextSize = textSize or 14
    button.Font = font or Enum.Font.GothamBold
    button.AutoButtonColor = false -- Disable default button color changes
    button.ZIndex = zIndex or 1
    button.Parent = parent
    return button
end

local function createImageButton(name, parent, size, position, image, offset, rectSize, color, transparency, zIndex)
    local button = Instance.new("ImageButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 32, 0, 32)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = transparency or 1
    button.Image = image or ""
    button.ImageRectOffset = offset or Vector2.new(0, 0)
    button.ImageRectSize = rectSize or Vector2.new(0, 0)
    button.ImageColor3 = color or Color3.fromRGB(255, 255, 255)
    button.AutoButtonColor = false
    button.ZIndex = zIndex or 1
    button.Parent = parent
    return button
end

local function createScrollingFrame(name, parent, size, position, scrollbarColor)
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = name
    scrollingFrame.Size = size
    scrollingFrame.Position = position
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.ScrollBarImageColor3 = scrollbarColor or Color3.fromRGB(78, 93, 234)
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    scrollingFrame.Parent = parent

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = scrollingFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = scrollingFrame

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)

    return scrollingFrame, listLayout
end

local function tween(instance, info, goal)
    local t = TweenService:Create(instance, info, goal)
    t:Play()
    return t
end

-- =============================================
-- Core Window Creation
-- =============================================

function SharkUI.new(options)
    local self = setmetatable({}, SharkUI)

    options = options or {}
    self.Title = options.Title or "SharkUI Window"
    self.Width = options.Width or 500
    self.Height = options.Height or 350
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.Insert
    self.ThemeColor = options.ThemeColor or Color3.fromRGB(78, 93, 234)
    self.AccentColor = options.AccentColor or Color3.fromRGB(255, 255, 255)
    self.BackgroundColor = options.BackgroundColor or Color3.fromRGB(20, 20, 25)
    self.SidebarColor = options.SidebarColor or Color3.fromRGB(25, 25, 30)
    self.TitleBarColor = options.TitleBarColor or Color3.fromRGB(15, 15, 20)
    self.InactiveColor = options.InactiveColor or Color3.fromRGB(150, 150, 150)
    self.TextColor = options.TextColor or Color3.fromRGB(255, 255, 255)
    self.ToggleBgColor = options.ToggleBgColor or Color3.fromRGB(40, 40, 45)
    self.SliderTrackColor = options.SliderTrackColor or Color3.fromRGB(40, 40, 45)
    self.PopupBgColor = options.PopupBgColor or Color3.fromRGB(30, 30, 35)
    self.AnimationSpeed = options.AnimationSpeed or 0.3
    self.EaseStyle = options.EaseStyle or Enum.EasingStyle.Quart
    self.EaseDirection = options.EaseDirection or Enum.EasingDirection.Out
    self.CanClose = options.CanClose == nil and true or options.CanClose -- Default true
    self.CanMinimize = options.CanMinimize == nil and true or options.CanMinimize -- Default true
    self.StartVisible = options.StartVisible == nil and true or options.StartVisible
    self.ResetOnSpawn = options.ResetOnSpawn == nil and false or options.ResetOnSpawn
    self.ZIndexBehavior = options.ZIndexBehavior or Enum.ZIndexBehavior.Sibling

    self.Callbacks = {
        OnClose = options.OnClose,
        OnMinimize = options.OnMinimize,
        OnRestore = options.OnRestore,
        OnToggleVisible = options.OnToggleVisible,
    }

    self.UI = {} -- Store UI elements
    self.Categories = {} -- { Name = { Button = ..., Section = ... } }
    self.CurrentCategory = nil
    self.IsMinimized = false
    self.Connections = {} -- Store connections to disconnect later

    -- Create ScreenGui
    self.UI.ScreenGui = Instance.new("ScreenGui")
    self.UI.ScreenGui.Name = options.Name or "SharkUI_Window"
    self.UI.ScreenGui.ResetOnSpawn = self.ResetOnSpawn
    self.UI.ScreenGui.ZIndexBehavior = self.ZIndexBehavior
    self.UI.ScreenGui.Enabled = false -- Start disabled for animation
    self.UI.ScreenGui.Parent = PlayerGui

    -- Main frame
    self.UI.MainFrame = createRoundedFrame("MainFrame", self.UI.ScreenGui,
        UDim2.new(0, self.Width, 0, self.Height),
        UDim2.new(0.5, -self.Width / 2, 0.5, -self.Height / 2),
        self.BackgroundColor, nil, 0, 1)

    -- Title Bar
    self.UI.TitleBar = createRoundedFrame("TitleBar", self.UI.MainFrame,
        UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
        self.TitleBarColor, nil, 0, 2)

    self.UI.TitleText = createTextLabel("TitleText", self.UI.TitleBar,
        UDim2.new(1, -(self.CanClose and 30 or 0) - (self.CanMinimize and 30 or 0) - 10, 1, 0), -- Adjust width based on buttons
        UDim2.new(0, 10, 0, 0), self.Title, self.TextColor, 16, Enum.Font.GothamBold,
        Enum.TextXAlignment.Left, 1, 3)

    -- Close Button
    if self.CanClose then
        self.UI.CloseButton = createTextButton("CloseButton", self.UI.TitleBar,
            UDim2.new(0, 30, 0, 30), UDim2.new(1, -30, 0, 0), "✕", self.TextColor, 16, Enum.Font.GothamBold, 1, 3)

        table.insert(self.Connections, self.UI.CloseButton.MouseEnter:Connect(function()
            tween(self.UI.CloseButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 100, 100) })
        end))
        table.insert(self.Connections, self.UI.CloseButton.MouseLeave:Connect(function()
            tween(self.UI.CloseButton, TweenInfo.new(0.2), { TextColor3 = self.TextColor })
        end))
        table.insert(self.Connections, self.UI.CloseButton.MouseButton1Click:Connect(function()
            self:Destroy()
            if self.Callbacks.OnClose then self.Callbacks.OnClose() end
        end))
    end

    -- Minimize Button
    if self.CanMinimize then
        self.UI.MinimizeButton = createTextButton("MinimizeButton", self.UI.TitleBar,
            UDim2.new(0, 30, 0, 30), UDim2.new(1, -(self.CanClose and 60 or 30), 0, 0), "−", self.TextColor, 16, Enum.Font.GothamBold, 1, 3)

        table.insert(self.Connections, self.UI.MinimizeButton.MouseEnter:Connect(function()
            tween(self.UI.MinimizeButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(100, 200, 255) })
        end))
        table.insert(self.Connections, self.UI.MinimizeButton.MouseLeave:Connect(function()
            tween(self.UI.MinimizeButton, TweenInfo.new(0.2), { TextColor3 = self.TextColor })
        end))
        table.insert(self.Connections, self.UI.MinimizeButton.MouseButton1Click:Connect(function()
            self:_ToggleMinimize()
        end))
    end

    -- Draggable Logic
    self:_SetupDraggable()

    -- Keybind Toggle Logic
    self:_SetupKeybindToggle()

    -- Initial Animation
    if self.StartVisible then
        self:Show()
    else
        -- Ensure it's positioned correctly but scaled down if starting hidden
        self.UI.MainFrame.Size = UDim2.new(0, self.Width, 0, 0)
        self.UI.MainFrame.Position = UDim2.new(0.5, -self.Width / 2, 0.5, 0)
    end

    return self
end

-- =============================================
-- Window Methods
-- =============================================

function SharkUI:Destroy()
    if self.UI and self.UI.ScreenGui then
        -- Animate closing
        local anim = tween(self.UI.MainFrame, TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, self.Width, 0, 0),
            Position = UDim2.new(0.5, -self.Width / 2, 0.5, 0)
        })
        anim.Completed:Wait()
        self.UI.ScreenGui:Destroy()
    end

    -- Disconnect all connections
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}
    self.UI = nil
    self.Categories = nil
    setmetatable(self, nil) -- Allow garbage collection
end

function SharkUI:_SetupDraggable()
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        -- Use faster tween for dragging responsiveness
        tween(self.UI.MainFrame, TweenInfo.new(0.05), { Position = targetPosition })
    end

    table.insert(self.Connections, self.UI.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.UI.MainFrame.Position
            tween(self.UI.TitleBar, TweenInfo.new(0.1), { BackgroundColor3 = self.TitleBarColor:Lerp(Color3.new(0,0,0), 0.2) }) -- Slightly darken

            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    tween(self.UI.TitleBar, TweenInfo.new(0.1), { BackgroundColor3 = self.TitleBarColor })
                    if changedConn then changedConn:Disconnect() end -- Clean up listener
                end
            end)
        end
    end))

    table.insert(self.Connections, self.UI.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

function SharkUI:_SetupKeybindToggle()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.ToggleKey then
            self:ToggleVisible()
            if self.Callbacks.OnToggleVisible then self.Callbacks.OnToggleVisible(self.UI.ScreenGui.Enabled) end
        end
    end))
end

function SharkUI:_ToggleMinimize()
    if not self.CanMinimize then return end

    local sidebar = self.UI.Sidebar
    local contentArea = self.UI.ContentArea

    if self.IsMinimized then
        -- Restore with animation
        tween(self.UI.MainFrame, TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, self.Width, 0, self.Height)
        })
        task.wait(self.AnimationSpeed * 0.3) -- Allow frame to expand slightly before showing content
        if sidebar then sidebar.Visible = true end
        if contentArea then contentArea.Visible = true end
        self.UI.MinimizeButton.Text = "−"
        self.IsMinimized = false
        if self.Callbacks.OnRestore then self.Callbacks.OnRestore() end
    else
        -- Minimize with animation
        if sidebar then sidebar.Visible = false end
        if contentArea then contentArea.Visible = false end
        tween(self.UI.MainFrame, TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, self.Width, 0, 30) -- Title bar height
        })
        self.UI.MinimizeButton.Text = "+" -- Or use an icon
        self.IsMinimized = true
        if self.Callbacks.OnMinimize then self.Callbacks.OnMinimize() end
    end
end

function SharkUI:Show()
    if not self.UI or self.UI.ScreenGui.Enabled then return end -- Already visible or destroyed

    -- Reset size/pos for animation if needed
    self.UI.MainFrame.Size = UDim2.new(0, self.Width, 0, 0)
    self.UI.MainFrame.Position = UDim2.new(0.5, -self.Width / 2, 0.5, 0)
    self.UI.ScreenGui.Enabled = true -- Enable first

    tween(self.UI.MainFrame, TweenInfo.new(self.AnimationSpeed * 1.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width / 2, 0.5, -self.Height / 2)
    })
end

function SharkUI:Hide()
    if not self.UI or not self.UI.ScreenGui.Enabled then return end -- Already hidden or destroyed

    local anim = tween(self.UI.MainFrame, TweenInfo.new(self.AnimationSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, self.Width, 0, 0),
        Position = UDim2.new(0.5, -self.Width / 2, 0.5, 0)
    })

    anim.Completed:Wait()
    if self.UI and self.UI.ScreenGui then -- Check if not destroyed during animation
        self.UI.ScreenGui.Enabled = false
    end
end

function SharkUI:ToggleVisible()
    if not self.UI then return end
    if self.UI.ScreenGui.Enabled then
        self:Hide()
    else
        self:Show()
    end
end

function SharkUI:SetThemeColor(color)
    self.ThemeColor = color
    self.UI.ScreenGui.ScrollBarImageColor3 = color -- Example update, need more comprehensive update logic

    -- Update existing elements dynamically (more complex, requires tracking themed elements)
    -- Example: Update selected category button icon color
    if self.CurrentCategory and self.Categories[self.CurrentCategory] then
        self.Categories[self.CurrentCategory].Button.Icon.ImageColor3 = color
    end
    -- Add more updates here for toggles, sliders, etc.
    warn("SetThemeColor currently has limited dynamic update capabilities.")
end


-- =============================================
-- Sidebar and Content Area
-- =============================================

function SharkUI:AddSidebar(width)
    if self.UI.Sidebar then return self.UI.Sidebar end -- Already added

    width = width or 165
    self.SidebarWidth = width

    self.UI.Sidebar = createRoundedFrame("Sidebar", self.UI.MainFrame,
        UDim2.new(0, width, 1, -30), -- Below title bar
        UDim2.new(0, 0, 0, 30),
        self.SidebarColor, nil, 0, 2)

    -- Adjust content area position if it exists
    if self.UI.ContentArea then
         self.UI.ContentArea.Position = UDim2.new(0, self.SidebarWidth, 0, 30)
         self.UI.ContentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, -30)
    end

    return self.UI.Sidebar
end

function SharkUI:AddContentArea()
    if self.UI.ContentArea then return self.UI.ContentArea end -- Already added

    local sidebarWidth = self.SidebarWidth or 0

    self.UI.ContentArea = createRoundedFrame("ContentArea", self.UI.MainFrame,
        UDim2.new(1, -sidebarWidth, 1, -30), -- To the right of sidebar, below title bar
        UDim2.new(0, sidebarWidth, 0, 30),
        self.BackgroundColor, nil, 1, 2) -- Transparent background

    return self.UI.ContentArea
end

function SharkUI:AddLogo(logoOptions)
    if not self.UI.Sidebar then self:AddSidebar() end -- Ensure sidebar exists
    logoOptions = logoOptions or {}

    local areaHeight = logoOptions.Height or 110
    local logoSize = logoOptions.LogoSize or 60
    local logoText = logoOptions.Text or "SharkUI"
    local textSize = logoOptions.TextSize or 18

    local logoArea = createRoundedFrame("LogoArea", self.UI.Sidebar,
        UDim2.new(1, 0, 0, areaHeight), UDim2.new(0, 0, 0, 0),
        self.SidebarColor, nil, 1, 3) -- Transparent

    -- Create shark logo (Simplified - using a frame for placement)
    local sharkLogo = createRoundedFrame("SharkLogo", logoArea,
        UDim2.new(0, logoSize, 0, logoSize),
        UDim2.new(0.5, -logoSize/2, 0, 15),
        self.SidebarColor, nil, 1, 4) -- Transparent

    -- Placeholder for actual logo graphic/shape
    local logoPlaceholder = createRoundedFrame("LogoGraphic", sharkLogo,
        UDim2.new(0, logoSize*0.8, 0, logoSize*0.8), UDim2.new(0.5, -logoSize*0.4, 0.5, -logoSize*0.4),
        self.ThemeColor, UDim.new(0.5, 0), 0, 5) -- Circle Example

    local logoLabel = createTextLabel("LogoText", logoArea,
        UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, areaHeight - 35),
        logoText, self.TextColor, textSize, Enum.Font.GothamBold, Enum.TextXAlignment.Center, 1, 4)

    return logoArea
end

function SharkUI:AddCategory(categoryOptions)
    if not self.UI.Sidebar then self:AddSidebar() end
    if not self.UI.ContentArea then self:AddContentArea() end
    categoryOptions = categoryOptions or {}

    local name = categoryOptions.Name or "Unnamed Category"
    local icon = categoryOptions.Icon or "" -- e.g., "rbxassetid://..."
    local iconOffset = categoryOptions.IconOffset or Vector2.new(0, 0)
    local iconSize = categoryOptions.IconRectSize or Vector2.new(36, 36)
    local defaultSelected = categoryOptions.DefaultSelected or false

    local categoryCount = 0
    for _ in pairs(self.Categories) do categoryCount = categoryCount + 1 end
    local startY = (self.UI.Sidebar:FindFirstChild("LogoArea") and self.UI.Sidebar.LogoArea.AbsoluteSize.Y or 0) + 10

    local buttonFrame = createRoundedFrame(name .. "Button", self.UI.Sidebar,
        UDim2.new(1, 0, 0, 40),
        UDim2.new(0, 0, 0, startY + categoryCount * 40), -- Position below logo/previous buttons
        self.SidebarColor, nil, 1, 3) -- Transparent

    local iconButton = createImageButton("Icon", buttonFrame,
        UDim2.new(0, 24, 0, 24), UDim2.new(0, 30, 0.5, -12),
        icon, iconOffset, iconSize, self.InactiveColor, 1, 4)

    local label = createTextLabel("Label", buttonFrame,
        UDim2.new(0, 100, 1, 0), UDim2.new(0, 65, 0, 0),
        name, self.InactiveColor, 14, Enum.Font.Gotham, TextXAlignment.Left, 1, 4)

    -- Hover/Selection Highlight
    local highlight = createRoundedFrame("HoverHighlight", buttonFrame,
        UDim2.new(0.95, 0, 0.8, 0), UDim2.new(0.025, 0, 0.1, 0),
        self.ThemeColor, UDim.new(0, 6), 1, 2) -- Initially transparent

    -- Category Content Section
    local sectionFrame = createRoundedFrame(name .. "Section", self.UI.ContentArea,
        UDim2.new(1, -20, 1, -20), UDim2.new(0, 10, 0, 10),
        self.BackgroundColor, nil, 1, 3) -- Transparent
    sectionFrame.Visible = false -- Initially hidden

    local titleLabel = createTextLabel(name .. "Title", sectionFrame,
        UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
        name, self.TextColor, 16, Enum.Font.GothamBold, TextXAlignment.Left, 1, 4)

    local scrollFrame, listLayout = createScrollingFrame(name .. "Scroll", sectionFrame,
        UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40),
        self.ThemeColor)

    -- Store references
    self.Categories[name] = {
        Button = { Frame = buttonFrame, Icon = iconButton, Label = label, Highlight = highlight },
        Section = { Frame = sectionFrame, Title = titleLabel, Scroll = scrollFrame, Layout = listLayout },
        Items = {} -- To store toggles, sliders etc. within this category
    }

    -- Click/Hover Logic
    local function handleInteraction()
        self:SelectCategory(name)
    end

    table.insert(self.Connections, buttonFrame.MouseEnter:Connect(function()
        if self.CurrentCategory ~= name then
            tween(highlight, TweenInfo.new(0.2), { BackgroundTransparency = 0.8 })
        end
    end))
    table.insert(self.Connections, buttonFrame.MouseLeave:Connect(function()
        if self.CurrentCategory ~= name then
            tween(highlight, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
        end
    end))
    table.insert(self.Connections, buttonFrame.MouseButton1Click:Connect(handleInteraction))
    table.insert(self.Connections, iconButton.MouseButton1Click:Connect(handleInteraction))

    -- Select if default
    if defaultSelected and not self.CurrentCategory then
        self:SelectCategory(name)
    elseif not self.CurrentCategory and categoryCount == 0 then -- Select first category if none specified
         self:SelectCategory(name)
    end

    return self.Categories[name].Section -- Return the section object for adding items
end

function SharkUI:SelectCategory(name)
    if not self.Categories[name] or self.CurrentCategory == name then return end

    -- Deselect previous category
    if self.CurrentCategory and self.Categories[self.CurrentCategory] then
        local prevCat = self.Categories[self.CurrentCategory]
        prevCat.Button.Icon.ImageColor3 = self.InactiveColor
        prevCat.Button.Label.TextColor3 = self.InactiveColor
        prevCat.Button.Highlight.BackgroundTransparency = 1
        prevCat.Section.Frame.Visible = false
        prevCat.Section.Frame.Position = UDim2.new(0, 10, 0, 10) -- Reset position if animated (though we removed animation)
    end

    -- Select new category
    local newCat = self.Categories[name]
    newCat.Button.Icon.ImageColor3 = self.ThemeColor
    newCat.Button.Label.TextColor3 = self.TextColor
    newCat.Button.Highlight.BackgroundTransparency = 0.8 -- Active selection highlight
    newCat.Section.Frame.Visible = true
    newCat.Section.Frame.Position = UDim2.new(0, 10, 0, 10) -- Ensure correct position

    self.CurrentCategory = name
end

-- =============================================
-- Content Item Creation Methods (Add to Section)
-- =============================================
-- These methods would ideally be methods of the 'section' object returned by AddCategory,
-- but for simplicity, we'll make them methods of the main window object that take the category name.

function SharkUI:AddToggle(categoryName, itemOptions)
    if not self.Categories[categoryName] then warn("Category not found:", categoryName) return end
    local section = self.Categories[categoryName].Section
    itemOptions = itemOptions or {}

    local name = itemOptions.Name or "Unnamed Toggle"
    local defaultState = itemOptions.Default or false
    local callback = itemOptions.Callback -- function(newState)

    local order = #self.Categories[categoryName].Items + 1

    local optionFrame = createRoundedFrame(name .. "Option", section.Scroll,
        UDim2.new(1, 0, 0, 30), nil, self.BackgroundColor, nil, 1, 4)
    optionFrame.LayoutOrder = order

    local label = createTextLabel("Label", optionFrame,
        UDim2.new(1, -50, 1, 0), nil, name, self.TextColor, 14, Enum.Font.Gotham, TextXAlignment.Left, 1, 5)

    -- Toggle Button
    local toggleButton = createRoundedFrame("ToggleButton", optionFrame,
        UDim2.new(0, 40, 0, 20), UDim2.new(1, -45, 0.5, -10),
        defaultState and self.ThemeColor or self.ToggleBgColor,
        UDim.new(1, 0), 0, 5)

    local toggleIndicator = createRoundedFrame("Indicator", toggleButton,
        UDim2.new(0, 16, 0, 16),
        defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        self.AccentColor, UDim.new(1, 0), 0, 6)

    local currentState = defaultState

    table.insert(self.Connections, toggleButton.MouseButton1Click:Connect(function()
        currentState = not currentState

        local newColor = currentState and self.ThemeColor or self.ToggleBgColor
        local newPos = currentState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)

        tween(toggleButton, TweenInfo.new(0.2), { BackgroundColor3 = newColor })
        tween(toggleIndicator, TweenInfo.new(0.2), { Position = newPos })

        if callback then
            task.spawn(callback, currentState) -- Use task.spawn for safety
        end
    end))

    local itemRef = { Type = "Toggle", Frame = optionFrame, Label = label, Button = toggleButton, Indicator = toggleIndicator, GetState = function() return currentState end }
    table.insert(self.Categories[categoryName].Items, itemRef)
    return itemRef
end

function SharkUI:AddSlider(categoryName, itemOptions)
    if not self.Categories[categoryName] then warn("Category not found:", categoryName) return end
    local section = self.Categories[categoryName].Section
    itemOptions = itemOptions or {}

    local name = itemOptions.Name or "Unnamed Slider"
    local minVal = itemOptions.Min or 0
    local maxVal = itemOptions.Max or 100
    local defaultVal = math.clamp(itemOptions.Default or (minVal + maxVal) / 2, minVal, maxVal)
    local increment = itemOptions.Increment or 0.1 -- Step value
    local callback = itemOptions.Callback -- function(newValue)

    local order = #self.Categories[categoryName].Items + 1

    local sliderFrame = createRoundedFrame(name .. "Slider", section.Scroll,
        UDim2.new(1, 0, 0, 50), nil, self.BackgroundColor, nil, 1, 4)
    sliderFrame.LayoutOrder = order

    local label = createTextLabel("Label", sliderFrame,
        UDim2.new(1, 0, 0, 20), nil, name, self.TextColor, 14, Enum.Font.Gotham, TextXAlignment.Left, 1, 5)

    local valueLabel = createTextLabel("Value", sliderFrame,
        UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, 0), -- Positioned next to label initially
        tostring(defaultVal), self.TextColor, 14, Enum.Font.Gotham, TextXAlignment.Right, 1, 5)

    local track = createRoundedFrame("Track", sliderFrame,
        UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0, 30), -- Below label/value
        self.SliderTrackColor, UDim.new(1, 0), 0, 5)

    local fill = createRoundedFrame("Fill", track,
        UDim2.new(0, 0, 1, 0), nil, -- Initial size set below
        self.ThemeColor, UDim.new(1, 0), 0, 6)

    local knob = createRoundedFrame("Knob", track,
        UDim2.new(0, 16, 0, 16), nil, -- Initial position set below
        self.AccentColor, UDim.new(1, 0), 0, 7)

    local currentValue = defaultVal
    local isDragging = false

    local function updateSliderVisuals(value)
        local ratio = (value - minVal) / (maxVal - minVal)
        ratio = math.clamp(ratio, 0, 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -8, 0.5, -8) -- Center knob on position
        valueLabel.Text = string.format("%." .. (math.floor(increment) == increment and 0 or 1) .. "f", value) -- Format based on increment
    end

    local function setValue(value, triggerCallback)
        local snappedValue = math.floor(value / increment + 0.5) * increment -- Snap to increment
        snappedValue = math.clamp(snappedValue, minVal, maxVal)
        if snappedValue ~= currentValue then
            currentValue = snappedValue
            updateSliderVisuals(currentValue)
            if triggerCallback and callback then
                task.spawn(callback, currentValue)
            end
        end
    end

    updateSliderVisuals(currentValue) -- Set initial state

    local function handleDrag(input)
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        if trackAbsSize == 0 then return end -- Avoid division by zero if not visible yet

        local mouseX = input.Position.X
        local ratio = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
        local targetValue = minVal + ratio * (maxVal - minVal)
        setValue(targetValue, true)
    end

    table.insert(self.Connections, track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            tween(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18), Position = knob.Position - UDim2.fromOffset(1, 1) })
            handleDrag(input) -- Update on initial click
        end
    end))

    table.insert(self.Connections, knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            tween(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18), Position = knob.Position - UDim2.fromOffset(1, 1) })
        end
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
            isDragging = false
            tween(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 16, 0, 16), Position = knob.Position + UDim2.fromOffset(1, 1) })
        end
    end))

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            handleDrag(input)
        end
    end))

    local itemRef = { Type = "Slider", Frame = sliderFrame, GetValue = function() return currentValue end, SetValue = function(v) setValue(v, false) end }
    table.insert(self.Categories[categoryName].Items, itemRef)
    return itemRef
end


function SharkUI:AddColorPicker(categoryName, itemOptions)
     if not self.Categories[categoryName] then warn("Category not found:", categoryName) return end
    local section = self.Categories[categoryName].Section
    itemOptions = itemOptions or {}

    local name = itemOptions.Name or "Unnamed Color"
    local defaultColor = itemOptions.Default or Color3.new(1, 1, 1)
    local callback = itemOptions.Callback -- function(newColor)

    local order = #self.Categories[categoryName].Items + 1

    -- Main item frame
    local colorFrame = createRoundedFrame(name .. "Color", section.Scroll,
        UDim2.new(1, 0, 0, 30), nil, self.BackgroundColor, nil, 1, 4)
    colorFrame.LayoutOrder = order

    local label = createTextLabel("Label", colorFrame,
        UDim2.new(1, -50, 1, 0), nil, name, self.TextColor, 14, Enum.Font.Gotham, TextXAlignment.Left, 1, 5)

    -- Color Preview (acts as the button)
    local previewButton = createTextButton("PreviewButton", colorFrame,
        UDim2.new(0, 30, 0, 18), UDim2.new(1, -35, 0.5, -9),
        "", nil, 0, nil, 0, 5) -- Visible background
    previewButton.BackgroundColor3 = defaultColor
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = previewButton

    -- Popup Frame (Initially Hidden)
    local popupFrame = createRoundedFrame(name .. "Popup", self.UI.MainFrame, -- Parent to MainFrame for ZIndex
        UDim2.new(0, 220, 0, 285), UDim2.new(0, 0, 0, 0), -- Positioned on click
        self.PopupBgColor, UDim.new(0, 6), 0, 100) -- High ZIndex
    popupFrame.Visible = false

    local popupContainer = createRoundedFrame("Container", popupFrame,
        UDim2.new(1, 0, 1, 0), nil, self.PopupBgColor, nil, 1, 101)
    local popupPadding = Instance.new("UIPadding")
    popupPadding.Padding = UDim.new(0, 15)
    popupPadding.Parent = popupContainer

    local popupTitle = createTextLabel("Title", popupContainer,
        UDim2.new(1, -30, 0, 30), UDim2.new(0, 0, 0, -5), -- Adjust for padding
        name, self.TextColor, 16, Enum.Font.GothamBold, TextXAlignment.Left, 1, 102)

    local popupClose = createTextButton("CloseButton", popupContainer,
        UDim2.new(0, 24, 0, 24), UDim2.new(1, -24, 0, -2), -- Adjust for padding
        "✕", self.TextColor, 16, Enum.Font.GothamBold, 1, 102)

    local popupPreview = createRoundedFrame("PopupPreview", popupContainer,
        UDim2.new(0, 60, 0, 30), UDim2.new(0.5, -30, 0, 35), -- Below title
        defaultColor, UDim.new(0, 4), 0, 102)

    local currentColor = defaultColor
    local sliders = {}

    -- Internal helper to create R, G, B sliders within the popup
    local function createColorSlider(sliderName, value, yPos)
        local sliderContainer = createRoundedFrame(sliderName .. "Container", popupContainer,
            UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, yPos), self.PopupBgColor, nil, 1, 102)

        local sLabel = createTextLabel("Label", sliderContainer,
            UDim2.new(0, 20, 0, 20), nil, sliderName, self.TextColor, 14, Enum.Font.GothamBold, TextXAlignment.Left, 1, 103)

        local sValueLabel = createTextLabel("Value", sliderContainer,
             UDim2.new(0, 40, 0, 20), UDim2.new(1, -40, 0, 0), tostring(value),
             self.TextColor, 14, Enum.Font.Gotham, TextXAlignment.Right, 1, 103)

        local sTrack = createRoundedFrame("Track", sliderContainer,
            UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0, 25), self.SliderTrackColor, UDim.new(1, 0), 0, 103)

        local colorMap = { R = Color3.new(1, 0, 0), G = Color3.new(0, 1, 0), B = Color3.new(0, 0, 1) }
        local sFill = createRoundedFrame("Fill", sTrack,
            UDim2.new(value / 255, 0, 1, 0), nil, colorMap[sliderName]:Lerp(Color3.new(1,1,1), 0.5), UDim.new(1, 0), 0, 104)

        local sKnob = createRoundedFrame("Knob", sTrack,
            UDim2.new(0, 16, 0, 16), UDim2.new(value / 255, -8, 0.5, -8), self.AccentColor, UDim.new(1, 0), 0, 105)

        local isDragging = false
        local currentSliderValue = value

        local function updateColorPreview()
            local r = sliders.R and sliders.R.GetValue() or 0
            local g = sliders.G and sliders.G.GetValue() or 0
            local b = sliders.B and sliders.B.GetValue() or 0
            popupPreview.BackgroundColor3 = Color3.fromRGB(r, g, b)
        end

        local function handleDrag(input)
            local trackAbsPos = sTrack.AbsolutePosition.X
            local trackAbsSize = sTrack.AbsoluteSize.X
            if trackAbsSize == 0 then return end

            local mouseX = input.Position.X
            local ratio = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            currentSliderValue = math.floor(ratio * 255 + 0.5)

            sFill.Size = UDim2.new(ratio, 0, 1, 0)
            sKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
            sValueLabel.Text = tostring(currentSliderValue)
            updateColorPreview()
        end

        table.insert(self.Connections, sTrack.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; handleDrag(input) end end))
        table.insert(self.Connections, sKnob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true end end))
        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end))
        table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input) if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then handleDrag(input) end end))

        return { Container = sliderContainer, GetValue = function() return currentSliderValue end, SetValue = function(v)
            currentSliderValue = math.clamp(math.floor(v + 0.5), 0, 255)
            local ratio = currentSliderValue / 255
            sFill.Size = UDim2.new(ratio, 0, 1, 0)
            sKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
            sValueLabel.Text = tostring(currentSliderValue)
            updateColorPreview()
        end }
    end

    sliders.R = createColorSlider("R", defaultColor.R * 255, 80)
    sliders.G = createColorSlider("G", defaultColor.G * 255, 130)
    sliders.B = createColorSlider("B", defaultColor.B * 255, 180)

    -- Apply Button
    local applyButton = createTextButton("ApplyButton", popupContainer,
        UDim2.new(0.5, -10, 0, 30), UDim2.new(0.25, 0, 1, -35), -- Centered-ish at bottom
        "Apply", self.TextColor, 14, Enum.Font.GothamBold, 0, 102)
    applyButton.BackgroundColor3 = self.ThemeColor
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 4)
    applyCorner.Parent = applyButton

    -- Apply Logic
    table.insert(self.Connections, applyButton.MouseButton1Click:Connect(function()
        local r = sliders.R.GetValue()
        local g = sliders.G.GetValue()
        local b = sliders.B.GetValue()
        local newColor = Color3.fromRGB(r, g, b)

        currentColor = newColor
        previewButton.BackgroundColor3 = newColor
        popupFrame.Visible = false

        if callback then
            task.spawn(callback, newColor)
        end
    end))

    -- Close Popup Logic
    table.insert(self.Connections, popupClose.MouseButton1Click:Connect(function()
        popupFrame.Visible = false
        -- Reset sliders to last applied color on close without apply
        sliders.R.SetValue(currentColor.R * 255)
        sliders.G.SetValue(currentColor.G * 255)
        sliders.B.SetValue(currentColor.B * 255)
    end))

    -- Open Popup Logic
    table.insert(self.Connections, previewButton.MouseButton1Click:Connect(function()
        if popupFrame.Visible then
            popupFrame.Visible = false
        else
            -- Position popup near the button, ensuring it's on screen
            local buttonPos = previewButton.AbsolutePosition
            local buttonSize = previewButton.AbsoluteSize
            local popupSize = popupFrame.AbsoluteSize
            local viewSize = self.UI.MainFrame.AbsoluteSize -- Use main frame as boundary

            local x = buttonPos.X + buttonSize.X + 5 -- Default right
            local y = buttonPos.Y -- Default aligned top

            -- Check right boundary
            if x + popupSize.X > viewSize.X then
                x = buttonPos.X - popupSize.X - 5 -- Try left
            end
            -- Check left boundary (if moved left)
            if x < 0 then
                x = 5 -- Fallback
            end

            -- Check bottom boundary
            if y + popupSize.Y > viewSize.Y then
                y = viewSize.Y - popupSize.Y - 5 -- Move up
            end
            -- Check top boundary
             if y < self.UI.TitleBar.AbsoluteSize.Y then -- Don't overlap titlebar
                y = self.UI.TitleBar.AbsoluteSize.Y + 5
            end

            -- Convert back to Offset for UDim2
            local mainFramePos = self.UI.MainFrame.AbsolutePosition
            popupFrame.Position = UDim2.fromOffset(x - mainFramePos.X, y - mainFramePos.Y)

            popupFrame.Visible = true
            popupFrame.Parent = self.UI.MainFrame -- Ensure it's on top

            -- Hide other popups
             for _, child in ipairs(self.UI.MainFrame:GetChildren()) do
                 if child:IsA("Frame") and child.Name:match("Popup$") and child ~= popupFrame then
                     child.Visible = false
                 end
             end
        end
    end))

    local itemRef = { Type = "ColorPicker", Frame = colorFrame, GetColor = function() return currentColor end, SetColor = function(c)
         currentColor = c
         previewButton.BackgroundColor3 = c
         sliders.R.SetValue(c.R * 255)
         sliders.G.SetValue(c.G * 255)
         sliders.B.SetValue(c.B * 255)
     end }
    table.insert(self.Categories[categoryName].Items, itemRef)
    return itemRef
end

-- =============================================
-- Final Return
-- =============================================

return SharkUI
