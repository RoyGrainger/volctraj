;; Variation of trajectory.pro, but for the times when the required height exactly matches that at whcih the trajectory model was run. In this case, only need to read off the position a given time later

;; as of 17th September, only fed one height at a time -- CJB

FUNCTION single_trajectory, volcano, traj_alt_grid, Start_DATTIM, Start_Position, End_DATTIM, End_Position

filename = volcano+'/'+volcano+'_'+start_DATTIM.date+'_'+string(start_position.alt, Format='(I5.5)')+'m.txt'
load_traj, filename, data


year = REFORM(data[2,*])
month = REFORM(data[3,*])
day = REFORM(data[4,*])
hour = REFORM(data[5,*])
minute = REFORM(data[6,*])
track = REFORM(data[0,*])
age = REFORM(data[8,*])   ;age of trajectory in hours

lat = REFORM(data[9,*])
lon = REFORM(data[10,*])
alt = REFORM(data[11,*])

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

end_lat = end_position_edit(lat, hour, day, {start: {day: s_day, hours: s_hour, minutes: s_min}, final: {day: e_day, hours: e_hour, minutes: e_min}}, traj_data)
end_lon = end_position_edit(lon, hour, day, {start: {day: s_day, hours: s_hour, minutes: s_min}, final: {day: e_day, hours: e_hour, minutes: e_min}}, traj_data)
end_alt = end_position_edit(alt, hour, day, {start: {day: s_day, hours: s_hour, minutes: s_min}, final: {day: e_day, hours: e_hour, minutes: e_min}}, traj_data)

RETURN, {lat: end_lat, lon: end_lon, alt: end_alt}

END
