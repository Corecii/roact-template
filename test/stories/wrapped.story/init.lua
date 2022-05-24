--[[
	Clicked count should go up when clicked, and render count should not.
]]
return function(target)
	local Roact = require(script.Parent.Parent.Roact)
	local RoactTemplate = require(script.Parent.Parent.lib)

	local ExampleTemplate = RoactTemplate.fromInstance(Roact, script.Parent.assets.wrapped)

	local Counter = Roact.Component:extend("Counter")

	function Counter:init()
		self:setState({
			count = 0,
		})
	end

	function Counter:render()
		return Roact.createElement(self.props.template, {
			CountingButton = {
				Text = "Clicked: " .. self.state.count,
				[Roact.Event.Activated] = function()
					self:setState({
						count = self.state.count + 1,
					})
				end,
			},
		})
	end

	local renderCalls = 0

	local function Example()
		renderCalls += 1
		-- If components are working properly, "render 1" won't increase since
		-- the outer object isn't being re-rendered, only the button is!

		return Roact.createElement(ExampleTemplate, {
			TitleLabel = { Text = "A Counting Button with Internal State (render " .. renderCalls .. ")" },
			CountingButton = RoactTemplate.wrapped(Counter),
		})
	end

	local tree = Roact.mount(Roact.createElement(Example), target)

	return function()
		Roact.unmount(tree)
	end
end
