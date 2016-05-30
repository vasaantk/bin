                    subroutine flatrot(rh, rm, rs, isign, 
     +                                 dd, dm, ds, vr, 
     +                                 gl, glat, rc, pa, 
     +                                 rd1, vt1, pm1, 
     +                                 rd2, vt2, pm2, istat)
*
*     estimates Galactocentric distance 'rc' (kpc), position angle 'pa'
*     (degree) of the Galactic parallel, distance 'rd' (kpc) from the
*     Sun, velocity perpendicular to the line of sight 'vt' (km / sec) 
*     and proper motion 'pm' (mas / year) of a Galactic plane object 
*     with RA(J2000) 'rh, rm, rs', Dec(J2000) 'isign, dd, dm, ds' and 
*     peak LSR radial velocity 'vr' (km / sec) on the basis of the 
*     flat circular rotation model of the Galaxy. Position angle 'pa'
*     of the Galactic parallel (direction of increasing galactic 
*     longitude) at the source is measured eastward from the north.
*     On the other hand, 'vt' and 'pm' are positive if the object 
*     moves towards direction of decreasing galactic longitude. 
*     Distance to the Galactic Center 'R0' (kpc) and rotational 
*     velocity 'V0' (km / sec) at the solar circle are assumed.
*     istat : 
*        0  : normal
*        1  : warning, galactic latitude might be too large for the 
*             flat circular rotation model
*        2  : radial velocity is out of applicability of the flat
*             circular rotation model 
*
      implicit real * 8 (a - h, o - z)
*
C standard GR
C        data R0, V0 /8.5d0, 220.0d0/   
C  M.R. (2009) GR
C      data R0, V0 /8.4d0, 254.0d0/
C  B.A. (2011) GR (to use with the Schoenrich et al. (2010) solar motion)
C      data R0, V0 /8.3d0, 239.0d0/
C  M.R. (2014) B1 solution (to use with the Schoenrich et al. (2010) solar motion)
      data R0, V0 /8.33d0, 243.0d0/
C
      data pi /3.141592654d0/
*
      write (*, *)
      write (*, *) 'Assumed R0 = ', R0, ' kpc and V0 = ', V0, ' km/s'
      write (*, *)
*
      rad = pi / 180.0d0
*
      call eqtogalp(rh, rm, rs, isign, dd, dm, ds, gl, glat, pa)
*
      if (gl .lt. 0.0d0) then
        gl = gl + 360.0d0
      endif
*
      rgl = rad * gl
      sgl = sin(rgl)
      cgl = cos(rgl)
*
      rc = R0 * V0 * sgl / (vr + V0 * sgl)
*       *** distance of the object from the Galactic center ***
*
      if (abs(glat) .le. 5.0d0) then
        istat = 0
      else
        istat = 1
*       WARNING : the galactic latitude might be too large for the 
*                 flat circular rotation model.
      endif
*
      v1 = V0 * (1.0d0 - abs(sgl))
      v2 = V0 * abs(sgl)
      v3 = 0.0d0
*
      if (((gl .ge.   0.0d0 .and. gl .lt.  90.0d0) .and.
     +         (vr .gt. v1 .or. vr .lt. -v2)) .or.
     +    ((gl .ge.  90.0d0 .and. gl .lt. 180.0d0) .and.
     +         (vr .gt. v3 .or. vr .lt. -v2)) .or.
     +    ((gl .ge. 180.0d0 .and. gl .lt. 270.0d0) .and.
     +         (vr .gt. v2 .or. vr .lt.  v3)) .or.
     +    ((gl .ge. 270.0d0 .and. gl .lt. 360.0d0) .and.
     +         (vr .gt. v2 .or. vr .lt. -v1))) then
        istat = 2
*       The flat circular rotation model is inadequate for this case.
*       Setting dummy values
        rd1 = 9999.99d0
        vt1 = 9999.99d0
        pm1 = 9999.99d0
        rd2 = 9999.99d0
        vt2 = 9999.99d0
        pm2 = 9999.99d0
      else if (rc .ge. R0) then
        rd1 = R0 * cgl + sqrt(rc * rc - R0 * R0 * sgl * sgl)
        vt1 = - V0 * ((R0 - rc) * cgl - rd1) / rc
        pm1 = 0.2108 * vt1 / rd1
*       Setting dummy values
        rd2 = 9999.99d0
        vt2 = 9999.99d0
        pm2 = 9999.99d0
      else
        rd1 = R0 * cgl - sqrt(rc * rc - R0 * R0 * sgl * sgl)
        rd2 = R0 * cgl + sqrt(rc * rc - R0 * R0 * sgl * sgl)
        vt1 = - V0 * ((R0 - rc) * cgl - rd1) / rc
        vt2 = - V0 * ((R0 - rc) * cgl - rd2) / rc
        pm1 = 0.2108 * vt1 / rd1
        pm2 = 0.2108 * vt2 / rd2
      endif
*
      return
      end








