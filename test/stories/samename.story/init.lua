--[[
	This should delete all three "Item" children, since all three are placed
	under an "Item" fragment.
]]
return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.simple)

	local function Example()
		return Roact.createElement(ExampleTemplate, {
			Content = {
				[Roact.Children] = {
					Item = RoactTemplate.None,
				},
			},
		})
	end

	local tree = Roact.mount(Roact.createElement(Example), target)

	return function()
		Roact.unmount(tree)
	end
end
