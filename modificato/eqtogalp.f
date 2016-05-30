                   subroutine eqtogalp(rh, rm, rs, isign, dd, dm, ds,
     +                                 glon, glat, pa)
*
*     converts J2000 equatorial coordinates of a source to galactic 
*     coordinates 'glon' and 'glat' in degrees and calculates position 
*     angle of a galactic parallel (direction of increasing longitude)
*     at the source measured eastward from the north.
*     For general formulae, see K. Yokoyama in 'Chikyu Kaiten' (1979).
*
      implicit real * 8 (a - h, o - z)
      implicit integer (i - n)
*
      data pi /3.14159265359d0/
*
      data omh, omm /18.0d0, 51.4d0/
      data gld, glm /32.0d0, 56.0d0/
      data aid, aim /62.0d0, 52.0d0/
*     values brought from RIKANENPYOU 1993.
*
      data small /1.0d-10/
*
      rad = pi / 180.0d0
*
      ra = rad * 15.0d0 * (rh + rm / 60.0d0 + rs / 3600.0d0)
      dc = isign * rad * (dd + dm / 60.0d0 + ds / 3600.0d0)
*
      omega = rad * 15.0d0 * (omh + omm / 60.0d0)
      ai = rad * (aid + aim / 60.0d0)
*
      glon0 = gld + glm / 60.0d0
*
      cbcl = cos(dc) * cos(ra - omega)
      cbsl = sin(dc) * sin(ai) + cos(dc) * sin(ra - omega) * cos(ai)
      sb   = sin(dc) * cos(ai) - cos(dc) * sin(ra - omega) * sin(ai)
*
      rlat = asin(sb)
      rlon = atan2(cbsl, cbcl) + rad * glon0
*
      ddc = pi / 2.0d0 - abs(dc)
      dlt = pi / 2.0d0 - abs(rlat)

      if (ddc .lt. small) then
        write (*, *) 'eqtogalp : source at pole.'
        write (*, *) '           declination = ', dc / rad
        write (*, *) '           P.A. is set to 0.'
        pa = 0.0d0
      else if (dlt .lt. small) then
        write (*, *) 'eqtogalp : source at Galactic pole.'
        write (*, *) '           latitude = ', rlat / rad
        write (*, *) '           P.A. is set to 0.'
        pa = 0.0d0
      else
        cphi = (cos(ai) - sin(dc) * sin(rlat)) / (cos(dc) * cos(rlat))
        sphi = cos(ra - omega) * sin(ai) / cos(rlat)
        phi = atan2(sphi, cphi)
        pa = 90.0d0 - phi / rad 
      endif
*
      glat = rlat / rad
      glon = rlon / rad 
*
      if (glon .lt. 0.0d0) then
        glon = glon + 360.0d0
      endif
*
      if (glat .gt. 90.0d0 .or. glat .lt. -90.0d0) then
        write (*, *) 'eqtogalp : glat out of range. ', glat
        stop
      else if (glon .lt. 0.0d0 .or. glon .gt. 360.0d0) then
        write (*, *) 'eqtogalp : glon out of range. ', glon
        stop
      endif
*
      return
      end







