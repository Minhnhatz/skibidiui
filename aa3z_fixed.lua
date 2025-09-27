local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

local redzlib = {
	Themes = {
		Darker = {
			["Color Hub 1"] = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(25, 25, 25)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(32, 32, 32)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(25, 25, 25))
			}),
			["Color Hub 2"] = Color3.fromRGB(30, 30, 30),
			["Color Stroke"] = Color3.fromRGB(40, 40, 40),
			["Color Theme"] = Color3.fromRGB(88, 101, 242),
			["Color Text"] = Color3.fromRGB(243, 243, 243),
			["Color Dark Text"] = Color3.fromRGB(180, 180, 180)
		},
		Dark = {
			["Color Hub 1"] = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(40, 40, 40)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(48, 48, 48)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(40, 40, 40))
			}),
			["Color Hub 2"] = Color3.fromRGB(45, 45, 45),
			["Color Stroke"] = Color3.fromRGB(65, 65, 65),
			["Color Theme"] = Color3.fromRGB(65, 150, 255),
			["Color Text"] = Color3.fromRGB(245, 245, 245),
			["Color Dark Text"] = Color3.fromRGB(190, 190, 190)
		},
		Purple = {
			["Color Hub 1"] = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(28, 25, 30)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(32, 32, 32)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(28, 25, 30))
			}),
			["Color Hub 2"] = Color3.fromRGB(30, 30, 30),
			["Color Stroke"] = Color3.fromRGB(40, 40, 40),
			["Color Theme"] = Color3.fromRGB(150, 0, 255),
			["Color Text"] = Color3.fromRGB(240, 240, 240),
			["Color Dark Text"] = Color3.fromRGB(180, 180, 180)
		}
	},
	Info = {
		Version = "1.1.0"
	},
	Save = {
		UISize = {550, 380},
		TabSize = 160,
		Theme = "Darker"
	},
	Settings = {},
	Connection = {},
	Instances = {},
	Elements = {},
	Options = {},
	Flags = {},
	Tabs = {},
	Icons = {
		["home"] = "rbxassetid://10723407389"
	}
}

local ViewportSize = workspace:WaitForChild("Camera").ViewportSize
local UIScale = ViewportSize.Y / 450

local Settings = redzlib.Settings
local Flags = redzlib.Flags

local SetProps, SetChildren, InsertTheme, Create do
	InsertTheme = function(Instance, Type)
		table.insert(redzlib.Instances, {
			Instance = Instance,
			Type = Type
		})
		return Instance
	end
	
	SetChildren = function(Instance, Children)
		if Children then
			for k,v in pairs(Children) do
				v.Parent = Instance
			end
		end
		return Instance
	end
	
	SetProps = function(Instance, Props)
		if Props then
			for k,v in pairs(Props) do
				Instance[k] = v
			end
		end
		return Instance
	end
	
	Create = function(...)
		local args = {...}
		local new = Instance.new(args[1])
		
		-- AUTO-INJECT: Add subtle UICorner and hover (no strokes)
		pcall(function()
			if new and typeof(new) == "Instance" then
				if new:IsA("Frame") or new:IsA("TextButton") or new:IsA("TextLabel") or new:IsA("ScrollingFrame") or new:IsA("ImageButton") then
					local __corner = Instance.new("UICorner")
					__corner.CornerRadius = UDim.new(0, 6) -- slightly rounded
					__corner.Parent = new

					-- Hover animation for buttons (best-effort)
					if new:IsA("TextButton") or new:IsA("ImageButton") then
						local ok, orig = pcall(function() return new.BackgroundColor3 end)
						local originalBG = ok and orig or Color3.fromRGB(65, 150, 255)
						new.MouseEnter:Connect(function()
							pcall(function()
								game:GetService('TweenService'):Create(new, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.new(math.min(1, originalBG.R+0.14), math.min(1, originalBG.G+0.14), math.min(1, originalBG.B+0.14)), BackgroundTransparency = math.max(0, (new.BackgroundTransparency or 0) - 0.05)}):Play()
							end)
						end)
						new.MouseLeave:Connect(function()
							pcall(function()
								game:GetService('TweenService'):Create(new, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = originalBG, BackgroundTransparency = new.BackgroundTransparency or 0}):Play()
							end)
						end)
					end
				end
			end
		end)
		
		local Children = {}
		
		if type(args[2]) == "table" then
			SetProps(new, args[2])
			SetChildren(new, args[3])
			Children = args[3] or {}
		elseif typeof(args[2]) == "Instance" then
			new.Parent = args[2]
			SetProps(new, args[3])
			SetChildren(new, args[4])
			Children = args[4] or {}
		end
		return new
	end
end

local Funcs = {}
function Funcs:FireCallback(tab, ...)
	for _,v in ipairs(tab) do
		if type(v) == "function" then
			task.spawn(v, ...)
		end
	end
end

function Funcs:ToggleVisible(Obj, Bool)
	Obj.Visible = Bool ~= nil and Bool or not Obj.Visible
end

function Funcs:GetCallback(Configs, index)
	local func = Configs[index] or Configs.Callback or function()end
	if type(func) == "table" then
		return {function(Value) func[1][func[2]] = Value end}
	end
	return {func}
end

local Connections, Connection = {}, redzlib.Connection

local GetFlag, SetFlag, CheckFlag do
	CheckFlag = function(Name)
		return type(Name) == "string" and Flags[Name] ~= nil
	end
	
	GetFlag = function(Name)
		return type(Name) == "string" and Flags[Name]
	end
	
	SetFlag = function(Flag, Value)
		if Flag and (Value ~= Flags[Flag] or type(Value) == "table") then
			Flags[Flag] = Value
		end
	end
end

local ScreenGui = Create("ScreenGui", CoreGui, {
	Name = "redz Library V5",
}, {
	Create("UIScale", {
		Scale = UIScale,
		Name = "Scale"
	})
})

local ScreenFind = CoreGui:FindFirstChild(ScreenGui.Name)
if ScreenFind and ScreenFind ~= ScreenGui then
	ScreenFind:Destroy()
end

local function GetStr(val)
	if type(val) == "function" then
		return val()
	end
	return val
end

local function CreateTween(Configs)
	local Instance = Configs[1] or Configs.Instance
	local Prop = Configs[2] or Configs.Prop
	local NewVal = Configs[3] or Configs.NewVal
	local Time = Configs[4] or Configs.Time or 0.5
	local TweenWait = Configs[5] or Configs.wait or false
	local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quint)
	
	local Tween = TweenService:Create(Instance, TweenInfo, {[Prop] = NewVal})
	Tween:Play()
	if TweenWait then
		Tween.Completed:Wait()
	end
	return Tween
end

local function MakeDrag(Instance)
	task.spawn(function()
		SetProps(Instance, {
			Active = true,
			AutoButtonColor = false
		})
		
		local DragStart, StartPos, InputOn
		
		local function Update(Input)
			if not DragStart or not StartPos then return end
			local delta = Input.Position - DragStart
			local Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X / UIScale, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y / UIScale)
			CreateTween({Instance, "Position", Position, 0.35})
		end
		
		Instance.MouseButton1Down:Connect(function()
			InputOn = true
		end)
		
		Instance.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				StartPos = Instance.Position
				DragStart = Input.Position
				
				local connection
				connection = UserInputService.InputChanged:Connect(function(movementInput)
					if movementInput.UserInputType == Enum.UserInputType.MouseMovement and InputOn then
						Update(movementInput)
					end
				end)
				
				local endConnection
				endConnection = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
						InputOn = false
						connection:Disconnect()
						endConnection:Disconnect()
					end
				end)
			end
		end)
	end)
	return Instance
end

local function VerifyTheme(Theme)
	for name,_ in pairs(redzlib.Themes) do
		if name == Theme then
			return true
		end
	end
	return false
end

local Theme = redzlib.Themes[redzlib.Save.Theme]

local function AddEle(Name, Func)
	redzlib.Elements[Name] = Func
end

local function Make(Ele, Instance, props, ...)
	local Element = redzlib.Elements[Ele](Instance, props, ...)
	return Element
end

AddEle("Corner", function(parent, CornerRadius)
	local New = Create("UICorner", parent, {
		CornerRadius = CornerRadius or UDim.new(0, 7)
	})
	return New
end)

AddEle("Button", function(parent, props, ...)
	local args = {...}
	local New = InsertTheme(SetProps(Create("TextButton", parent, {
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme["Color Hub 2"],
		AutoButtonColor = false
	}), props), "Frame")
	
	New.MouseEnter:Connect(function()
		New.BackgroundTransparency = 0.4
	end)
	New.MouseLeave:Connect(function()
		New.BackgroundTransparency = 0
	end)
	if args[1] then
		New.Activated:Connect(args[1])
	end
	return New
end)

AddEle("Gradient", function(parent, props, ...)
	local args = {...}
	local New = InsertTheme(SetProps(Create("UIGradient", parent, {
		Color = Theme["Color Hub 1"]
	}), props), "Gradient")
	return New
end)

function redzlib:GetIcon(index)
	if type(index) ~= "string" or index:find("rbxassetid://") or #index == 0 then
		return index
	end
	
	local firstMatch = nil
	index = string.lower(index):gsub("lucide", ""):gsub("-", "")
	
	if self.Icons[index] then
		return self.Icons[index]
	end
	
	for Name, Icon in pairs(self.Icons) do
		if Name == index then
			return Icon
		elseif not firstMatch and Name:find(index, 1, true) then
			firstMatch = Icon
		end
	end
	
	return firstMatch or index
end

function redzlib:SetScale(NewScale)
	NewScale = ViewportSize.Y / math.clamp(NewScale, 300, 2000)
	UIScale, ScreenGui.Scale.Scale = NewScale, NewScale
end

function redzlib:MakeWindow(Configs)
	local WTitle = Configs[1] or Configs.Name or Configs.Title or "redz Library V5"
	local WMiniText = Configs[2] or Configs.SubTitle or "by : redz9999"
	
	Settings.ScriptFile = Configs[3] or Configs.SaveFolder or false
	
	local UISizeX, UISizeY = unpack(redzlib.Save.UISize)
	local MainFrame = InsertTheme(Create("ImageButton", ScreenGui, {
		Size = UDim2.fromOffset(UISizeX, UISizeY),
		Position = UDim2.new(0.5, -UISizeX/2, 0.5, -UISizeY/2),
		BackgroundTransparency = 0.03,
		Name = "Hub"
	}), "Main")
	
	Make("Gradient", MainFrame, {
		Rotation = 45
	})
	MakeDrag(MainFrame)
	
	local MainCorner = Make("Corner", MainFrame)
	
	local Components = Create("Folder", MainFrame, {
		Name = "Components"
	})
	
	local TopBar = Create("Frame", Components, {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Name = "Top Bar"
	})
	
	local Title = InsertTheme(Create("TextLabel", TopBar, {
		Position = UDim2.new(0, 15, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		AutomaticSize = "XY",
		Text = WTitle,
		TextXAlignment = "Left",
		TextSize = 12,
		TextColor3 = Theme["Color Text"],
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Name = "Title"
	}, {
		InsertTheme(Create("TextLabel", {
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = "X",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(1, 5, 0.9),
			Text = WMiniText,
			TextColor3 = Theme["Color Dark Text"],
			BackgroundTransparency = 1,
			TextXAlignment = "Left",
			TextYAlignment = "Bottom",
			TextSize = 8,
			Font = Enum.Font.Gotham,
			Name = "SubTitle"
		}), "DarkText")
	}), "Text")
	
	local MainScroll = InsertTheme(Create("ScrollingFrame", Components, {
		Size = UDim2.new(0, redzlib.Save.TabSize, 1, -TopBar.Size.Y.Offset),
		ScrollBarImageColor3 = Theme["Color Theme"],
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		ScrollBarThickness = 1.5,
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = "Y",
		ScrollingDirection = "Y",
		BorderSizePixel = 0,
		Name = "Tab Scroll"
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10)
		}), 
		Create("UIListLayout", {
			Padding = UDim.new(0, 5)
		})
	}), "ScrollBar")
	
	local Containers = Create("Frame", Components, {
		Size = UDim2.new(1, -MainScroll.Size.X.Offset, 1, -TopBar.Size.Y.Offset),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Name = "Containers"
	})
	
	local ButtonsFolder = Create("Folder", TopBar, {
		Name = "Buttons"
	})
	
	local CloseButton = Create("ImageButton", ButtonsFolder, {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(1, -10, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10747384394",
		AutoButtonColor = false,
		Name = "Close"
	})
	
	local MinimizeButton = Create("ImageButton", ButtonsFolder, {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(1, -35, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10734896206",
		AutoButtonColor = false,
		Name = "Minimize"
	})
	
	local Minimized, SaveSize, WaitClick = false, nil, false
	local Window, FirstTab = {}, false
	
	function Window:CloseBtn()
		ScreenGui:Destroy()
	end
	
	function Window:MinimizeBtn()
		if WaitClick then return end
		WaitClick = true
		
		if Minimized then
			MinimizeButton.Image = "rbxassetid://10734896206"
			CreateTween({MainFrame, "Size", SaveSize, 0.25, true})
			Minimized = false
		else
			MinimizeButton.Image = "rbxassetid://10734924532"
			SaveSize = MainFrame.Size
			CreateTween({MainFrame, "Size", UDim2.fromOffset(MainFrame.Size.X.Offset, 28), 0.25, true})
			Minimized = true
		end
		
		WaitClick = false
	end
	
	function Window:Minimize()
		MainFrame.Visible = not MainFrame.Visible
	end
	
	function Window:Set(Val1, Val2)
		if type(Val1) == "string" and type(Val2) == "string" then
			Title.Text = Val1
			Title.SubTitle.Text = Val2
		elseif type(Val1) == "string" then
			Title.Text = Val1
		end
	end
	
	local ContainerList = {}
	
	function Window:MakeTab(paste, Configs)
		if type(paste) == "table" then 
			Configs = paste 
		end
		local TName = Configs[1] or Configs.Title or "Tab!"
		local TIcon = Configs[2] or Configs.Icon or ""
		
		TIcon = redzlib:GetIcon(TIcon)
		if not TIcon or not TIcon:find("rbxassetid://") or TIcon:gsub("rbxassetid://", ""):len() < 6 then
			TIcon = false
		end
		
		local TabSelect = Make("Button", MainScroll, {
			Size = UDim2.new(1, 0, 0, 24)
		})
		Make("Corner", TabSelect)
		
		local LabelTitle = InsertTheme(Create("TextLabel", TabSelect, {
			Size = UDim2.new(1, TIcon and -25 or -15, 1),
			Position = UDim2.fromOffset(TIcon and 25 or 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = TName,
			TextColor3 = Theme["Color Text"],
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = (FirstTab and 0.3) or 0,
			TextTruncate = "AtEnd"
		}), "Text")
		
		local LabelIcon = InsertTheme(Create("ImageLabel", TabSelect, {
			Position = UDim2.new(0, 8, 0.5),
			Size = UDim2.new(0, 13, 0, 13),
			AnchorPoint = Vector2.new(0, 0.5),
			Image = TIcon or "",
			BackgroundTransparency = 1,
			ImageTransparency = (FirstTab and 0.3) or 0
		}), "Text")
		
		local Selected = InsertTheme(Create("Frame", TabSelect, {
			Size = FirstTab and UDim2.new(0, 4, 0, 4) or UDim2.new(0, 4, 0, 13),
			Position = UDim2.new(0, 1, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme["Color Theme"],
			BackgroundTransparency = FirstTab and 1 or 0
		}), "Theme")
		Make("Corner", Selected, UDim.new(0.5, 0))
		
		local Container = InsertTheme(Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 1),
			AnchorPoint = Vector2.new(0, 1),
			ScrollBarThickness = 1.5,
			BackgroundTransparency = 1,
			ScrollBarImageTransparency = 0.2,
			ScrollBarImageColor3 = Theme["Color Theme"],
			AutomaticCanvasSize = "Y",
			ScrollingDirection = "Y",
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			Name = ("Container %i [ %s ]"):format(#ContainerList + 1, TName)
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10)
			}), 
			Create("UIListLayout", {
				Padding = UDim.new(0, 5)
			})
		}), "ScrollBar")
		
		table.insert(ContainerList, Container)
		
		if not FirstTab then 
			Container.Parent = Containers 
		end
		
		local function Tabs()
			if Container.Parent then return end
			for _,Frame in pairs(ContainerList) do
				if Frame:IsA("ScrollingFrame") and Frame ~= Container then
					Frame.Parent = nil
				end
			end
			Container.Parent = Containers
			Container.Size = UDim2.new(1, 0, 1, 150)
			
			for k,v in pairs(redzlib.Tabs) do
				if v.Cont ~= Container then
					v.func:Disable()
				end
			end
			
			CreateTween({Container, "Size", UDim2.new(1, 0, 1, 0), 0.3})
			CreateTween({LabelTitle, "TextTransparency", 0, 0.35})
			CreateTween({LabelIcon, "ImageTransparency", 0, 0.35})
			CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 13), 0.35})
			CreateTween({Selected, "BackgroundTransparency", 0, 0.35})
		end
		
		TabSelect.Activated:Connect(Tabs)
		
		FirstTab = true
		local Tab = {}
		table.insert(redzlib.Tabs, {TabInfo = {Name = TName, Icon = TIcon}, func = Tab, Cont = Container})
		Tab.Cont = Container
		
		function Tab:Disable()
			Container.Parent = nil
			CreateTween({LabelTitle, "TextTransparency", 0.3, 0.35})
			CreateTween({LabelIcon, "ImageTransparency", 0.3, 0.35})
			CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 4), 0.35})
			CreateTween({Selected, "BackgroundTransparency", 1, 0.35})
		end
		
		function Tab:Enable()
			Tabs()
		end
		
		function Tab:Visible(Bool)
			Funcs:ToggleVisible(TabSelect, Bool)
		end
		
		function Tab:Destroy() 
			TabSelect:Destroy() 
			Container:Destroy() 
		end
		
		function Tab:AddLabel(Configs)
			local LName = type(Configs) == "string" and Configs or Configs[1] or Configs.Name or Configs.Title or "Label"
			
			local LabelFrame = Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 25),
				AutomaticSize = "Y",
				BackgroundTransparency = 1,
				Name = "Option"
			})
			
			local LabelText = InsertTheme(Create("TextLabel", LabelFrame, {
				Size = UDim2.new(1, -20, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium,
				Text = LName,
				TextColor3 = Theme["Color Text"],
				TextSize = 10,
				TextXAlignment = "Left",
				TextYAlignment = "Center"
			}), "Text")
			
			local Label = {}
			function Label:Visible(Bool) 
				Funcs:ToggleVisible(LabelFrame, Bool) 
			end
			function Label:Destroy() 
				LabelFrame:Destroy() 
			end
			function Label:Set(NewText)
				if type(NewText) == "string" then
					LabelText.Text = GetStr(NewText)
				end
			end
			return Label
		end
		
		return Tab
	end
	
	CloseButton.Activated:Connect(function() Window:CloseBtn() end)
	MinimizeButton.Activated:Connect(function() Window:MinimizeBtn() end)
	
	-- Add example Home tab with real-time info
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	-- Tab Home
	local HomeTab = Window:MakeTab({"Home", "home"})

	-- Labels
	local fpsLabel = HomeTab:AddLabel("FPS: ...")
	local timeLabel = HomeTab:AddLabel("Time Plays: 00:00")
	local friendsLabel = HomeTab:AddLabel("Friends online: ... / offline: ...")

	-- FPS update
	local accumulator, frames, fps = 0, 0, 0
	RunService.RenderStepped:Connect(function(dt)
		frames = frames + 1
		accumulator = accumulator + dt
		if accumulator >= 0.5 then
			fps = math.floor(frames / accumulator + 0.5)
			frames, accumulator = 0, 0
			pcall(function() fpsLabel:Set("FPS: "..tostring(fps)) end)
		end
	end)

	-- Session time update
	local startTime = tick()
	RunService.Heartbeat:Connect(function()
		local elapsed = math.floor(tick() - startTime)
		local m = math.floor(elapsed / 60)
		local s = elapsed % 60
		pcall(function() timeLabel:Set(string.format("Time Plays: %02d:%02d", m, s)) end)
	end)

	-- Friends update (best-effort)
	local function updateFriends()
		local onlineCount, totalCount = 0, 0
		local success, friends = pcall(function()
			if Players and Players.GetFriendsAsync then
				local t = {}
				local pages = Players:GetFriendsAsync(LocalPlayer.UserId)
				if pages and pages.GetCurrentPage then
					local currentPage = pages:GetCurrentPage()
					if type(currentPage) == "table" then
						for _,v in pairs(currentPage) do 
							table.insert(t, v) 
						end
					end
				end
				return t
			end
			return nil
		end)
		
		if success and friends and type(friends) == "table" and #friends > 0 then
			totalCount = #friends
			for _,f in ipairs(friends) do
				if f.IsOnline then onlineCount = onlineCount + 1 end
			end
		else
			totalCount = #Players:GetPlayers()
			onlineCount = #Players:GetPlayers()
		end
		
		pcall(function() 
			friendsLabel:Set("Friends online: "..onlineCount.." / offline: "..(totalCount - onlineCount)) 
		end)
	end

	updateFriends()
	spawn(function()
		while true do
			wait(30)
			updateFriends()
		end
	end)
	
	return Window
end

return redzlib
