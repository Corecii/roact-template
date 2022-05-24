--[[
	An instance-for-instance recreation of the template instance should appear.
]]
return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.simple)

	local tree = Roact.mount(Roact.createElement(ExampleTemplate), target)

	return function()
		Roact.unmount(tree)
	end
end
