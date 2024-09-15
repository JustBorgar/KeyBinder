--!strict

----- Variables -----

local Code = workspace:WaitForChild("Code")
local Shared = Code.Shared
local Goodies = Shared.Goodies

local KeyBinder = require(Goodies.KeyBinder)

----- Code -----

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
