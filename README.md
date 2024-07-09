# [KeyBinder](https://github.com/JustBorgar/KeyBinder)

Effortless action binding, auto-positioning, rebinds & multi-method support.

## Description ##

KeyBinder is a ContextActionService wrapper that provides automatic button positioning much like
PseudoPerson's ContextActionUtility (which this is based on), while being strict typed, offering higher legibility, as well
as support for multiple functions, signals for them, and rebinding.


### Why reinvent the wheel if it already works? ###

A while ago I released a forked version of CAU bundled with [SNM](https://devforum.roblox.com/t/sip-n-munch-an-open-source-platformer/2304088)
to add rebinding support to the game in hopes of adding a rebinding menu to the game later on (I never did), but a while later while trying
to clean up my own messy fork I figured it'd be much easier to just do the thing from scratch, squash a bunch of bugs, and that's pretty
much what this is.

Keep in mind I made this like 6 months before uploading it to github, so there might be inconsistencies with the type checking
and/or documentation as I just did a last minute cleanup, that and I haven't tested it a whole lot either, nonetheless I hope
it's useful, and no offense intended to the creator of CAU, i've used their module for years and I only made this for the
added functionality I needed, if their module works for you i'd recommend you keep using it.

## How to Use ##

You use this much like you'd use the regular [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService),
you call BindAction, it'll position the buttons for you automatically and it'll make them consistent with the jump button for you (you can set
KeyBinder.MakeConsistent to false if you don't want the later). KeyBinder.KeepPosition will keep the position of your button when you rebind
it, and AdditiveActions allows repeated calls of BindAction to be additive by calling BindFuncToAction instead.

Outside of that BindFuncToAction will add a new function to a previously binded Action, it's unbind function will remove it, and if you so
desire you can pass a table with multiple functions in BindAction instead of a single one and KeyBinder will take care of it.

Much like CAU, KeyBinder has a cap of 7 slots by default, if you want more, go to the module's table and add the desired additional positions.

And that's about as much of the functionality as I remember, there's no proper documentation because I made this thing 6 months ago
and I can't bother, but that should of explained most of it.

## Documentation ##

I'll add this at some point, probably.

### Example ###

Here's an example of usage:
```luau
--This creates a button called pressed, and links it to the "Pressed" function, which prints when the button is initially pressed
local function Pressed(ActionName, InputState, _)
	if InputState == Enum.UserInputState.Begin then
		print("Key pressed")
	end
end
KeyBinder:BindAction("Pressed", Pressed, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)

--This adds a new function to the previous button (with AdditiveActions enabled), which prints when the button is released
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
```

## Attribution ##

KeyBinder makes use of the following external resources:
* FastSignal, by lucasmz (and the README, which I copied a litte bit).
* ContextActionUtility, by PseudoPerson (what this module is built based on).

All rights reserved to their respective owners.

## Installation ##

### From GitHub ###

You can get a copy of KeyBinder right here on [GitGub](https://github.com/JustBorgar/KeyBinder)

### From Devforum ###

I haven't made a post for this yet, but I likely will at some point.

<a href="https://github.com/JustBorgar/KeyBinder/releases">
    <img alt="Releases" src="https://img.shields.io/github/v/release/JustBorgar/KeyBinder">
    </img>
</a>

<a href="https://github.com/JustBorgar/KeyBinder">
    <img alt="" src="https://img.shields.io/github/downloads/JustBorgar/KeyBinder/total">
    </img>
</a>
