;;function to output the end position of the trajectory
;; 11th August 2015 CJB - open

;; Call for each quantity latitude, longitude and altitude, for every start height

;;Inputs:  quant = latitudes/longitudes/altitudes interpolated to required start heights, array size (no. latitude elements, no. starting altitudes)
;;         traj = location in the data files of the trajectory required by start time, vector of array positions of required track
;;         hour = array of times in hours at which the quantities have been measured
;;         day = array of days (dates) at which the quantities have been measured
;;         time = times required, structure (start: {day: int, hours: int, minutes: int}, final: {day: int, hours: int, minutes: int})
;;Outputs: end_position = final lat/lon/alt of parcel at end time required

;; 110915 CJB - extent to include times greater than 24 hours after the initial injection


FUNCTION end_position_edit, quant, hour, day, time, traj
  
   ;;Final output will have the same number of elements as the number of starting heights
   end_pos = fltarr(n_elements(quant[0,*]))

   ;;extract track number 'traj' from the data set int_lat, int_lon and int_alt, and from the time arrays,
   ;;remembering that here end_date = start_date

   req_quant = quant[traj,*]


   ;;If the end time is a whole number of hours later
   IF time.final.minutes EQ 0 THEN BEGIN      

      ;;Now find where req_hour EQ the end time
      f = where(day[traj] EQ time.final.day AND hour[traj] EQ time.final.hours)
      FOR x = 0, n_elements(quant[0,*])-1 DO end_pos[x] = req_quant[f,x]
      
   ENDIF ELSE BEGIN
   
      ;;For when the end minute is not 0
      f = where(day[traj] EQ time.final.day AND hour[traj] EQ time.final.hours)
      g = where(day[traj] EQ time.final.day AND hour[traj] EQ time.final.hours+1)

      FOR m = 0, n_elements(quant[0,*])-1 DO end_pos[m] = INTERPOL([req_quant[f,m],req_quant[g,m]], [0,60], time.final.hours)

   ENDELSE

   RETURN, end_pos

END
