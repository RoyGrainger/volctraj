;; Program to calculate the straight line distance between two points, provided latitude, longitude and altitude

;; Inputs - P1 = {lat, lon, alt} - output from trajectory.pro
;;          P2 = {lat, lon, alt} - reference point

;; Perhaps add a keyword for radius of the earth

;; 150915 - CJB start


FUNCTION spdist, P1, P2

  ;distance R is the radius of the Earth plus the altitude
  alt1 = 6370E3 + P1.alt
  alt2 = 6370E3 + P2.alt
  ;converting from degrees to radians
  lat1 = P1.lat*(!PI/180)
  lat2 = P2.lat*(!PI/180)
  lon1 = P1.lon*(!PI/180)
  lon2 = P2.lon*(!PI/180)

  dist = SQRT(ABS(alt1^2 + alt2^2 - 2*alt1*alt2*(cos(lat1)*cos(lat2)*cos(lon1 - lon2) + sin(lat1)*sin(lat2))))

  RETURN, dist
END
