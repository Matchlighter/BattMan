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
