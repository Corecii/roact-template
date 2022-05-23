return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.simple)

	local function Example()
		return Roact.createElement(ExampleTemplate, {
			TitleLabel = {
				Text = "Example Title Set With Changes",
				[Roact.Children] = {
					Gradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200)),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Thickness = 2,
						Color = Color3.fromRGB(200, 200, 200),
					}),
				},
			},
			ItemNameLabel = { Text = "Some Item" },
		})
	end

	local tree = Roact.mount(Roact.createElement(Example), target)

	return function()
		Roact.unmount(tree)
	end
end
