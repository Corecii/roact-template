# Roact Template (from Instance)

A library that allows you to load an instance as a Roact component at runtime

[Documentation](https://corecii.github.io/roact-template/)

Install with [wally](https://wally.run):
```toml
# wally.toml
[dependencies]
RoactTemplate = "corecii/roact-template@0.2.0"
```

When API dumps become outdated, open your `wally.lock` and remove the `corecii/api-dump-static` section, then run `wally install` again.
*(in the future, you will be able to use `wally upgrade`, but upgrade is not available yet)*

You can also use the [packaged release model](https://github.com/Corecii/roact-template/releases/latest),
but be aware that the internal
API dump is *not* updated with every Roblox update. When using Wally, the newest API
dump is fetched automatically on install. When using the pre-packaged model, the
latest API dump is *not* fetched automatically. You can download the latest API
dump [here](https://github.com/Corecii/api-dump-static/releases/latest)
to replace the included one with the newest version.

---

RoactTemplate allows you to change descendants of your template interface. You can:
* Change descendants by their name
* Assign descendants props and children
* Wrap descendants in components (see `wrapped` in the docs!)
* Select descendants to change according to a custom callback or pre-made selectors

### Quick Simple Example

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

---

## Notes

Compared to the "convert to Roact *code*" approach, this allows you to easily
edit UI in Studio even after you start programming it.

RoactTemplate only replaces the *static* parts of your UI. This allows you to
program the dynamic parts declaratively, while using Roblox's great built-in
editor for the static parts.

Roact is based on React, which was made for web development. Web development is
founded on hand-writing structure (HTML) and style (CSS) markup. Roblox, on the
other hand, is founded on a great editor, and lacks a CSS-equivalent. Because of
these differences, using Roact typically involves throwing out one of Roblox's
biggest advantages: its editor. RoactTemplate allows you to use the editor as
you would before Roact existed, then program your UI declaratively using Roact.
It's the best of both worlds!

I recommend storing your UI templates as `rbxm` or `rbxmx` files next to or as a
child of the code that uses the UI templates. You should ideally store each
interface or component as its own model so that resolving merge conflicts is easier.
