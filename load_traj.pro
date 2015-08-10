;;To read in trajectory data
;061815 CJB create

PRO load_traj,filename,data

openr, lun, '$trajdir/'+filename, /get_lun 

line = ''
l=0

WHILE NOT EOF(lun) DO BEGIN

   ;;Read one line at a time
   readf, lun, line

   ;;Index line, +1 as want to start reading data the line after this
   l = l+1       

   ;;Does the current line match the last one we don't want?
   IF STRCMP(line,'     1 PRESSURE',15) EQ 1 THEN BEGIN

      ;;If yes, read the rest of the file to variable "result". NOTE filename height extension is 5 characters, so must include 0 if 9999m or less
      result = READ_ASCII('$trajdir/'+filename, DATA_START = l) 

   ENDIF

ENDWHILE

data = result.field01
free_lun, lun

END
