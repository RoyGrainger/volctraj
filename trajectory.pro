;;function to read trajectory data on a given day, interpolate to a required height and return location a specified time later
;; 5th August 2015 CJB start - extracts end position if the end time is the same day, and has an end time with 0 minutes past the hour
;; 6th August 2015 CJB - extended to include end times with non zero minutes, and next day end times
;; 7th August 2015 CJB - extended to accept a range of start alititudes 

;;Inputs: volcano = volcano code, string
;;        traj_alt_grid = altitude grid of data set
;;        start_DATTIM = start date and time of the trajectory, structure {date(string, YYMMDD), time(string, HHMM)}
;;        start_position = position of volcano, and altitude of initial injection, structure {lat (dbl), lon(dbl), alt(dbl array)}
;;        end_DATTIM = date and time at which position of air parcel is needed, structure {date(string, YYMMDD), time(string, HHMM)}
;;Output: end_position = location of air parcel end_DATTIM later, structure {lat (array), lon (array), alt (array)}

FUNCTION trajectory, volcano, traj_alt_grid, Start_DATTIM, Start_Position, End_DATTIM, End_Position

;;Reading in the trajectories data

q = intarr(4)   
FOR n = 0,3 do q[n] = max(where(traj_alt_grid LT start_position.alt[n])) < (n_elements(traj_alt_grid)-2)


;;If all of the starting altitudes fall between two model heights...
IF n_elements(UNIQ(q)) EQ 1 THEN BEGIN
   
   data = dblarr(2,13, 125) ;;2 = number of heights, always 2 as want to interpolate between 2 levels
                            ;;13 columns outputted by HYSPLIT
                            ;;125 rows outputted by HYSPLIT for 1 day, tracks every 6 hours
   
   filename1 = volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+string(traj_alt_grid[q], Format='(I5.5)')+'m.txt'					 
   filename2 = volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+string(traj_alt_grid[q+1], Format='(I5.5)')+'m.txt'					 
   load_traj, filename1, data_read1			 
   load_traj, filename2, data_read2		
   data[0,*,*] = data_read1  
   data[1,*,*] = data_read2 
   heights = [traj_alt_grid[q],traj_alt_grid[q+1]]

ENDIF ELSE BEGIN

   loc = q[UNIQ(q)]
   heights = intarr(n_elements(loc)*2)
   data = dblarr(n_elements(loc)*2,13, 125)

   FOR x = 0, n_elements(loc)-1 DO BEGIN

      filename1 = volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+string(traj_alt_grid[loc[x]], Format='(I5.5)')+'m.txt'					 
      filename2 = volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+string(Traj_Alt_Grid[loc[x]+1], Format='(I5.5)')+'m.txt'					 
      load_traj, filename1, data_read1			 
      load_traj, filename2, data_read2
      ;;must be 2*x to avoid overwriting, i.e. first loop write elements 0 and 1, 2nd 2 and 3
      data[(2*x),*,*] = data_read1
      data[((2*x)+1),*,*] = data_read2
      heights[2*x] = traj_alt_grid[loc[x]]
      heights[(2*x)+1] = traj_alt_grid[loc[x]+1]

   ENDFOR

ENDELSE

;Print message if the requested start height is smaller than the lowest measured height, or higher than the highest
IF max(start_position.alt) GT traj_alt_grid[n_elements(traj_alt_grid)-1] OR min(start_position.alt) LT traj_alt_grid[0] THEN print,'Requested initial height is outside the calculable range'

;;Now, want to extract the collumns into separate variables, row per height
;;Given we've only loaded two heights over the same time frame, all time arrays will be the same for both files

year = intarr(n_elements(data[0,0,*]))
month = intarr(n_elements(data[0,0,*]))
day = intarr(n_elements(data[0,0,*]))
hour = intarr(n_elements(data[0,0,*]))
minute = intarr(n_elements(data[0,0,*]))
lat = dblarr(n_elements(data[0,0,*]), n_elements(heights))
lon = dblarr(n_elements(data[0,0,*]), n_elements(heights))
alt = dblarr(n_elements(data[0,0,*]), n_elements(heights))
track = intarr(n_elements(data[0,0,*]))
age = intarr(n_elements(data[0,0,*]))

year = REFORM(data[0,2,*])
month = REFORM(data[0,3,*])
day = REFORM(data[0,4,*])
hour = REFORM(data[0,5,*])
minute = REFORM(data[0,6,*])
track = REFORM(data[0,0,*])
age = REFORM(data[0,8,*])    ;age of trajectory in hours

FOR h = 0, n_elements(heights)-1 DO BEGIN
   lat[*,h] = data[h,9,*]
   lon[*,h] = data[h,10,*]
   alt[*,h] = data[h,11,*]
ENDFOR

;; want to interpolate between latitudes, longitudes, and altitudes to the same amount that the input start height is
;; between heights[0] and heights[1], heights[2] and heights[3] etc.

int_lat = fltarr(n_elements(lat[*,0]), n_elements(start_position.alt))
int_lon = fltarr(n_elements(lat[*,0]), n_elements(start_position.alt))
int_alt = fltarr(n_elements(lat[*,0]), n_elements(start_position.alt))

tmp_lats = fltarr(n_elements(lat[*,0]),2)
tmp_lons = fltarr(n_elements(lat[*,0]),2)
tmp_alts = fltarr(n_elements(lat[*,0]),2)

FOR r = 0, n_elements(start_position.alt) - 1 DO BEGIN
   int_heights = [heights[2*r], heights[(2*r)+1]]
   tmp_lats[*,0] = lat[*,2*r]
   tmp_lats[*,1] = lat[*,(2*r)+1]
   FOR x = 0, n_elements(lat[*,0])-1 DO int_lat[x,r] = INTERPOL(tmp_lats[x,*], int_heights, start_position.alt[r])
   tmp_lons[*,0] = lon[*,2*r]
   tmp_lons[*,1] = lon[*,(2*r)+1]
   FOR y = 0, n_elements(lon[*,0])-1 DO int_lon[y,r] = INTERPOL(tmp_lons[y,*], int_heights, start_position.alt[r])
   tmp_alts[*,0] = alt[*,2*r]
   tmp_alts[*,1] = alt[*,(2*r)+1]
   FOR z = 0, n_elements(alt[*,0])-1 DO int_alt[z,r] = INTERPOL(tmp_alts[z,*], int_heights, start_position.alt[r])
ENDFOR

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
         

start = where(year EQ s_year AND month EQ s_month AND day EQ s_day AND hour EQ s_hour)
         
;;When there is more than one track registering at a particular time, want the youngest one which is always the last one
start = max(start) 
         
;;The track that starts at this time will be one index larger than this value
traj = track[start] + 1
        
traj_data = where(track EQ traj)

;;extract track number 'traj' from the data set int_lat, int_lon and int_alt, and from the time arrays, remembering that
;; here end_date = start_date and min = 0

req_lat = int_lat[*,traj_data]
req_lon = int_lon[*,traj_data]
req_alt = int_alt[*,traj_data]
req_hour = hour[traj_data]

;;If the end time is a whole number of hours later
IF s_min EQ 0 THEN BEGIN      

   ;;Now find where req_hour EQ the end time
   f = where(req_hour EQ e_hour)
   end_lat = req_lat[*,f]
   end_lon = req_lon[*,f]
   end_alt = req_alt[*,f]

   ;;return the end position
   end_position = {lat: end_lat, lon: end_lon, alt: end_alt}
      
ENDIF ELSE BEGIN

   ;;For when the end minute is not 0
   f = where(req_hour EQ e_hour)
   g = where(req_hour EQ e_hour+1)
   FOR m = 0, n_elements(start_position.alt)-1 DO BEGIN
      end_lat[m] = INTERPOL([req_lat[m,f],req_lat[m,g]], [0,60], e_min)
      end_lon[m] = INTERPOL([req_lon[m,f],req_lon[m,g]], [0,60], e_min)
      end_alt[m] = INTERPOL([req_alt[m,f],req_alt[m,g]], [0,60], e_min)
   ENDFOR
         
   ;;return the end position
   end_position = {lat: end_lat, lon: end_lon, alt: end_alt}

ENDELSE

RETURN, end_position

END
