                    subroutine solmot(ras, dec, dist, spm, aspm, dspm)
*
*     calculates solar motion effect in RA 'aspm' (mas / year), in Dec
*     'dspm' (mas / year) and in absolute magnitude 'spm' (mas / year)
*     of an object with RA 'ras' (degree), Dec 'dec' (degree) and
*     distance 'dist' (kpc).
*
      implicit real * 8 (a - h, o - z)
      implicit integer (i - n)
*
C   standard solar motion
C            data alpapex, delapex, vsolar /271.0d0, 29.0d0, 19.5/
C  John Ball's 1960 Solar Motion
C           data alpapex, delapex, vsolar /270.0d0, 30.0d0, 20.0/
C Dehnen and Binney (1998) solar motion
C          data alpapex, delapex, vsolar /251.0d0, 10.0d0, 13.4/
C Schoenrich et al. 2010 (revised Hipparcos Solar Motion)
      data alpapex, delapex, vsolar /267.0d0, 23.0d0, 18.0/
*
      data pi /3.14159265359d0/
*
      rad = pi / 180.0d0
*
      aa = rad * alpapex
      da = rad * delapex
      ra = rad * ras
      dc = rad * dec
      am = aa - ra
      cosda = cos(da)
      sinda = sin(da)
      cosdc = cos(dc)
      sindc = sin(dc)
      sinam = sin(am)
      cosam = cos(am)
*
      spm = 0.2108d0 * vsolar / dist
*
      aspm = -spm * cosda * sinam
      dspm = -spm * (cosdc * sinda - sindc * cosda * cosam)
*
      return
      end
