                    subroutine eqtoecl(rh, rm, rs, isign, dd, dm, ds,
     +                                elon, elat)
*
*     converts the J2000 equatorial coordinates to the ecliptic 
*     coordinates 'elon' and 'elat' at J2000 in degrees. The J2000 
*     value of the obliquity 'epcilon' is adopted.
*
      implicit real * 8 (a - h, o - z)
      implicit integer (i - n)
*
      data pi /3.14159265359d0/
*
      data epcd, epcm, epcs /23.0d0, 26.0d0, 21.448d0/
      data small /1.0d-15/
*
      rad = pi / 180.0d0
      epcilon = epcd + epcm / 60.0d0 + epcs / 3600.0d0
*
      ra = rad * 15.0d0 * (rh + rm / 60.0d0 + rs / 3600.0d0)
      dc = isign * rad * (dd + dm / 60.0d0 + ds / 3600.0d0)
*
      ep = rad * epcilon
*
      cose = cos(ep)
      sine = sin(ep)
      cosr = cos(ra)
      sinr = sin(ra)
      cosd = cos(dc)
      sind = sin(dc)
*
      sinb = - sine * cosd * sinr + cose * sind
*
      beta = asin(sinb)
*
      cosb = cos(beta)
*
      if (abs(cosb) .le. small) then
        elam = 0.0d0
      else
        cosl = cosd * cosr / cosb
        sinl = (cose * cosd * sinr + sine * sind) / cosb
        elam = atan2(sinl, cosl)
      endif
*
      elon = elam / rad
      elat = beta / rad
*
      if (elon .lt. 0.0d0) then
        elon = elon + 360.0d0
      endif
*
      return
      end



