To build this program you need
- Lazarus IDE: https://www.lazarus-ide.org/
- Free Pascal Compiler: https://www.freepascal.org/

No support is given.

# What it Does

The program searches for `.ini` files which are not `BINI` files in the selected directory and all sub-directories. From those files it extracts specifically formatted text and puts it inside an `.frc` file - which then can be used via [adoxa's Freelancer Resource Compiler](http://adoxa.altervista.org/freelancer/tools.html#frc) to convert it into an resource DLL file.

The program registers the resource text within the `.ini` files and to which key-value lines they are assigned to, and automatically generates IDs for those and writes them back into the `.ini` files.

# How to Use

All relevant information for this tool is written in normal commentary format inside the `ini` files to not break any other tools or the game itself.

## Keys

There are three keys for the tool to register resource text inside the files:
- `;res str` for simple unformatted strings (new lines however work)
- `;res html` for formatted text
- `;res $someName` for referring to another named resource

To name another resource for the `;res $` lines, just add a globally unique name after the usual keys. For example:

```;res str MyGreatName```

and then you can reference it anywhere by writing

```;res $MyGreatName```

The tool will then use the exact same IDs here instead of making a new text. This is intended for repeating entires like for trade lane names or the barebone ship statistic infocards.

The names must be unique through all files. They are case insensitive.

## Knowledge DB Entries

To link "knowledge" entries (`rumor`, `rumor_type2` and `know`) they must be followed on the same line by `;knowdb <list of nicknames>`.

Example:
```
rumor = base_0_rank, mission_end, 1, 131196 ;knowdb li01_01, li01
```


## Format of Text

The formatting of any text is following exactly the same rules as adoxa's FRC wants it. Its readme describes it as:

```
Sequence  RDL                       Notes
-----------------------------------------------------------------
\b        <TRA bold="true"/>
\B        <TRA bold="false"/>
\cC       <TRA color="#RRGGBB"/>    C must be lower case
\cName    <TRA color="#RRGGBB"/>    Name matches case
\cRRGGBB  <TRA color="#RRGGBB"/>    use upper case hex letters
\C        <TRA color="default"/>
\fN       <TRA font="N"/>           one or two digits
\F        <TRA font="default"/>
\hN       <POS h="N" relH="true"/>  one to three digits
\i        <TRA italic="true"/>
\I        <TRA italic="false"/>
\l        <JUST loc="l"/>           left
\m        <JUST loc="c"/>           center (middle)
\n        <PARA/>                   adds a new line in plain text
\r        <JUST loc="r"/>           right
\u        <TRA underline="true"/>
\U        <TRA underline="false"/>

Name      RRGGBB        C    RRGGBB      C may be prefixed with:
----      ------        -    ------
Gray      808080        z    000000      d to use 40 (dark)
Blue      4848E0        r    FF0000      h to use 80 (half)
Green     3BBF1D        g    00FF00      l to use C0 (light)
Aqua      87C3E0        b    0000FF
Red       BF1D1D        c    00FFFF
Fuchsia   8800C2        m    FF00FF
Yellow    F5EA52        y    FFFF00
White     FFFFFF        w    FFFFFF
```

## Adding Text to the Keys

Find the line you want to add the resource text to. Then simply make a new line below it starting with one of the Keys. After that you must start each line of the resource text with a commentary symbol and a space following after ( `; ` ).

Set your ID to `0` to let the tool assign a new one. If you leave the existing ID, the tool will update the actual text behind it.

Example:
```
[Weapon]
nickname = gun_mark01
ids_name = 0
;res str
; Big Bang Gun
ids_info = 0
;res html
; \bBold Heading\B
; \mCentered Text\l
; \n
; This is the last line of this infocard.

...and the rest of the weapon settings...
```

With this the resource text "Starflier" will be automatically assigned to the preceeding `ids_name`, and the infocard text will be inserted for the `ids_info`.

## Adding multiple Resources

### ID Ranges

Some values like `firstname_male` accept an entire range of IDs. This can be done by simply writing multiple resource blocks below the line:

```
firstname_male = 0, 0
;res str
; Hans
;res str
; Olaf
;res str
; Heino
;res str
; Peter
...
```

The tool automatically recognizes those special cases and assigns the first and last ID correctly to this.

Those ID ranges are only automatically assigned for:
- `firstname_male`
- `firstname_female`
- `lastname`
- `formation_desig`
- `large_ship_names`

### Multiple IDs for one Line

Sometimes the game lists multiple IDs in one line. Again for this, simply create multiple blocks as in the previous example.

The only use-case for this is:
- `rank_desig`

### Base Descriptions

Descriptions of bases in Freelancer are separated into two infocards. One is directly assigned to the `[Object]` in the system file. This is usually the general statistics on the base (e.g. population count, type name, etc).
And then there's always a second infocard which describes more detailed information on the base. This is just visible to the player when at least once docked on the base.

To create those two related infocards for a base, simply add two resource blocks to the base's `ids_info`:

```
[Object]
nickname = li01_01_Base
ids_name = 0
;res str
; Planet Manhatten
ids_info = 0
;res html
; Diameter: 500km
; Mass: 3*10^8kg
; Population: 500000
;res html
; Planet Manhatten was the first planet settled by colonists in Sirius.
; The entire planet's surface is one big connected city.
; It is the capital of Liberty.
```

To achieve the linking of those two resources the tool will automatically add a `map` entry for it inside the `infocardmap.ini` file usually located in DATA\INTERFACE\ directory. To always generate them anew it does delete all entries that contain an ID number which is outside the vanilla game's ID range.

## Adding global Resource

The tool can also create global resources at the first line of any read file that are not directly linked to something. This is only useful if this global resource is given a name and referenced later. One example may be the barebone ship statistic infocards.

```
;res html ShipStats
; Hull Points:
; Mass:
; Nanobots/Batteries:
; Cargo Space:
```

and then later referenced by:

```
[Ship]
nickname = ge_fighter
ids_name = 0
;res str
; Starflier
ids_info2 = 0
;res $ShipStats
ids_info3 = 0
...
```

## Handling grammatical cases for Faction Names and Zones

Freelancer allows for multiple entries of a faction name or zone name to handle grammatical cases present in other languages (e.g. English has just 1, German has 4). Via [adoxa's Name plugin](http://adoxa.altervista.org/freelancer/plugins.html#names) this can be achieved in mods, too.

Again, for those simply add multiple resource blocks to the relevant entries. The tool will always just assign the first resource's ID in the ini file, but keep the others and put them into the output in the defined order.

```
[Zone]
ids_name = 0
;res str
; Badlands
;res str
; The Badlands
;res str
; the Badlands
```