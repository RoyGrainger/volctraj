;;function to read trajectory data on a given day, interpolate to a required height and return location a specified time later
;; 5th August 2015 CJB start - extracts end position if the end time is the same day, and has an end time with 0 minutes past the hour
;; 6th August 2015 CJB - extended to include end times with non zero minutes, and next day end times
;; 7th August 2015 CJB - extended to accept a range of start alititudes 
;; 2nd September 2015 CJB - added function int_quantity to speed up interpolation section

;;Inputs: volcano = volcano code, string
;;        traj_alt_grid = altitude grid of data set
;;        start_DATTIM = start date and time of the trajectory, structure {date(string, YYMMDD), time(string, HHMM)}
;;        start_position = position of volcano, and altitude of initial injection, structure {lat (dbl), lon(dbl), alt(dbl array)}git pull help
;;        end_DATTIM = date and time at which position of air parcel is needed, structure {date(string, YYMMDD), time(string, HHMM)}
;;Output: end_position = location of air parcel end_DATTIM later, structure {lat (array), lon (array), alt (array)}

FUNCTION trajectory, volcano, traj_alt_grid, Start_DATTIM, Start_Position, End_DATTIM, End_Position

;;Reading in the trajectories data

q = intarr(n_elements(start_position.alt))   
FOR n = 0,n_elements(start_position.alt)-1 DO q[n] = max(where(traj_alt_grid LT start_position.alt[n])) < (n_elements(traj_alt_grid)-2)


;;If all of the starting altitudes fall between two model heights...
IF n_elements(UNIQ(q)) EQ 1 THEN BEGIN
   
   data = dblarr(2,13, 125) ;;2 = number of heights, always 2 as want to interpolate between 2 levels
                            ;;13 columns outputted by HYSPLIT
                            ;;125 rows outputted by HYSPLIT for 1 day, tracks every 6 hours

   ;;All values of array q are the same so
   q = q[0]
   
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

int_lat = INT_QUANTITY(lat, heights, traj_alt_grid, start_position.alt)
int_lon = INT_QUANTITY(lon, heights, traj_alt_grid, start_position.alt)
int_alt = INT_QUANTITY(alt, heights, traj_alt_grid, start_position.alt)


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

;--> call end_position function
end_lat = end_position_edit(int_lat, hour, {start: {hours: s_hour, minutes: s_min}, final: {hours: e_hour, minutes: e_min}}, traj_data)
end_lon = end_position_edit(int_lon, hour, {start: {hours: s_hour, minutes: s_min}, final: {hours: e_hour, minutes: e_min}}, traj_data)
end_alt = end_position_edit(int_alt, hour, {start: {hours: s_hour, minutes: s_min}, final: {hours: e_hour, minutes: e_min}}, traj_data)

RETURN, {lat: end_lat, lon: end_lon, alt: end_alt}

END
