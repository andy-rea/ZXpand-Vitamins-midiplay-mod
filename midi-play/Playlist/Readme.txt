
ZX81 + ZXpand+ Midi Player with Playlist support

you will need...

suitable midi files
Charlie Robson's 

midicsv.exe
midimash,exe
conv.bat
convall.bat
convCSV.bat
winmash.bat

Available from https://github.com/charlierobson/ZXpand-Vitamins/tree/1625a99e533ef97050629181769f0e6afba1ed7b/midi-mash

and listconv.py
or listconv.exe

convert your midis to ZXM see Chalie robson work


Once you have your collection of suitable ZXM files we need a cmd prompt and navigate
 to the folder containing our ZXM files brace yourself...  ( oh yeah all this is on windows becuase thats all i do )

in the cmd prompt type  DIR *.ZXM /b >playlist.TXT

This will create a txt file with just the ZXM filenames 1 per line... this is the minimum requirement 
HOWEVER now is your chance to add the descriptive text open your favorite text editor and after each 
filename on the same line if you want to add text leave 1 or more spaces after the filename and put 

#your descriptive text blah blah blah upto 256 characters but it doesn't matter it you go over 256.

So the complet line will look like

SOMENAME.ZXM #my descriptive text blah blah ect...

case dosn't matter it all get converted to a form the ZX81 understands

The important thing is that the text remains on one line with the file name at the beginning, 
the spaces between the filename and the # don't count but the text starts immediately after the #
Ascii characters that don't map to ZX81 characters are mostly replaced with spaces.

having your *.ZXM files in the same directory as your text playlist during conversion it will attempt to retrieve the length of the midi file
display during playback, other wise --:-- will be displayed

Once we are happy with our text based list we go back to the cmd prompt ( you did leave it open right? )
and we type 

listconv.py [-h] [-v] Source_file [Destination_file]

for example

LISTCONV.PY MyPlayList.txt ZX81NAME.ZPL

which will convert the file MyPlayList.txt  into a zx81 for called ZX81NAME.ZPL
if the output file already exsists you will be asked to confirm overwritting it
the output filename is also optional if no name is supplied default.zpl is used

 
if you don't have python installed you can use the bloated exe instead 
( it the same program but has the python runtimes packed in there as well )
 in which case you would type 

LISTCONV MyPlayList.txt ZX81NAME.ZPL


it should do its thing and tell you at the end how many entries have been created... 
There is a -v Verbose option but the output isn't very nice. I used it mostly for debugging.

And i know the python is awful, it not my thing and probbaly never will be so i just hacked a bunch of stuff together till it 
did what i needed it to do.

Right after that ideally we can copy the *.ZXM files and the ZX81NAME.ZPL ( or what ever you named it)
and the PLISTMID.P (the player) file into a suitable folder on your ZX81 sd card.

Now then, are we are seated at our favorite 8-bit ZX81? 
Fire that sucker up and navigate to the folder you just made andand load up PLISTMID.P

You should be greeted with a somewhat familiar screen asking for a track number
( plays just like the old player ) OR you can input a playlist filename 
( make sure to put the full name including .ZPL )

What happens if you enter a ZPL playlist file ?...
playlist files have a maximum size of 8192 bytes and are loaded into memory at 32768 
Each playlist entry consumes a minimum of 10 bytes ( A.ZXM--:--) the filename minimum 5 bytes
 and 5 bytes for the tracktime. + an optional additinal 2 to 257 byte $FE + descriptive text.

so in theory you could fit over 700 entries but the filenames would be useless as we would be
restricted to 2 character names + the extensiom. 

And a minimum of 29 entries if you used the full 
8.3 names and the full 256 characters for the descriptive text  on every entry.

Have fun 


