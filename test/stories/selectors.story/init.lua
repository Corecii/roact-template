return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	-- Current version of Rojo may not sync in attributes
	script.Parent.assets.selectors:FindFirstChild("Item", true):SetAttribute("Attribute", "test")

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.selectors)

	local function identifier(name)
		return {
			[Roact.Children] = {
				[name] = Roact.createElement("Folder"),
			},
		}
	end

	local function Example()
		return Roact.createElement(ExampleTemplate, {
			TitleLabel = identifier("nameFast"),
			[RoactTemplate.Select.class("TextLabel")] = identifier("class"),
			[RoactTemplate.Select.isA("TextLabel")] = identifier("isA"),
			[RoactTemplate.Select.classPattern("^Text")] = identifier("classPattern"),
			[RoactTemplate.Select.name("Item")] = identifier("name"),
			[RoactTemplate.Select.namePattern("^Button")] = identifier("namePattern"),
			[RoactTemplate.Select.attribute("Attribute", "test")] = identifier("attribute"),
			[RoactTemplate.Select.prop("Text", "ExamplePropSelector")] = identifier("prop"),
			[RoactTemplate.Select.propPattern("Text", "^ExamplePropPatternSelector")] = identifier("propPattern"),
			[RoactTemplate.Select.tag("Example")] = identifier("tag"),
			[RoactTemplate.Select.every(
				RoactTemplate.Select.tag("EveryExample1"),
				RoactTemplate.Select.tag("EveryExample2")
			)] = identifier("every"),
			[RoactTemplate.Select.some(
				RoactTemplate.Select.tag("SomeExample1"),
				RoactTemplate.Select.tag("SomeExample2")
			)] = identifier("some"),
			[RoactTemplate.Select.no(RoactTemplate.Select.tag("NoExample"))] = identifier("no"),
		})
	end

	local tree = Roact.mount(Roact.createElement(Example), target)

	return function()
		Roact.unmount(tree)
	end
end
