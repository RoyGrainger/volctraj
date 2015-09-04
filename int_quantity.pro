;; Function to interpolate the quantity between two measured heights, at the assigned altitude

;; 12th August 2015 CJB - start
;; 2nd September 2015 CJB - include UNIQ function

;; Inputs:  quant = lat/lon/alt - quantity want to interpolate
;;          heights = array of trajectory start heights, lying either side of the input start heights
;;          start_alt = array of inputted start altitudes
;;          traj_alt_grid = array of trajectory starting altitudes
;; Outputs: int_quant = array of interpolated quantities to output [x,r] [tranjectory points (same as quant input), number of starting altidues]


FUNCTION int_quantity, quant, heights, traj_alt_grid, start_alt
  
  int_quant = fltarr(n_elements(quant[*,0]), n_elements(start_alt))

  q = intarr(n_elements(start_alt))   
  FOR n = 0,n_elements(start_alt)-1 DO q[n] = max(where(traj_alt_grid LT start_alt[n])) < (n_elements(traj_alt_grid)-2)

  ;If all the starting altitudes lie between the same two trajectories
  IF n_elements(UNIQ(q)) EQ 1 THEN BEGIN

     FOR r = 0, n_elements(start_alt) - 1 DO BEGIN
        FOR x = 0, n_elements(quant[*,0])-1 DO int_quant[x,r] = INTERPOL(quant[x,*], heights, start_alt[r])
     ENDFOR

  ENDIF ELSE BEGIN

     loc = q[UNIQ(q)]    ;position in the traj_alt array of the required traj heights
     tmp_quant = fltarr(n_elements(quant[*,0]),2) ;temporary variable redefined each time, as the two
                                                  ;values of the quantity interpolating between
     ;;loop over the number of different pairs of starting altitudes
     FOR l = 0, n_elements(loc)-1 DO BEGIN
        int_heights = [traj_alt_grid[loc[l]], traj_alt_grid[loc[l]+1]]
        tmp_quant[*,0] = quant[*,2*l]
        tmp_quant[*,1] = quant[*,(2*l)+1]
        FOR r = 0, n_elements(start_alt) - 1 DO BEGIN
           IF start_alt[r] GE int_heights[0] AND start_alt[r] LT int_heights[1] THEN BEGIN
              FOR x = 0, n_elements(quant[*,0])-1 DO int_quant[x,r] = INTERPOL(tmp_quant[x,*], int_heights, start_alt[r])
           ENDIF
        ENDFOR
     ENDFOR
  ENDELSE
RETURN, int_quant

END
