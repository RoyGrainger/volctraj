; Routine to test volcano trajectory code
; 03 Aug 2015 RGG Created
; 04 Aug 2015 CJB encorporating volc_location.pro



  volcano = 'SARY' ; code for Sarachev

  position = volc_location(volcano)  ; Outputs a structure, position = {lat(deg N), lon(deg E), alt(m)}

  Traj_alt_grid = [1500, 5000, 10000] ; heights at which trajectories are available
  Trajectory, Volcano, Traj_Alt_Grid, Start_DATTIM, Start_Position, End_DATTIM, End_Position
  Stop

End
