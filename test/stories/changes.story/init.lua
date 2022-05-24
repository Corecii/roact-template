return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.simple)

	local function Example()
		return Roact.createElement(ExampleTemplate, {
			[RoactTemplate.Root] = {
				BackgroundTransparency = 0.5,
				BackgroundColor3 = Color3.fromRGB(0, 255, 255),
			},
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
			Item = function(instance)
				return {
					BackgroundColor3 = Color3.new(
						instance.BackgroundColor3.R * 0.5,
						instance.BackgroundColor3.G * 0.8,
						instance.BackgroundColor3.B * 0.8
					),
				}
			end,
		})
	end

	local tree = Roact.mount(Roact.createElement(Example), target)

	return function()
		Roact.unmount(tree)
	end
end
