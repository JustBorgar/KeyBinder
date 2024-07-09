--!strict

--[[

████████████████████████████████████████████████████████████

██  ██ ████ ██   ██ ████   ██ ████  ██ █████  ████  ███
██ ██  ██    ██ ██  ██  ██    ██ ██ ██ ██  ██ ██   ██ ██
████   ██     ██    ██  ██ ██ ██ ██ ██ ██  ██ ██   ██ ██
████   ████   ██    █████  ██ ██ ██ ██ ██  ██ ████ ████
██ ██  ██     ██    ██  ██ ██ ██ ██ ██ ██  ██ ██   ██ █
██  ██ ████   ███   █████  ██ ██  ███  █████  ████ ██ ██

████████████████████████████████████████████████████████████

Effortless action binding, auto-positioning, rebinds & multi-method support.

----- About -----

KeyBinder is a ContextActionService wrapper that provides automatic button positioning much like
CAU (which this is based on), while being strict typed, offering higher legibility, as well
as support for multiple functions, signals for them, and rebinding.

A while ago I released a forked version of PseudoPerson's CAU module bundled with SNM (my open source
platformer) to add rebinding support to the game, but a while later while trying to clean up my own
messy fork I figured it'd be better to just do the thing from scratch, squash a bunch of bugs, and
that's pretty much what this is.

Keep in mind I made this like 6 months before open sourcing it, so there might be inconsistencies with
the type checking and/or documentation as I just did a last minute cleanup, that and I haven't tested
it a whole lot either, nonetheless I hope it's useful, and no offense intended to the creator of CAU,
i've used their module for years and I only made this for the added functionality I needed.

----- How to Use -----

You use this module much like you'd use the regular ContextActionService, with only a
few noticeable differences, below is an example showcasing some of the key new
features (it's 3:53am as of writing I can't bother documenting this properly sorry):

--- Example ---

--This creates a button called pressed, and links it to the "Pressed" function, which prints when the button is initially pressed
local function Pressed(ActionName, InputState, _)
	if InputState == Enum.UserInputState.Begin then
		print("Key pressed")
	end
end
KeyBinder:BindAction("Pressed", Pressed, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)

--This adds a new function to the previous button, which prints when the button is released
local function Released(ActionName, InputState, _)
	if InputState == Enum.UserInputState.End then
		print("Key released")
	end
end
KeyBinder:BindAction("Pressed", Released, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)

--This creates a "Rebind" button, which will switch the desktop's key between F and R while maintaining it's methods (make sure you pass new or you'll override them!)
local Rebinded = false
local function Rebind(ActionName, InputState, _)
	if InputState == Enum.UserInputState.Begin then
		if not Rebinded then
			--Careful, passing a new function when rebinding will override the previous ones, pass nil instead
			KeyBinder:RebindAction("Pressed", nil, true, Enum.KeyCode.R, Enum.KeyCode.ButtonB)
			Rebinded = true
		else
			KeyBinder:RebindAction("Pressed", nil, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
			Rebinded = false
		end
		print("Rebinded Key")
	end
end
KeyBinder:BindAction("Rebind", Rebind, true, Enum.KeyCode.G, Enum.KeyCode.ButtonY)

----- Attribution -----

KeyBinder makes use of the following external resources:
_FastSignal, by lucasmz.
_ContextActionUtility, by PseudoPerson (what this module is built based on).

All rights reserved to their respective owners.

----- License -----

MIT NON-AI License

Copyright (c) 2024, JustBorgar & Caffeine Overflow

Permission is hereby granted, free of charge, to any person obtaining a copy of the software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions.

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

In addition, the following restrictions apply:

1. The Software and any modifications made to it may not be used for the purpose of training or improving machine learning algorithms,
including but not limited to artificial intelligence, natural language processing, or data mining. This condition applies to any derivatives,
modifications, or updates based on the Software code. Any usage of the Software in an AI-training dataset is considered a breach of this License.

2. The Software may not be included in any dataset used for training or improving machine learning algorithms,
including but not limited to artificial intelligence, natural language processing, or data mining.

3. Any person or organization found to be in violation of these restrictions will be subject to legal action and may be held liable
for any damages resulting from such use.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

----- Services -----

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

----- Variables -----

local Player = Players.LocalPlayer
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")

local Signal = require(script.FastSignal)

local ButtonSize = UDim2.new(0.8, 0, 0.8, 0)
local ButtonPositions = {
	[1] = UDim2.new(-0.42, 0, 0.72, 0);
	[2] = UDim2.new(-0.17, 0, -0.17, 0);
	[3] = UDim2.new(0.72, 0, -0.42, 0);
	[4] = UDim2.new(-1.11, 0, -0.04, 0);
	[5] = UDim2.new(-0.86, 0, -0.86, 0);
	[6] = UDim2.new(-0.04, 0, -1.11, 0);
}
local TakenPositions: {[number]: boolean?} = {}
local BindedData: {[string]: {
	Functions: any,
	DesktopKey: Enum.KeyCode,
	ConsoleKey: Enum.KeyCode,
	CreateTouchButton: boolean,
	ButtonPosition: number?
}} = {}


--Will bug out if called too soon
if not game:IsLoaded() then
	game.Loaded:Wait()	
end
wait(0.1)

----- Module -----

local KeyBinder = {}

--Signal Params (Hack, yes ik it displays it wrong, it's better than nothing)
type ActionUpdatedParams = (self: {any}, ActionName: string, DesktopKey: Enum.KeyCode, ConsoleKey: Enum.KeyCode, ...any) -> RBXScriptConnection
type ActionBindedParams = (self: {any}, ActionName: string) -> RBXScriptConnection
type ActionUpdatedParamsFire = (self: {any}, ActionName: string, DesktopKey: Enum.KeyCode, ConsoleKey: Enum.KeyCode, ...any) -> ()
type ActionBindedParamsFire = (self: {any}, ActionName: string, DesktopKey: Enum.KeyCode, ConsoleKey: Enum.KeyCode, ...any) -> ()

--Class Type
type KeyBinderType = {
	KeepPosition: boolean,
	MakeConsistent: boolean,
	AdditiveActions: boolean,
	ActionUpdated: {Connect: ActionUpdatedParams, Once: ActionUpdatedParams , Wait: ActionUpdatedParams, Fire: ActionUpdatedParamsFire} & Signal.Class,
	ActionBinded: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class,
	ActionUnbinded: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class,
	FunctionAdded: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class,
	FunctionRemoved: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class,
	BindAction: (self: any?, ActionName: string, FuncToBind: any, CreateTouchButton: boolean, DesktopKey: Enum.KeyCode, ConsoleKey: Enum.KeyCode, ButtonPos: number?) -> (),
	BindFuncToAction: (self: any?, ActionName: string, FuncToBind: any?) -> (),
	RebindAction: (self: any?, ActionName: string, FuncToBind: any?, CreateTouchButton: boolean?, DesktopKey: Enum.KeyCode?, ConsoleKey: Enum.KeyCode?) -> (),
	UnbindAction: (self: any?, ActionName: string) -> (),
	UnbindFuncFromAction: (self: any?, ActionName: string, FuncToUnbind: any) -> (),
	SetTitle: (self: any?, ActionName: string, Title: string) -> (),
	SetImage: (self: any?, ActionName: string, Image: string) -> (),
	SetPosition: (self: any?, ActionName: string, Position: UDim2) -> (),
	SetDescription: (self: any?, ActionName: string, Description: string) -> (),
	GetButton: (self: any?, ActionName: string) -> ImageButton?
}

--Signals
KeyBinder.ActionUpdated = Signal.new() :: {Connect: ActionUpdatedParams, Once: ActionUpdatedParams , Wait: ActionUpdatedParams, Fire: ActionUpdatedParamsFire} & Signal.Class
KeyBinder.ActionBinded = Signal.new() :: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class
KeyBinder.ActionUnbinded = Signal.new() :: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class
KeyBinder.FunctionAdded = Signal.new() :: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class
KeyBinder.FunctionRemoved = Signal.new() :: {Connect: ActionBindedParams, Once: ActionBindedParams , Wait: ActionBindedParams, Fire: ActionBindedParamsFire} & Signal.Class

--Settings
KeyBinder.KeepPosition = true --Maintains button position when rebinded
KeyBinder.MakeConsistent = true --Makes buttons have the same appearence as the jump button
KeyBinder.AdditiveActions = true --Calling BindAction on an already binded action will automatically call AddAction.

--- Bind Action ---

--[[
Binds a new action, or adds to a previous one if AdditiveActions is enabled.
--]]

function KeyBinder:BindAction(ActionName: string, FuncToBind: any, CreateTouchButton: boolean, DesktopKey: Enum.KeyCode, ConsoleKey: Enum.KeyCode, ButtonPos: number?): ()

	--Bind Action
	local ActionData = BindedData[ActionName]
	if not ActionData then --Limitation: ActionNames can't be repeated
		
		--Check if it's a single function or multiple ones
		if typeof(FuncToBind) == "table" then
			FuncToBind = FuncToBind
		else
			FuncToBind = {FuncToBind}
		end
		
		--Store action & binding data
		BindedData[ActionName] = {
			Functions = FuncToBind,
			DesktopKey = DesktopKey,
			ConsoleKey = ConsoleKey,
			CreateTouchButton = CreateTouchButton,
			ButtonPosition = ButtonPos
		}
		ActionData = BindedData[ActionName]
		assert(ActionData) --Shut up type checker, it isn't nil
		
		--Get Next Pos
		local function GetPos(): UDim2
			
			--If position is already taken, reuse it
			local TakenPos = ActionData.ButtonPosition
			if TakenPos then
				return ButtonPositions[TakenPos] --Returns already taken position
			end

			--Looks for a free slot and takes it
			for Index, Position in pairs(ButtonPositions) do
				if not TakenPositions[Index] then
					TakenPositions[Index] = true --Sets position as taken
					ActionData.ButtonPosition = Index --Stores index of position
					return Position --Returns first open position
				end
			end
			
			warn("No position for button found, returned 0")
			return UDim2.new(0, 0, 0, 0) --If no position is available returns 0 with a warn (just add more positions if you need more, I ain't coming up with a math formula for this thing)
		end
		
		--Update Button
		local function UpdateButton(Button: ImageButton, State: Enum.UserInputState): ()
			if Button and KeyBinder.MakeConsistent then --Makes button's appearence consistent with jump
				
				--JumpButton
				local TouchGui = PlayerGui:WaitForChild("TouchGui")
				local TouchControlFrame = TouchGui:WaitForChild("TouchControlFrame")
				local JumpButton = TouchControlFrame:WaitForChild("JumpButton", math.huge) --Silences warn I think
				Button.Parent = JumpButton
				Button.Size = ButtonSize
				Button.AnchorPoint = Vector2.new(0.5, 0.5)
				
				--Image
				if State and State ~= Enum.UserInputState.Begin then
					Button.Image = "rbxassetid://6256840888"
				else
					Button.Image = "rbxassetid://14112658774"
				end
				
				--Title
				local Title = Button:FindFirstChild("ActionTitle") :: TextLabel
				if Title then
					Title.TextTransparency = 0.4
					Title.TextStrokeTransparency = 1
				end
				Button.Name = Title.Text
				
				--Color
				if State and State ~= Enum.UserInputState.Begin then
					Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					Title.TextColor3 = Color3.fromRGB(40, 40, 40)
				end
				
				--Fix jump button getting stuck
				local function FixDefaultJumpButton()
					local UICorner = JumpButton:FindFirstChild("UICorner") :: UICorner
					if UICorner then
						UICorner.CornerRadius = UDim.new(0.5, 0)
					end
				end
				FixDefaultJumpButton()
			end
		end
		
		--Bind Action
		local function InternalBind(Name: string, State: Enum.UserInputState, Obj: InputObject): Enum.ContextActionResult
			if Name == ActionName then
				local function TriggerActions(...)
					for _, Func in pairs(ActionData.Functions) do
						coroutine.wrap(Func)(...) --If the function call yields even a little bit the button will stay "pressed", which visually looks really ugly, so we run the functions in a coroutine (which afaik gets garbage collected once execution ends).
					end
				end
				TriggerActions(Name, State, Obj)
				if not ActionData[ActionName] then --This silences the annoying "CAS" warn
					task.delay(0.01, function()
						if not ActionData[ActionName] then
							UpdateButton(ContextActionService:GetButton(ActionName), State) --Update Button Appearence	
						end		
					end)
				end
			end
			return Enum.ContextActionResult.Pass; --Why on earth is this off by default
		end
		ContextActionService:BindAction(ActionName, InternalBind, CreateTouchButton, DesktopKey, ConsoleKey)
		
		--Default Button
		ContextActionService:SetTitle(ActionName, ActionName)
		ContextActionService:SetPosition(ActionName, GetPos())
		UpdateButton(ContextActionService:GetButton(ActionName), Enum.UserInputState.End)
		
		--Fire Signal
		KeyBinder.ActionBinded:Fire(ActionName)
	else
		
		--If Adding actions is enabled and the functions are new, add them on top of the current ones
		if KeyBinder.AdditiveActions and (FuncToBind ~= ActionData.Functions) and ({FuncToBind} ~= ActionData.Functions) then
			KeyBinder:BindFuncToAction(ActionName, FuncToBind)
		else --The action is repeated, don't bind
			warn(ActionName.." is already binded. Make sure all your ActionNames are unique.")
		end
	end
end

--- Bind Function To Action ---

--[[
Adds a function to a previously binded action, make sure said action exists before calling.
--]]

function KeyBinder:BindFuncToAction(ActionName: string, FuncToBind: any?): ()
	
	--Add Action
	local ActionData = BindedData[ActionName]
	if ActionData then --Limitation: ActionNames can't be repeated
		
		--Check if it's a single function or multiple ones
		if typeof(FuncToBind) ~= "table" then
			FuncToBind = {FuncToBind}
		end
		
		--Add new actions
		if FuncToBind then
			for _, Func in pairs(FuncToBind) do
				if not table.find(ActionData.Functions, Func) then --Duplicate prevention
					table.insert(ActionData.Functions, Func)
				else
					warn("Duplicate function passed to action, make sure all your functions are unique.")
				end
			end
			
			--Fire Signal
			KeyBinder.FunctionAdded:Fire(ActionName)
		end
	else
		warn("No action named "..ActionName.." exists, you can't add to something that doesn't exist can you?")
	end
end

--- Rebind Action ---

--[[
Unbinds a previously binded action and binds it again with the new passed parameters. Passing null
will maintain the previous one.

To add additional functions use BindFuncToAction, this method overrides.
--]]

function KeyBinder:RebindAction(ActionName: string, FuncToBind: any?, CreateTouchButton: boolean?, DesktopKey: Enum.KeyCode?, ConsoleKey: Enum.KeyCode?)
	local Binded = BindedData[ActionName]
	if Binded then
		
		--Remove the existing binding
		UnbindAction(ActionName, true) --Unbinds action without firing the unbinded signal to bind it again in a sec
		
		--Check if it's a single function or multiple ones
		if FuncToBind then
			if typeof(FuncToBind) == "table" then
				FuncToBind = FuncToBind
			else
				FuncToBind = {FuncToBind}
			end
		end
		
		--Bind the action again with updated parameters
		FuncToBind = FuncToBind or Binded.Functions
		CreateTouchButton = CreateTouchButton or Binded.CreateTouchButton; assert(CreateTouchButton and typeof(CreateTouchButton) == "boolean") --Man I hate the type checker so much
		DesktopKey = DesktopKey or Binded.DesktopKey; assert(DesktopKey and DesktopKey.EnumType == Enum.KeyCode)
		ConsoleKey = ConsoleKey or Binded.ConsoleKey; assert(ConsoleKey and ConsoleKey.EnumType == Enum.KeyCode)
		KeyBinder:BindAction(ActionName, FuncToBind, CreateTouchButton, DesktopKey, ConsoleKey, KeyBinder.KeepPosition and Binded.ButtonPosition or nil)
	
		--Fire Signal
		KeyBinder.ActionUpdated:Fire(ActionName, DesktopKey, ConsoleKey)
	else
		warn(ActionName.." doesn't exist, make sure you create your actions before trying to rebind them")
	end
end

--- Unbind Action ---

--[[
Unbinds a previously binded action. Not to be confused with UnbindFuncFromAction, who unbinds
a specific set of functions from an action.
--]]

--Interface (so you can't pass the Skip thing outside the module by mistake)
function KeyBinder:UnbindAction(ActionName: string): ()
	UnbindAction(ActionName)
end

--Actual thing
function UnbindAction(ActionName: string, _SkipSignal: boolean?): ()
	
	--Remove Action
	local ActionData = BindedData[ActionName]
	if ActionData then

		--Unbinds action
		ContextActionService:UnbindAction(ActionName)
		
		--Frees Position
		if ActionData.ButtonPosition then
			TakenPositions[ActionData.ButtonPosition] = false
		end

		--Removes action
		local NewBindedData = {}
		for Key, Value in pairs(BindedData) do
			if Key ~= ActionName then
				NewBindedData[Key] = Value
			end
		end
		BindedData = NewBindedData

		--Fire Signal
		if not _SkipSignal then
			KeyBinder.ActionUnbinded:Fire(ActionName)
		end
	else
		warn(ActionName.." doesn't exist.")
	end
end

--- Unbind Function From Action ---

--[[
Unbinds the passed function/functions from a previously binded action.
--]]

function KeyBinder:UnbindFuncFromAction(ActionName: string, FuncToUnbind: any)

	--Add Action
	local ActionData = BindedData[ActionName]
	if ActionData then
		
		--Check if it's a single function or multiple ones
		if typeof(FuncToUnbind) ~= "table" then
			FuncToUnbind = {FuncToUnbind}
		end
		
		--Substract action/s
		for _, Func in pairs(FuncToUnbind) do
			local Binded = table.find(ActionData.Functions, Func)
			if Binded then
				table.remove(ActionData.Functions, Binded)
			else
				warn("You can't unbind a function that isn't bound to the passed action.")
			end
		end

		--Fire Signal
		KeyBinder.FunctionRemoved:Fire(ActionName)
	else
		warn("No action named "..ActionName.." exists, you can't substract to something that doesn't exist can you?")
	end
end

--- Generic Methods ---

--[[
These do the exact same thing they do in CAS.

Customization methods would be redundant as you already have access to the button with GetButton.
--]]

--Set Title
function KeyBinder:SetTitle(ActionName: string, Title: string): ()
	local ActionData = BindedData[ActionName]
	if ActionData then
		ContextActionService:SetTitle(ActionName, Title)
	else
		warn(ActionName.." doesn't exist, make sure it does before setting it's title.")
	end
end

--Set Image
function KeyBinder:SetImage(ActionName: string, Image: string): ()
	local ActionData = BindedData[ActionName]
	if ActionData then
		ContextActionService:SetImage(ActionName, Image)
	else
		warn(ActionName.." doesn't exist, make sure it does before setting it's image.")
	end
end

--Set Position
function KeyBinder:SetPosition(ActionName: string, Position: UDim2): ()
	local ActionData = BindedData[ActionName]
	if ActionData then
		ContextActionService:SetPosition(ActionName, Position)
	else
		warn(ActionName.." doesn't exist, make sure it does before setting it's position.")
	end
end

--Set Description
function KeyBinder:SetDescription(ActionName: string, Description: string): ()
	local ActionData = BindedData[ActionName]
	if ActionData then
		ContextActionService:SetDescription(ActionName, Description)
	else
		warn(ActionName.." doesn't exist, make sure it does before setting it's description.")
	end
end

--Get Button
function KeyBinder:GetButton(ActionName: string) --: ImageButton?
	local ActionData = BindedData[ActionName]
	if ActionData then
		return ContextActionService:GetButton(ActionName)
	else
		warn(ActionName.." doesn't exist, make sure it does before trying to get it's button.")
	end
end

return KeyBinder :: KeyBinderType