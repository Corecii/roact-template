--!strict
local CollectionService = game:GetService("CollectionService")

local ApiDumpStatic = require(script.Parent.Parent.ApiDumpStatic)

local function newSelector<T...>(call: (instance: Instance, T...) -> boolean): (T...) -> (instance: Instance) -> boolean
	return function(...)
		local args = table.pack(...)
		return function(instance: Instance)
			return call(instance, unpack(args, 1, args.n))
		end
	end
end

--[=[
	@class Select

	Selectors to use to change descendent elements.

	These selectors **will be slower** than name-based selection. Name selection
	is preferred since we can do fast look-ups to check if any descendant has a
	given name.
]=]

local Select = {}

--[=[
	@function prop
	@within Select
	@param prop string
	@param value any
	@return (instance: Instance) -> boolean

	Selects an element according to the value of a property
]=]
Select.prop = newSelector(function(instance, prop, value)
	local info = ApiDumpStatic.Classes[instance.ClassName]:Properties()[prop]
	if not info then
		return false
	end
	if
		not (info.Security == "None" or info.Security.Read == "None")
		or (info.Tags and table.find(info.Tags, "NotScriptable"))
	then
		return false
	end

	return (instance :: any)[prop] == value
end)

--[=[
	Selects an element according to its name.

	This is *slower* than the default `["name"] = { changes }` syntax.
]=]
function Select.name(name: string): (instance: Instance) -> boolean
	return Select.prop("Name", name)
end

--[=[
	Selects an element according to its class name.
]=]
function Select.class(class: string): (instance: Instance) -> boolean
	return Select.prop("ClassName", class)
end

--[=[
	@function isA
	@within Select
	@param prop string
	@param value any
	@return (instance: Instance) -> boolean

	Selects an element according to if it `:IsA` class
]=]
Select.isA = newSelector(function(instance, class)
	return instance:IsA(class)
end)

--[=[
	@function propPattern
	@within Select
	@param prop string
	@param pattern string
	@return (instance: Instance) -> boolean

	Selects an element according whether the value of a property matches a pattern.
]=]
Select.propPattern = newSelector(function(instance, prop, pattern)
	local info = ApiDumpStatic.Classes[instance.ClassName]:Properties()[prop]
	if not info then
		return false
	end
	if
		not (info.Security == "None" or info.Security.Read == "None")
		or (info.Tags and table.find(info.Tags, "NotScriptable"))
	then
		return false
	end

	return tostring((instance :: any)[prop]):match(pattern) and true or false
end)

--[=[
	Selects an element according whether the name matches a pattern.
]=]
function Select.namePattern(pattern: string): (instance: Instance) -> boolean
	return Select.propPattern("Name", pattern)
end

--[=[
	Selects an element according whether the class name matches a pattern.

	For example, `^Text.+$` matches both `TextLabel` and `TextBox`.
]=]
function Select.classPattern(pattern: string): (instance: Instance) -> boolean
	return Select.propPattern("ClassName", pattern)
end

--[=[
	@function attribute
	@within Select
	@param attribute string
	@param value string
	@return (instance: Instance) -> boolean

	Selects an element according whether the value of an attribute equals a value.
]=]
Select.attribute = newSelector(function(instance, name, value)
	return instance:GetAttribute(name) == value
end)

--[=[
	@function tag
	@within Select
	@param tag string
	@return (instance: Instance) -> boolean

	Selects an element according whether its template instance has a tag.
]=]
Select.tag = newSelector(function(instance, tag)
	return CollectionService:HasTag(instance, tag)
end)

-- We intentionally use pairs for the following so that if an array with holes
-- is passed it cannot cause buggy behavior.

--[=[
	@function some
	@within Select
	@param ... Selector
	@return (instance: Instance) -> boolean

	Selects an element according whether at least one of the given selectors matches.
]=]
Select.some = newSelector(function(instance, ...: (instance: Instance) -> boolean)
	for _, selector in pairs({ ... }) do
		if selector(instance) then
			return true
		end
	end

	return false
end)

--[=[
	@function every
	@within Select
	@param ... Selector
	@return (instance: Instance) -> boolean

	Selects an element according whether all of the given selectors matches.
]=]
Select.every = newSelector(function(instance, ...: (instance: Instance) -> boolean)
	for _, selector in pairs({ ... }) do
		if not selector(instance) then
			return false
		end
	end

	return true
end)

--[=[
	@function no
	@within Select
	@param selector Selector
	@return (instance: Instance) -> boolean

	Selects an element if the given selector fails for the element.
]=]
Select.no = newSelector(function(instance, selector)
	return not selector(instance)
end)

return Select
