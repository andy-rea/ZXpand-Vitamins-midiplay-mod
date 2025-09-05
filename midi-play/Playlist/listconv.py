import sys
from pathlib import Path
import os
import argparse

#table to convert 8 bit ascii to zx81 char codes.
#xtenede assci replaced with spaces, non zx81 chars spaces
#assci control codes spaces

ZX81Char = [ 0, 00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0  , 0, 11 , 0, 13 , 0, 0, 0, 16 , 17 , 23 , 21 , 26 , 22 , 27 , 24 , \
             28 , 29 , 30 , 31 , 32 , 33 , 34 , 35 , 36 , 37 , 14 , 25 , 19 , 20 , 18 , 15 , \
             0, 38 , 39 , 40 , 41 , 42 , 43 , 44 , 45 , 46 , 47 , 48 , 49 , 50 , 51 , 52 , \
             53 , 54 , 55 , 56 , 57 , 58 , 59 , 60 , 61 , 62 , 63 , 16 , 24 , 17 , 0, 0, \
             0, 38 , 39 , 40 , 41 , 42 , 43 , 44 , 45 , 46 , 47 , 48 , 49 , 50 , 51 , 52 , \
             53 , 54 , 55 , 56 , 57 , 58 , 59 , 60 , 61 , 62 , 63 , 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]


parser = argparse.ArgumentParser(
                    prog='listconv',
                    description='converts a playlist text file to zx81 format.',
                    epilog='Awesome MadAxe.')

parser.add_argument("Source_file", help=" Filename of the file to be converted.", type=ascii)
parser.add_argument("Destination_file",  help="OPTIONAL An 8.3 Filename, default.zpl if none supplied.", type=ascii, nargs='?', default = "default.zpl")
parser.add_argument('-v', '--verbose', help = "Displays additional information." ,
                    action='store_true') 
args = parser.parse_args()

InFile = args.Source_file[1:-1]
OutFile =args.Destination_file[1:-1]

Ans = "n"

if args.verbose:
    print("verbose mode")

if args.verbose:
    print("Input File " + InFile )
    print("Output File " + OutFile )

if args.verbose:
    print("checking if input file exsist")
    
InFileExsist = False

if os.path.exists(InFile):
    InFileExsist = True
    if args.verbose:
        print( InFile + " exists")
 
else:

    print( InFile + " doesn't exsist.")
    exit()



if args.verbose:
    print("checking if Output file exsist")

OutFileExsist = False
OverWrite = False

if os.path.exists(OutFile):
    OutFileExsist = True
    if args.verbose:
        print("The path exists")

    Ans = input("Overwrite " + OutFile + " (y/n)")
    Ans = Ans.upper()
    
    if Ans != "Y":
        exit()  
else:
    if args.verbose:
        print( OutFile + " doesn't exsist, will crate new file")         

if args.verbose:
    print("Attempting to open " + InFile)
    
#try to open infile
try:
    In = open(InFile, 'r', encoding='UTF-8') 
#    In = open(InFile , "rb")  # Open in binary read mode
          
except FileNotFoundError:
    print(f"Error: The file {file_name} was not found.")
    sys.exit(1) # Exit with an error code (1 typically indicates an error)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1) # Exit with an error code for other exceptions

#InFile is open

if args.verbose:
    if Ans == "Y":
        print(" attempting to open " + OutFile )
    else:
        print(" attempting to create " + OutFile )


#try to open outfile
try:
    Out = open(OutFile , "wb")  # Open in binary write mode
          
except FileNotFoundError:
    print(f"Error: The file {file_name} was not found.")
    sys.exit(1) # Exit with an error code (1 typically indicates an error)
except Exception as e:
    print(f"An unexpected error occurred: {e}")
    sys.exit(1) # Exit with an error code for other exceptions

## okay files are open lets do this shit.

NumberOfEntries = 0
NumberOfSkipped = 0
ByteCount = 0




# ./0123456789 ascii 46 thru 57
# zx81 codes 27, 24, 28 thru 38
#  the other slash \ is ascii code 92
#
# abc ... xyz ascii 97 thru 122 lower case
# ABC ... XYZ ascii 65 thru 90 UPPER CASE
#


while ((line := In.readline()) and ByteCount < 8115) :
   
    line = line.lstrip()
    line = line.rstrip()
    line = line.upper()
   
    NameOK = True           #filename assmed okay unless proved false below

    if (len(line) < 5):
        if args.verbose:
            print(line + " Skipping, Too Short, or no extension.")
        NameOK = False
        NumberOfSkipped += 1
        continue

# find ".ZXM"
    DotPos = 0
    for x in line:
        if x == '.':
            break
        DotPos += 1
            
    if (DotPos < 1 or DotPos > 8):
        if args.verbose :
            print(line + " skipping, doesn't look like an 8.3 filename ")
        NameOK = False
        NumberOfSkipped += 1
        continue

    Fname = line[0:DotPos+4]
  #  print(" ectracted filename is " + Fname)
    Length = len(Fname)
    
    if Length > 12:
        if args.verbose :
            print(line + " skipping, doesn't look like an 8.3 filename ")
        NameOK = False
        NumberOfSkipped += 1
        continue

    
    
    if (Fname[-4:Length]) != ".ZXM" :
        if args.verbose:
            print(line + " skipping, extension must be .ZXM ")
        NameOK = False
        NumberOfSkipped += 1
        continue

    
    

    #check for valid characters, alphanumeric and period only
    for s in Fname[0:-4]:
        c = ord(s)
       
        if not (( c > 64 and c < 91 ) or ( c > 47 and c < 58 )):
            NameOK = False
            break
        
    
    if NameOK == False:
        if args.verbose:
            print(line + " skipping, conatins invalid character " + s)
        NumberOfSkipped += 1
        continue
    
    
   
    if args.verbose:
        print("adding " + line + " to output file. ", (NumberOfEntries + 1), " entries created.")

# add to outfile except last character
    FirstByte = True
    for s in Fname[0:-1]:
        #convert byte to zx81 code
        c = ord(s)
        if (c > 64 and c < 91):
            c -= 27
        elif (c > 47 and c < 58 ):
            c -= 20
        elif (c == 46 ):
            c = 27
        if FirstByte:
            FirstByte = False
            Out.write(bytes([c+64]))        # set bit 6 first byte only
            ByteCount += 1
        
        else:    
            Out.write(bytes([c]))
            ByteCount += 1
        

    #last byte should be zx81 M with bit 7 set

    Out.write(bytes([178]))
    ByteCount += 1
    NumberOfEntries += 1

    #lets try and open the actual ZXM file to retrieve the
    #length data from the last block
   
    ZXMExsists = False
    if os.path.exists(Fname):
        ZXMExsists = True
    if args.verbose:
        print( Fname + " exists")

    #try to open ZXM file
    if ZXMExsists:    
        try:
            ZXMin = open(Fname , "rb")  # Open in binary read mode
              
        except FileNotFoundError:
            if args.verbose:
                print(f"Error: The file {file_name} was not found.")
           # sys.exit(1) # Exit with an error code (1 typically indicates an error)
        except Exception as e:
            if args.verbose:
                print(f"An unexpected error occurred: {e}")
           # sys.exit(1) # Exit with an error code for other exceptions

    #get length of file,then seek to end minus 255
    if ZXMExsists:
        fifts = 0
        ZXMSize = os.path.getsize(Fname)
        ZXMin.seek(ZXMSize - 256)
        
        aa = ord(ZXMin.read(1))
        bb = ord(ZXMin.read(1)) 
        cc = ord(ZXMin.read(1))

       # print( aa , " ", bb, " ", cc)

        fifts = aa + bb * 256 + cc * 65536

        n = fifts / 50
      
        m = int(n/60)
        s = int(n-m*60)
        ms = str(m)
        if len(ms)<2:
            ms = " "+ms
        ss = str(s)
        if len(ss)<2:
            ss = "0"+ss
        
        TimeString = ms+":"+ss
        if len(TimeString) != 5:
            TimeString = "--:--"
                
    if not ZXMExsists:
        TimeString = "--:--"
        
    for x in TimeString:
        Out.write(bytes([ZX81Char[ord(x)]]))
        ByteCount += 1    

    

#lets see if their is text associated with this filename
    HashPos = 0
    for x in line:
        if x == '#':
            break
        HashPos += 1
            
    if (HashPos == len(line)):
        if args.verbose :
            print(line + " no text to foll0w")
        continue

#pobably some text to follow
#max 256 characters
    OutText = " "
    LineLength = len(line)
    TextLength = LineLength - HashPos
#omit the hash character 
    TrackText = line[(-TextLength) + 1:len(line)]
  #limit text to 64 characters
    
    if len(TrackText) > 257:
        TrackText = TrackText[0:256]


    Out.write(bytes([254]))     #FE in playlist signifies text to follow
    ByteCount += 1
    for x in TrackText[0:len(TrackText) - 1]:
        if args.verbose:
            OutText = OutText + x
        Out.write(bytes([ZX81Char[ord(x)]]))
        ByteCount += 1
#and last character in message
    if args.verbose:
        OutText = OutText + TrackText[-1:len(TrackText)]
        
    Out.write(bytes([ZX81Char[(ord(TrackText[-1:len(TrackText)]))]+128]))
   
    ByteCount += 1          

    if args.verbose:
        print("**"+OutText + "**"  )
        

    
    
    
#terminate OutFile with $FF zx81 will see this as end of playlist.

    
    
Out.write(bytes([255]))
ByteCount += 1

if NumberOfSkipped != 0:
    print(NumberOfSkipped, " lines skipped, due to errors, use -v ")
          
print("Playlist " + OutFile + " created with ", NumberOfEntries, " Entries." )
if ByteCount > 8179:
    print("STOPPED BECAUSE OUTPUT FILE IS FULL.")
if NumberOfEntries == 777:
    print("\n Lucky 7's .... You Win ... NOTHING !!! " )

if args.verbose:
    print(ByteCount , " bytes in output file")

In.close()
Out.close()

        

    
   

  
