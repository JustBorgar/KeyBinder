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

# How to Use #

You use this much like you'd use the regular [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService),
you call BindAction, it'll position the buttons for you automatically and it'll make them consistent with the jump button for you (you can set
KeyBinder.MakeConsistent to false if you don't want the later). KeyBinder.KeepPosition will keep the position of your button when you rebind
it, and AdditiveActions allows repeated calls of BindAction to be additive by calling BindFuncToAction instead.

Outside of that BindFuncToAction will add a new function to a previously binded Action, it's unbind function will remove it, and if you so
desire you can pass a table with multiple functions in BindAction instead of a single one and KeyBinder will take care of it.

Much like CAU, KeyBinder has a cap of 7 slots by default, if you want more, go to the module's table and add the desired additional positions.

And that's about as much of the functionality as I remember, there's no proper documentation because I made this thing 6 months ago
and I can't bother, but that should of explained most of it.
