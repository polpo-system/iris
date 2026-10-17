# Iris, a picture viewer for polpo

Iris shows pictures in a viewer of the tiling desktop of polpo (no Gadgets needed):

    Iris.Open name      a picture file: Oberon pictures (.pic), GIF, JPEG, BMP, TGA, PCX, ICO,
                        IFF and XPM
    Iris.Open ^         the selected name
    Iris.Info           in the menu: name, size and depth of the picture

Drag the picture with any mouse button to pan; System.Copy opens a second viewer of the same
picture. `Iris.Tool` lists the commands.

How the formats plug in: `Pictures.Open` reads Oberon pictures itself; for another file it
looks up the extension in the section PictureConverters of `Oberon.Text`
(`gif = GIF.InitPicture`), loads that module by name (`Modules.ThisMod`), calls the command
(`Modules.ThisCommand`) and lets it read the file. Nothing imports the converters, so a new
format is a new module and a line in Oberon.Text. The converters are in
https://github.com/polpo-system/picture-formats, one portia package each.

`test/IrisTest.Mod`: an Oberon picture stored as t.pic and opened again (needs the desktop).

Install with portia: `portia.Install iris`. The converters of the formats above come with it as
dependencies; XBM and PBM/PGM/PPM need the gadgets (gadgets-xbm, gadgets-ppm).
The license is GPL-3 (`LICENSE`); the code comes from ETH Oberon, whose license (`LICENSE.ETH`)
asks to keep its copyright notice and conditions, which `LICENSE.ETH` does.
