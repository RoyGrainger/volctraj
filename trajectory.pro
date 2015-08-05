;;function to read trajectory data on a given day, interpolate to a required height and return location a specified time later
;; 5th August 2015 CJB start - extracts end position if the end time is the same day, and 0000, 0600, 1200 or 1800

;;Inputs: volcano = volcano code, string
;;        traj_alt_grid = altitude grid of data set
;;        start_DATTIM = start date and time of the trajectory, structure {date(string, YYMMDD), time(string, HHMM)}
;;        start_position = position of volcano, and altitude of initial injection, structure {lat, lon, alt}
;;        end_DATTIM = date and time at which position of air parcel is needed, structure {date(string, YYMMDD), time(string, HHMM)}
;;Output: end_position = location of air parcel end_DATTIM later, structure {lat, lon, alt}

FUNCTION trajectory, volcano, Traj_Alt_Grid, Start_DATTIM, Start_Position, End_DATTIM, End_Position

st_height = start_position.alt
h = intarr(2)

;;Reading in the trajectories data
data = dblarr(2,13, 125) ;;2 = number of heights, always 2 as want to interpolate between 2 levels
                         ;;13 columns outputted by HYSPLIT
                         ;;125 rows outputted by HYSPLIT for 1 day, tracks every 6 hours

FOR a = 0, n_elements(traj_alt_grid)-2 DO BEGIN

   h[0] = traj_alt_grid[a]
   h[1] = traj_alt_grid[a+1]

   IF st_height GE h[0] AND st_height LT h[1] THEN BEGIN

      FOR n = 0,1 DO BEGIN

         ;; NOTE filename height extension is 5 characters, so must include 0 if 9999m or less
         IF h[n] LT 10000 THEN openr, lun, '/home/jupiter/eodg2/birch/Trajectories/Fine/'+volcano+'/'+volcano+'_'+start_DATTIM.date+'_0'+strtrim(h[n],1)+'m.txt', /get_lun $
         ELSE openr, lun, '/home/jupiter/eodg2/birch/Trajectories/Fine/'+volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+strtrim(h[n],1)+'m.txt', /get_lun

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
               IF h[n] LT 10000 THEN result = READ_ASCII('/home/jupiter/eodg2/birch/Trajectories/Fine/'+volcano+'/'+volcano+'_'+start_DATTIM.date+'_0'+strtrim(h[n],1)+'m.txt', DATA_START = l) $
               ELSE result = READ_ASCII('/home/jupiter/eodg2/birch/Trajectories/Fine/'+volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+strtrim(h[n],1)+'m.txt', DATA_START = l)

            ENDIF

         ENDWHILE

         ;;Will be a structure of one field, so reasign to an array
         data[n,*,*] = result.field01
         free_lun, lun

      ENDFOR
      
      ;;Outputting the values of traj_alt_grid that the required starting height falls between
      heights = [h[0],h[1]]
      
   ENDIF

ENDFOR

;Print message if the requested start height is smaller than the lowest measured height, or higher than the highest
IF st_height GT traj_alt_grid[n_elements(traj_alt_grid)-1] OR st_height LT traj_alt_grid[0] THEN print,'Requested initial height is outside the calculable range'

;;Now, want to extract the collumns into separate variables, row per height
;;Given we've only loaded two heights over the same time frame, all time arrays will be the same for both files

year = intarr(n_elements(data(0,0,*)))
month = intarr(n_elements(data(0,0,*)))
day = intarr(n_elements(data(0,0,*)))
hour = intarr(n_elements(data(0,0,*)))
minute = intarr(n_elements(data(0,0,*)))
lat = dblarr(n_elements(data(0,0,*)),2)
lon = dblarr(n_elements(data(0,0,*)),2)
alt = dblarr(n_elements(data(0,0,*)),2)
track = intarr(n_elements(data(0,0,*)))
age = intarr(n_elements(data(0,0,*)))

year = REFORM(data[0,2,*])
month = REFORM(data[0,3,*])
day = REFORM(data[0,4,*])
hour = REFORM(data[0,5,*])
minute = REFORM(data[0,6,*])
track = REFORM(data[0,0,*])
age = REFORM(data[0,8,*])    ;age of trajectory in hours

FOR h = 0, 1 DO BEGIN
   lat[*,h] = data[h,9,*]
   lon[*,h] = data[h,10,*]
   alt[*,h] = data[h,11,*]
ENDFOR

;; want to interpolate between latitudes, longitudes, and altitudes to the same amount that the input start height is between heights[0] and heights[1]

int_lat = fltarr(n_elements(lat[*,0]))
int_lon = fltarr(n_elements(lat[*,0]))
int_alt = fltarr(n_elements(lat[*,0]))

FOR x = 0, n_elements(lat[*,0])-1 DO int_lat[x] = INTERPOL(lat[x,*], heights, st_height)
FOR y = 0, n_elements(lon[*,0])-1 DO int_lon[y] = INTERPOL(lon[y,*], heights, st_height)
FOR z = 0, n_elements(alt[*,0])-1 DO int_alt[z] = INTERPOL(alt[z,*], heights, st_height)

;; now want to read the position at a future time

st_date = start_DATTIM.date
    s_year = FIX(STRMID(st_date,0,2))
    s_month = FIX(STRMID(st_date,2,2))
    s_day = FIX(STRMID(st_date,4,2))
st_time = start_DATTIM.time
    s_hour = FIX(STRMID(st_time,0,2))
    s_min = FIX(STRMID(st_time,2,4))
en_date = end_DATTIM.date
    e_year = FIX(STRMID(en_date,0,2))
    e_month = FIX(STRMID(en_date,2,2))
    e_day = FIX(STRMID(en_date,4,2))
en_time = end_DATTIM.time
    e_hour = FIX(STRMID(en_time,0,2))
    e_min = FIX(STRMID(en_time,2,4))
    
;;if hour is 00, 06, 12, or 18, and min is 0, can simply read off the answer, otherwise more interpolating is needed
;;Also, if st_date = en_date, again it's simple to read off, but if it's a different day then can't just add on the difference in hours

IF e_hour EQ 0 OR e_hour EQ 6 OR e_hour EQ 12 OR e_hour EQ 18 THEN BEGIN

   IF STRCMP(st_date,en_date,6) EQ 1 THEN BEGIN
      
      IF s_min EQ 0 THEN BEGIN
         
         start = where(year[*,0] EQ s_year AND month[*,0] EQ s_month AND day[*,0] EQ s_day AND hour[*,0] EQ s_hour)
         
         ;;When there is more than one track registering at a particular time, want the youngest one which is always the last one
         start = max(start) 
         
         ;;The track that starts at this time will be one index larger than this value
         traj = track[start] + 1
         
         traj_data = where(track EQ traj)
      
         ;;extract track number 'traj' from the data set int_lat, int_lon and int_alt, and from the time arrays, remembering that here end_date = start_date and min = 0
         req_lat = int_lat[traj_data]
         req_lon = int_lon[traj_data]
         req_alt = int_alt[traj_data]
         req_hour = hour[traj_data]
      
         ;;Now find where req_hour EQ the end time
         f = where(req_hour EQ e_hour)
         end_lat = req_lat[f]
         end_lon = req_lon[f]
         end_alt = req_alt[f]

         ;;return the end position
         end_position = {lat: end_lat, lon: end_lon, alt: end_alt}
      
      ENDIF

   ENDIF

ENDIF


RETURN, end_position
END
