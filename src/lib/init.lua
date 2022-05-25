--!strict
local HttpService = game:GetService("HttpService")

local ApiDumpStatic = require(script.Parent.ApiDumpStatic)

local DISALLOWED_PROPS_LIST = { "Parent", "Transparency", "Name", "ClassName" }

local DISALLOWED_PROPS = {}
for _, value in ipairs(DISALLOWED_PROPS_LIST) do
	DISALLOWED_PROPS[value] = true
end

type Roact = {
	createElement: (...any) -> ...any,
	createFragment: (...any) -> ...any,
	Children: any,
}

type Element = any
type Component = any

export type ChangesCallback = (instance: Instance) -> { [any]: any }
export type ChangesTable = { [any]: any }
export type Changes = ChangesCallback | ChangesTable

export type SelectorCallback = (instance: Instance) -> boolean
export type Selector = string | SelectorCallback | Root

export type TemplateItemElement = {
	type: "element",
	singleFragment: boolean?,
	isRoot: boolean?,
	class: string,
	instance: Instance,
	props: { [string]: any },
	children: { [string]: TemplateItem },
}

export type TemplateItemFragment = {
	type: "fragment",
	children: { [string]: TemplateItem },
}

export type TemplateItem = TemplateItemElement | TemplateItemFragment

--[=[
	@class RoactTemplate

	A module to create a Roact tree at runtime given an Instance, with the
	ability to change descendants using selectors.

	:::info

	The items marked **"Private"** are *not* private, they're just intentionally
	hidden by default. If you have a use for them, feel free to use them!

	:::
]=]
local RoactTemplate = {}

--[=[
	@prop Select Select
	@within RoactTemplate

	Selectors to use to change descendent elements.

	These selectors **will be slower** than name-based selection. Name selection
	is preferred since we can do fast look-ups to check if any child has a given
	name.
]=]
RoactTemplate.Select = require(script.Select)

--[=[
	@type Selector string | Root | (instance: Instance) -> boolean
	@within RoactTemplate

	Used to determine whether a change should apply to an instance. You can
	write your own or use the ones under `Select`.

	Name-based selection is preferred over using Selector callbacks because
	name-based selection is faster.
]=]

--[=[
	@type Changes ChangesTable | ChangesCallback
	@within RoactTemplate
]=]

--[=[
	@type ChangesTable { [any]: any }
	@within RoactTemplate

	Represents properties to overwrite on an element.

	* You can use `RoactTemplate.None` to set a property to nil.
	* You can use `[Roact.Children] = {}` to add children to an element.
	* If you want to remove a child you need to set it to `RoactTemplate.None`.
	* Children with the same name are placed in a fragment with that name.
	  You can remove them all at once -- or overwrite them all at once -- by
	  setting the child to None or some element.
]=]

--[=[
	@type ChangesCallback (templateInstance: Instance) -> ChangesTable
	@within RoactTemplate

	A function that is called on a template instance and returns changes. This
	allows you to make changes dependent upon the instance's existing
	properties, attributes, etc. For example, you can use this to darken the
	color that was set in the studio editor.

	For example:
	```lua
	local ButtonTemplate = RoactTemplate.fromInstance(SomeButtonInstance)

	local function Button()
	    return Roact.createElement(ButtonTemplate, {
	        Button = function(templateInstance)
	            if mouseIsOverInstance() then
	                -- Darken the button if the mouse is over it!
	                return {
	                    BackgroundColor3 = Color3.new(
	                        templateInstance.BackgroundColor3.R * 0.8,
	                        templateInstance.BackgroundColor3.G * 0.8,
	                        templateInstance.BackgroundColor3.B * 0.8
	                    ),
	                }
	            else
	                return {}
	            end
	        end,
	    })
	end
	```

	:::caution

	You should not modify `templateInstance` or its children. It won't directly affect
	the render, since `instance` is just a template, but it may affect future
	renders that depend on the instance.

	:::
]=]

--[=[
	@prop None None
	@within RoactTemplate

	Represents "nil" when overwriting props or children.
]=]
RoactTemplate.None = newproxy(true)
getmetatable(RoactTemplate.None).__tostring = function()
	return "<RoactTemplate.None>"
end

export type None = typeof(RoactTemplate.None)

local Wrap = newproxy(true)
getmetatable(Wrap).__tostring = function()
	return "<RoactTemplate.Wrap>"
end

--[=[
	@prop Root Root
	@within RoactTemplate

	A special selector representing the root instance of a template.

	This is an easy alternative to specifying the root instance's name, which
	may not stay consistent.

	For example:
	```lua
	local function ButtonFromTemplate(instance)
	    -- instance can be any Button object
	    local Button = RoactTemplate.fromInstance(instance)
	    return function(props)
	        return Roact.createElement(Button, {
	            -- we don't know the name of the button, so we can use Root instead.
	            [RoactTemplate.Root] = {
	                [Roact.Event.Activated] = props.onActivated,
	            },
	        })
	    end
	end
	```
]=]
RoactTemplate.Root = newproxy(true)
getmetatable(RoactTemplate.Root).__tostring = function()
	return "<RoactTemplate.Root>"
end

export type Root = typeof(RoactTemplate.Root)

--[=[
	Creates a component given an instance.

	The component's props are a dictionary of `Selector -> Changes` where:
	* A `Selector` can be a `string` (fast) *or* a callback that acts on the
	  Instance and returns true/false (slow).
	* `Changes` can be a table of properties or a function returning a table of
	  properties.

	For example:
	```lua
	local Roact = require(game.ReplicatedStorage.Packages.Roact)
	local RoactTemplate = require(game.ReplicatedStorage.Packages.RoactTemplate)

	local InventoryTemplate = RoactTemplate.fromInstance(Roact, UITemplates.InventoryApp)

	local function InventoryApp(props)
	    return Roact.createElement(InventoryTemplate, {
	        WindowTitle = {
	            Text = props.category,
	        },
	        OuterFrame = {
	            Visible = props.visible,
	        },
	        Scroller = {
	            [Roact.Children] = makeInventoryItems(props.items),
	        },
	    })
	end
	```
]=]
function RoactTemplate.fromInstance(Roact: Roact, instance: Instance): ({ [Selector]: Changes }) -> Element
	return RoactTemplate.componentFromInstance(Roact, instance)
end

--[=[
	Used to wrap an element with a component.

	Wrapping a descendant element with a component allows you to efficiently
	apply stateful changes without re-rendering the whole tree.

	The only provided prop is `template` which can be used to render the
	elements we're wrapping. `template` supports the `{ [Selector]: Changes }`
	props as usual.

	For example:
	```lua
	    local TitleComponent = Roact.Component:extend("TitleComponent")

	    function TitleComponent:init()
	        self:setState({ transparency = 1 })
	    end

	    function TitleComponent:didMount()
	        self.updater = RunService.Heartbeat:Connect(function()
	            self:setState({ transparency = math.sin(os.clock() / math.pi) })
	        end)
	    end

	    function TitleComponent:render()
	        return Roact.createElement(self.props.template, {
	            Title = {
	                TextTransparency = self.state.transparency,
	            },
	        })
	    end

	    local InventoryTemplate = RoactTemplate.fromInstance(Roact, ExampleTemplateUI)

	    -- Now we can wrap the Title with our TitleComponent to get stateful
	    -- changes without re-rendering the whole outer component.
	    Roact.createElement(Template, {
	        Title = RoactTemplate.wrapped(TitleComponent)
	    })
	```

	:::caution

	The `template` component does not automatically preserve the props passed to
	the outer component. If you need the same props, pass similar props when you
	createElement your `template` in the component's `render`.

	***Be careful not to pass the `wrapped` component into the `template`'s
	props*** as that would apply the wrapped component recursively, infinitely.

	:::
]=]
function RoactTemplate.wrapped(component: Component): Changes
	return {
		[Wrap] = component,
	}
end

--[=[
	@tag Extra
	@private
	Creates a component given an instance. This is the same as `fromInstance`.

	See `fromInstance` for more info.
]=]
function RoactTemplate.componentFromInstance(Roact: Roact, instance: Instance): ({ [Selector]: Changes }) -> Element
	if typeof(instance) ~= "Instance" then
		warn("instance object related to the following error message:", instance) -- allows user inspection
		error("Expected an Instance for instance argument, got " .. typeof(instance))
	end

	local template = RoactTemplate.templateFromInstance(instance)

	return RoactTemplate.componentFromTemplate(Roact, template)
end

--[=[
	@tag Extra
	@private
	Creates a static component given an instance.

	This component cannot change since it caches its elements. This is a very
	speedy way to show static UI since the Roact element tree is created only
	once.
]=]
function RoactTemplate.staticComponentFromInstance(
	Roact: Roact,
	instance: Instance,
	selectors: { [Selector]: Changes }
): (...any) -> Element
	local template = RoactTemplate.templateFromInstance(instance)

	local element = RoactTemplate.elementFromTemplate(Roact, template, selectors)

	return function()
		return element
	end
end

--[=[
	@tag Extra
	@private
	Returns the `props` necessary to create an instance. The props can be passed
	in to `createElement` to create an equivalent instance, minus its children.
]=]
function RoactTemplate.propertiesFromInstance(instance: Instance): { [string]: any }
	assert(typeof(instance) == "Instance", "Expected argument #1 (instance) to be an instance")

	local api = ApiDumpStatic.Classes[instance.ClassName]
	assert(api, "Unknown instance type '" .. instance.ClassName .. "'")

	local properties = {}

	for name, info in pairs(api:Properties()) do
		if
			not DISALLOWED_PROPS[name]
			and (info.Security == "None" or (info.Security.Read == "None" and info.Security.Write == "None"))
			and not (info.Tags and (table.find(info.Tags, "NotScriptable") or table.find(info.Tags, "ReadOnly")))
		then
			pcall(function()
				local prop = (instance :: any)[name]
				if prop ~= api:GetPropertyDefault(name) then
					properties[name] = prop
				end
			end)
		end
	end

	return properties
end

--[=[
	@tag Extra
	@private
	Returns the internal template for a given instance.
]=]
function RoactTemplate.templateFromInstance(instance: Instance): TemplateItem
	local elements: { [string]: TemplateItem } = {}

	local toProcess = { { instance = instance, parent = elements } }
	while #toProcess > 0 do
		local item = table.remove(toProcess)
		assert(item, "always") -- typechecker assert

		local children = {}

		local props = RoactTemplate.propertiesFromInstance(item.instance)
		table.freeze(props)

		local existingItem = item.parent[item.instance.Name]
		if existingItem then
			if existingItem.type ~= "fragment" then
				item.parent[item.instance.Name] = table.freeze({
					type = "fragment" :: "fragment",
					children = {
						[item.instance.Name] = existingItem,
					},
				})

				existingItem = item.parent[item.instance.Name]
			end

			existingItem.children[item.instance.Name .. " " .. HttpService:GenerateGUID()] = table.freeze({
				type = "element" :: "element",
				singleFragment = true,
				class = item.instance.ClassName,
				instance = item.instance,
				props = props,
				children = children,
			})
		else
			item.parent[item.instance.Name] = table.freeze({
				type = "element" :: "element",
				isRoot = item.instance == instance,
				class = item.instance.ClassName,
				instance = item.instance,
				props = props,
				children = children,
			})
		end

		for _, child in ipairs(item.instance:GetChildren()) do
			table.insert(toProcess, { instance = child, parent = children })
		end
	end

	local rootElement = elements[instance.Name]

	return rootElement
end

local function merge(into: { [any]: any }, from: { [any]: any }, none: any?)
	for key, value in pairs(from) do
		if value == none then
			value = nil
		end
		into[key] = value
	end
end

local function applySelectors(
	Roact: Roact,
	template: TemplateItemElement,
	slowSelectors: { [SelectorCallback]: Changes }?,
	fastSelectors: { [string | Root]: Changes }?
): ({ [string]: any }, { [string]: any })
	if not (fastSelectors or slowSelectors) then
		return table.clone(template.props), {}
	end

	local newProps = {}
	local newChildren = {}

	local function apply(changes: Changes)
		if typeof(changes) == "function" then
			local changesResult = changes(template.instance)

			if typeof(changesResult) ~= "table" then
				local sourceId, line, name = debug.info(changes, "sln")
				warn("Changes object related to the following error message:", changes) -- allows user inspection
				error(
					string.format(
						"Expected a table from ChangesCallback, got %s. Callback: %s:%s: %s",
						typeof(changesResult),
						tostring(sourceId or "[unknown]"),
						tostring(line or "unknown"),
						tostring(name or "unknown")
					)
				)
			end

			changes = changesResult
		end

		if typeof(changes) ~= "table" then
			warn("Changes object related to the following error message:", changes) -- allows user inspection
			error("Expected a table or function for Changes, got " .. typeof(changes))
		end

		assert(typeof(changes) == "table", "always") -- typechecker assert

		merge(newProps, changes)

		if newProps[Roact.Children] then
			merge(newChildren, newProps[Roact.Children])
			newProps[Roact.Children] = nil
		end
	end

	if fastSelectors then
		if fastSelectors[RoactTemplate.Root] and template.isRoot then
			apply(fastSelectors[RoactTemplate.Root])
		end

		if fastSelectors[template.instance.Name] then
			apply(fastSelectors[template.instance.Name])
		end
	end

	if slowSelectors then
		for selector, changes in pairs(slowSelectors) do
			if selector(template.instance) then
				apply(changes)
			end
		end
	end

	return newProps, newChildren
end

local function elementFromTemplate(
	Roact: Roact,
	template: TemplateItem,
	slowSelectors: { [SelectorCallback]: any }?,
	fastSelectors: { [string | Root]: any }?
): any
	if template.type == "fragment" then
		local children = {}

		for name, child in pairs(template.children) do
			children[name] = elementFromTemplate(Roact, child, slowSelectors, fastSelectors)
		end

		return Roact.createFragment(children)
	end
	assert(template.type == "element", "always") -- typechecker assert

	local newProps, newChildren = applySelectors(Roact, template, slowSelectors, fastSelectors)

	local element
	if newProps[Wrap] then
		element = Roact.createElement(newProps[Wrap], {
			template = RoactTemplate.componentFromTemplate(Roact, template),
		})
	else
		local props = table.clone(template.props)
		merge(props, newProps)

		local children = {}
		for name, child in pairs(template.children) do
			if newChildren[name] == nil then
				children[name] = elementFromTemplate(Roact, child, slowSelectors, fastSelectors)
			end
		end
		merge(children, newChildren, RoactTemplate.None)

		element = Roact.createElement(template.class, props, children)
	end

	if template.singleFragment then
		element = Roact.createFragment({
			[template.instance.Name] = element,
		})
	end

	return element
end

--[=[
	@tag Extra
	@private
	Creates a Roact element from an internal template.
]=]
function RoactTemplate.elementFromTemplate(
	Roact: Roact,
	template: TemplateItem,
	selectors: { [Selector]: Changes }?
): Element
	if selectors ~= nil and typeof(selectors) ~= "table" then
		warn("selectors object related to the following error message:", selectors) -- allows user inspection
		error("Expected a table { [Selector]: Changes } or nil for selectors, got " .. typeof(selectors))
	end

	local slowSelectors: { [SelectorCallback]: any }? = nil
	local fastSelectors: { [string | Root]: any }? = nil
	if selectors ~= nil then
		slowSelectors = {}
		fastSelectors = {}
		assert(fastSelectors, "always") -- typechecker assert
		assert(slowSelectors, "always") -- typechecker assert

		for key, value in pairs(selectors) do
			if typeof(key) == "string" or key == RoactTemplate.Root then
				fastSelectors[key] = value
			elseif typeof(key) == "function" then
				slowSelectors[key] = value
			else
				error(
					("Unknown Selector type " .. typeof(key) .. " (expected string | function | RoactTemplate.Root)\n")
						.. "  Are you trying to specify props for the root instance of the template? Try the following instead:\n"
						.. "  [RoactTemplate.Root] = { YourProps = 'Your Values' }"
				)
			end

			if typeof(value) ~= "table" and typeof(value) ~= "function" then
				error(
					("Unknown Changes type " .. typeof(value) .. " (expected table | function)\n")
						.. "  Are you trying to specify props for the root instance of the template? Try the following instead:\n"
						.. "  [RoactTemplate.Root] = { YourProps = 'Your Values' }"
				)
			end
		end

		if next(slowSelectors) == nil then
			slowSelectors = nil
		end
		if next(fastSelectors) == nil then
			fastSelectors = nil
		end
	end

	return elementFromTemplate(Roact, template, slowSelectors, fastSelectors)
end

--[=[
	@tag Extra
	@private
	Creates a Roact component from an internal template.
]=]
function RoactTemplate.componentFromTemplate(Roact: Roact, template: TemplateItem): ({ [Selector]: Changes }) -> Element
	return function(selectors)
		return RoactTemplate.elementFromTemplate(Roact, template, selectors)
	end
end

return RoactTemplate
