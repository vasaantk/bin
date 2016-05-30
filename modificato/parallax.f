                    subroutine parallax(ras, dec, dist, slong,
     +                                  cdra, ddec)
*
*     calculates angular displacements in right ascention and declination
*     directions 'cdra' and 'ddec', respectively in milliarcsecond of a 
*     source with right ascention 'ras' degree, declination 'dec' degree 
*     and distance 'dist' kpc due to the annual parallax when the Sun's 
*     ecliptic longitude is 'slong' degree. 
*     As the obliquity 'epcilon', the J2000 value is adopted for simplicity.
*
      implicit real * 8 (a - h, o - z)
      implicit integer (i - n)
*
      data pi /3.14159265359d0/
      data epcd, epcm, epcs /23.0d0, 26.0d0, 21.448d0/
*
      rad = pi / 180.0d0
      epcilon = epcd + epcm / 60.0d0 + epcs / 3600.0d0
*
      ra = rad * ras
      dc = rad * dec
      sl = rad * slong
      ep = rad * epcilon
*
      aprlx = 1.0d0 / dist
*
      cosr = cos(ra)
      sinr = sin(ra)
      cosd = cos(dc)
      sind = sin(dc)
      coss = cos(sl)
      sins = sin(sl)
      cose = cos(ep)
      sine = sin(ep)
*
      cdra = aprlx * (-sinr * coss + cose * cosr * sins)
      ddec = aprlx * (-sind * cosr * coss - cose * sind * sinr * sins
     +               + sine * cosd * sins)
*
      return
      end
