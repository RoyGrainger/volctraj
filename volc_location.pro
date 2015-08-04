function volc_location,volc_code,position
; Returns location and height of volcano
; 3 Aug 2015 RGG first attempt
; 3 Aug 2015 CJB searching volcano_object for volcano code
  
;;Opens the new object volcano_object, which includes all data on volcanoes from the Global Volcanism Program database from the Smithsonian Institude
v = OBJ_NEW('volcano_object')

result = v -> search_name(volc_code,/ANY_POSITION)

  position = {lat: result.latitude, $   ; latitude in degrees decimal
              lon: result.longitude ,$   ; longitude in degrees decimal
              alt: result.elevation}     ; altitude in metres

  return,Position
end 
