<div align="center">

<img src="https://github.com/Matchlighter/BattMan/blob/main/public/logo.png?raw=true" alt="BattMan" width="200"/>

# Battery Manager

Stop forgetting where you're using your expensive rechargeable batteries.

</div>

## Premise
It's all too often that I go to grab some (rechargeable) batteries and ask myself "Where the heck did the all go?!".
That's an annoying question when I have some rather expensive batteries. I have a handheld barcode/QR scanner that I needed a project for, so...

## Usage
Presently, this is pretty tailored to my use case. I have a Netum DS2800 2D Scanner that can transmit data via MQTT. This app listens for MQTT messages from the scanner, and logs the info.

When a battery is scanned within 5 minutes of scanning a device, that battery is automatically linked to that device.

If you want to use this in it's present state, you'll need to be able to intepret Ruby and do some modifications. I may make it more generic at some point, but for now it solves my "need".

## Default Data Model

### Things
`Thing`s are a core concept. A `Thing` represents anything that exists (or could exist) in the real world. That includes places, locations, devices, appliances, your cat, your house, your garage, the bin of stuff you have in your garage - if you can see it with your eyes, it's a `Thing`.

Conversely, the following are concepts/ideas and thus are not `Thing`s: events (eg Christmas, or when you changed your car's oil), warranties (though you could have a booklet wherin the warranty is written - that'd be a `Thing`).

#### Locations
A sub-type of `Thing` that represents a Location or where you'd store other `Thing`s - eg your house, your garage, etc. `Location`s may belong to `Location`s which may belong to `Location`s - you get the idea.

#### Items
Most `Thing`s that aren't a `Location` are probably an `Item`. Could be your cat, your house (notice how you can consider your house as both a `Location` and an `Item` - that's what makes BattMan awesome), your phone, that DVD people like to borrow, etc.

##### Devices
Devices are a more specific type of `Item` - all `Device`s are `Item`s, but not all `Item`s are `Device`s. `Device`s are really special in any way - classifying one of your `Thing`s as a device is just a way to group your `Thing`s and add some presets to them. For example, `Devices` usually have batteries, a warranty, etc. By introducing the `Device` type, we can apply a sensible preset/template to your `Thing`. You could achieve the same effect manually/directly on your `Thing`, but templates are nice!

##### Appliances
`Appliance`s are pretty much the same story as `Device`s.

##### Batteries
Guess what - also `Item`s just like `Device`s and `Appliance`s! The `Battery` "template" has a `can-belong-to:` tag that makes it so that you can easilly link and `Battery`'s to a `Device`. Again, you could manually add the `can-belong-to:` tag to any `Thing` that you wanted, but (again) templates are nice!

#### Products
Used to tag a Thing that is a "class" of Items that you may have multiple instances/copies of.

For example, you might have 3 of the same model of TV.
- Each was bought on a different date, has a different S/N, etc.
- But they all have the same manual, warranty terms, etc.

Products are just `Item`s that include the (non-inheritable) `product: true` tag.

When duplicating an `Item` via the UI, it allows you to first "convert" the `Item` into a `Product` - basically, it just duplicates it, sets the `product: true` tag, and then applies some magic (aka the `implements:` tag) to link the existing `Item` to the new `Product` (yes, 1 became 3 here - you started with 1 `Item`. Duplicating that `Item` produced a `Product`, the updated `Item`, and a new duplicate of that `Item`. That's 3 `Thing`s.).

#### Templates
Yet another `Thing` (because they represent/describe something that _can_ exist in the real world). A `Template` provides preset tags that you can apply/mixin to your `Thing`s. The above concept of "Items" and "Locations" are implemented via Templates. Again, they're all just `Thing`s with a number of tags. Templates just allow you to apply a bunch of tags at once.

## Resources
- https://wifi.scandocs.net/DS2800/en/
- https://github.com/MultiMote/niimblue

## TODO (Feel free to PR ;) )
- Move `Device` and `Battery` `PATTERN` definitions to a YML file
- Support configuration of ID parsing
- Add a special "charger" Device that. Probably no backend necessary, but UI should display date of last charge
- Dockerfile
- Implement Auth?

## License
This thing is dead simple - literally a 2 day project at this point. If I seek to expand it, I may adopt a more formal license, but for now, do whatever the heck you want with this project.

[repo_url]: https://github.com/Matchlighter/BattMan
