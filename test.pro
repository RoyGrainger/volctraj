; Routine to test volcano trajectory code
; 03 Aug 2015 RGG Created
; 04 Aug 2015 CJB encorporating volc_location.pro
; 05 Aug 2015 CJB encorporating trajectory.pro
; 07 Aug 2015 CJB adding capability for multiple starting altitudes


  volcano = 'SARY' ; code for Sarachev

  position = volc_location(volcano)  ; Outputs a structure, position = {lat(deg N), lon(deg E), alt(m)}

  Traj_alt_grid = [1500, 5000, 10000] ; heights at which trajectories are available


  start_position = { lat: position.lat, lon: position.lon, alt: [1600, 2500, 4000, 7500] }
  Start_DATTIM = {date:'090611',time:'1200'}
  End_DATTIM = {date:'090612',time:'1200'}

;;NOTE: end time must be less than 24 hours after the start time, as that's how long the trajectories were run for

  end_position = trajectory( Volcano, Traj_Alt_Grid, Start_DATTIM, Start_Position, End_DATTIM)

End
