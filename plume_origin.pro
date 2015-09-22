;; Take a point in a plume (retrieved by IASI) and use HYSPLIT model runs to establish when it was
;; erupted and at what injection altitude.

;; 16th September 2015 - CJB start




  reference_position = {lat: 50, lon:150, alt: 3000}

  volcano = 'SARY' ; code for Sarachev

  position = volc_location(volcano)  ; Outputs a structure, position = {lat(deg N), lon(deg E), alt(m)}

  ;Start_DATTIM = {date:'090611',time:'1200'}

  date = ['090611','090611','090611','090611']
  time = ['0500','0800','0900','1500']

  End_DATTIM = {date:'090612',time:'1200'}  

  Traj_alt_grid = [1500, 4000, 7000, 10000] ; heights at which trajectories are available

  req_alt = [2000, 4000, 6000, 8000, 10000]  ;heights want to 'retrieve'
  
  ;;Checking whether any of the start altitudes are the same as the trajectory grid
  subreq = intarr(n_elements(req_alt))
  subtraj = intarr(n_elements(traj_alt_grid))
  match2, req_alt, traj_alt_grid, subreq, subtraj
  n = where( subreq NE -1)
  ;;index is a binary array, 1 for elements of req_alt that match a trajectory, 0 otherwise
  index = intarr(n_elements(req_alt))
  index[n] = 1

  dist = dblarr(n_elements(date), n_elements(req_alt))

  FOR n = 0, n_elements(date) - 1 DO BEGIN
     start_DATTIM = {date: date[n], time: time[n]}
     FOR i = 0, n_elements(index) - 1 DO BEGIN

        start_position = { lat: position.lat, lon: position.lon, alt: req_alt[i] }

        IF index[i] EQ 0 THEN end_position = trajectory( Volcano, Traj_Alt_Grid, Start_DATTIM, Start_Position, End_DATTIM) $
        ELSE end_position = single_trajectory( Volcano, Traj_Alt_Grid, Start_DATTIM, Start_Position, End_DATTIM)

        dist[n,i] = spdist(end_position, reference_position)

     ENDFOR
  ENDFOR

  closest = WHERE(dist EQ min(dist))

 ; print, 'The closest point at time '+end_dattim.time+' on '+end_dattim.date+' was erupted at '+start_dattim.time+' on '+start_dattim.date+' at an altitude of '+STRING(req_alt[closest])+'m.'

END
