                    program frmodel
*
*     estimates values of galactocentric distance rc(kpc), velocity 
*     vt(km/sec) perpendicular to the line of sight and the proper 
*     motion gpm (mas/year) of a Galactic disk object of given celestial 
*     coordinates with given estimated distance to the object or by 
*     estimating the distance from the LSR radial velocity vr(km/sec).
*     A simple flat circular rotation model of the Galaxy is assumed 
*     with given values of the galactic center distance R0(kpc) and 
*     rotation velocity V0(km/sec) at the solar circle. 
*     Then parallax ellipse and movement of the object due to the
*     Solar Motion are estimated.
*
      implicit real * 8 (a - h, o - z)
*
      character*70 argm
      character raline * 70, decline * 70
      character ans * 1, asign * 1
      character arh * 3, arm * 3, add * 3, adm * 3
*
      dimension rd(2), vt(2), gpm(2)
*
      narg = iargc()
      if (narg.eq.4) then
      call getarg(1,argm)
      read(argm,'(A70)') raline
      print *, 'raline = ', raline
      call getarg(2,argm)
      read(argm,'(A70)') decline
      print *, 'decline = ', decline
      call getarg(3,argm)
      read(argm,'(A1)') ans
      print *, ans
      call getarg(4,argm)
      read(argm,'(e50.0)') rde
      print *, 'dist(kpc) = ', rde
      endif

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
      data zero /0.0d0/
      data nseg /24/
*
      open (11, file = 'galrot.dat')
      open (12, file = 'solmot.dat')
      open (13, file = 'paralx.dat')
      open (14, file = 'galsol.dat')
      open (15, file = 'combmt.dat')
      open (16, file = 'frmodel.gp')
*
      rad = pi / 180.0d0
*
      write (*, *) 'Galactic Rotation, Solar Motion  and Parallax'
      write (*, *)
      call inqradc(raline,decline,rh, rm, rs, isign, dd, dm, 
     + ds, ras, dec)
*
C      write (*, *) 'Do you have an estimated distance to the source?'
C     read (*, *) ans
*
      if (ans .ne. 'y' .and. ans .ne. 'Y') then
        write (*, *) 'Enter LSR velocity in km/sec : '
        read (*, *) vr
*
        call flatrot(rh, rm, rs, isign, dd, dm, ds, vr, gl, glat, 
     +       rc, pa, rd(1), vt(1), gpm(1), rd(2), vt(2), gpm(2),
     +       istat)
*
        sgl = sin(rad * gl)
*
        v1 = V0 * (1.0d0 - abs(sgl))
        v2 = V0 * abs(sgl)
        v3 = 0.0d0
*
        if (istat .eq. 1) then
          write (*, *) 'Warning : Galactic latitude of your source ',
     +          'seems too large to apply the flat rotation model.'
          write (*, *)
        else if (istat .eq. 2) then
          write (*, *) 'Sorry, the flat rotation model is inadequate ',
     +                 'for your source.'
          write (*, *) 'The model assumes LSR velocity range '
*
          if (gl .ge.   0.0d0 .and. gl .lt.  90.0d0) then
            write (*, *) '    from ', -v2, ' km / sec'
            write (*, *) '    to   ',  v1, ' km / sec'
          else if (gl .ge.  90.0d0 .and. gl .lt. 180.0d0) then
            write (*, *) '    from ', -v2, ' km / sec'
            write (*, *) '    to   ',  v3, ' km / sec'
          else if (gl .ge. 180.0d0 .and. gl .lt. 270.0d0) then
            write (*, *) '    from ',  v3, ' km / sec'
            write (*, *) '    to   ',  v2, ' km / sec'
          else if (gl .ge. 270.0d0 .and. gl .lt. 360.0d0) then
            write (*, *) '    from ', -v1, ' km / sec'
            write (*, *) '    to   ',  v2, ' km / sec'
          endif
*
          write (*, *) 'at this galactic longitude : ', gl
          stop
        endif
*
        write (*, '('' Galactic longitude and latitude = '', 2F7.2, 
     +              '' degrees'')') gl, glat
        write (*, '('' Position angle of the Galactic parallel = '',
     +              F7.2, '' degrees'')') pa
        write (*, '('' Estimated distance from the G.C. = '',
     +              F7.2, '' kpc'')') rc 
*
        if (rc .gt. R0) then
          ndis = 1
          write (*, '('' Estimated distance from the Sun = '',   
     +                 F7.2, '' kpc'')') rd(1)
          write (*, '('' Transversal velocity = '', F7.2, '' km/s'')')
     +           vt(1)
          write (*, '('' PM due to GR         = '', F7.2, '' mas/y'')')
     +           gpm(1)
        else
          ndis = 2
          write (*, '('' Estimated distance from the Sun = '', 
     +                 F7.2, ''   or '', F7.2, '' kpc'')') rd(1), rd(2)
          write (*, '('' Transversal velocity = '', F7.2, ''   or '',
     +                F7.2, '' km/s'')') vt(1), vt(2)
          write (*, '('' PM due to GR         = '', F7.2, ''   or '',
     +                F7.2, '' mas/y'')') gpm(1), gpm(2)
        endif
*
      else
*       *** estimated distance given
        ndis = 1
        call eqtogalp(rh, rm, rs, isign, dd, dm, dc, gl, glat, pa)
*
C        write (*, *) 'Enter distance in kpc : '
C       read (*, *) rde
*
        rgl = rad * gl
        sgl = sin(rgl)
        cgl = cos(rgl)
*
        rc = sqrt(rde * rde - 2.0d0 * R0 * rde * cgl + R0 * R0)
*       *** distance of the object from the Galactic center ***

        write (*, *) 'Galactic longitude and latitude = ', 
     +               gl, ', ', glat
        write (*, *) 'Position angle of the galactic plane = ', pa
*
        if (glat .gt. 5.0d0) then
          write (*, *)
          write (*, *) 'WARNING : the galactic latitude might be too ', 
     +                 'large for the flat rotation model!'
          write (*, *)
        endif
*
        vr = V0 * sgl * (R0 - rc) /rc
        rd(1) = rde 
        vt(1) = - V0 * ((R0 - rc) * cgl - rde) / rc
        gpm(1) = 0.2108 * vt(1) / rde
*
        write (*, *)
        write (*, '('' Distance from the Galactic center = '',
     +               F7.2, '' kpc'')') rc
        write (*, '('' Estimated LSR velocity = '', F7.2, '' km/s'')') 
     +           vr
        write (*, '('' Transversal velocity   = '', F7.2, '' km/s'')')
     +           vt(1)
        write (*, '('' PM due to GR           = '', F7.2, '' mas/y'')')
     +           gpm(1)
      endif
*
      dsl = 360.0d0 / nseg
*
      rpa = rad * pa
*
*     Position angle 'pa' of the Galactic parallel (direction of 
*     increasing galactic longitude) at the source is measured 
*     eastward from the north, while 'vt' and 'pm' are taken 
*     positive if the source moves towards direction of decreasing 
*     galactic longitude.
*
      do 200 i = 1, ndis
        agpm = -gpm(i) * sin(rpa)
        dgpm = -gpm(i) * cos(rpa)
*
        write (*, *) 'PM due to GR in RA and Dec = ', agpm,
     +               '  ', dgpm, '  mas/y'
*
        write (11, '(4F10.3)') zero, zero, agpm, dgpm
        write (11, *)
*
C        print *, 'writing galrot.dat'
C        pause

        dagpm = agpm / nseg
        ddgpm = dgpm / nseg
*
        call solmot(ras, dec, rd(i), spm, aspm, dspm)
*
        write (*, *) 'Solar motion effect in RA and Dec = ', aspm,
     +               '  ', dspm, '  mas/y'
*
        write (12, '(4F10.3)') zero, zero, aspm, dspm
        write (12, *)
*
C        print *, 'writing solmot.dat'
C       pause
*
        acpm = agpm + aspm
        dcpm = dgpm + dspm
*
        write (14, '(4F10.3)') zero, zero, acpm, dcpm
        write (14, *)
*
        dacpm = acpm / nseg
        ddcpm = dcpm / nseg
*
        apmmt = 0.0d0
        dpmmt = 0.0d0
*
*       do 100 j = 1, 2 * nseg + 1
* Calculate the apparent motion for 20 (rather than 2) years
         do 100 j = 1, 20 * nseg + 1

          slong = dsl * (j - 1)
          apmmt = dacpm * (j - 1)
          dpmmt = ddcpm * (j - 1)
*
          call parallax(ras, dec, rd(i), slong, cdra, ddec)
*
          if (j .eq. 1) then
            pdra = cdra
            pdec = ddec
          endif
*
          rdra = cdra - pdra
          rdec = ddec - pdec
          write (13, '(2F10.3)') rdra, rdec
          write (15, '(2F10.3)') (apmmt + rdra), dpmmt + rdec
 100    continue
*
 200  continue
*
      close (11)
      close (12)
      close (13)
      close (14)
      close (15)
*
      if (dec .lt. 0.0d0) then
        asign = '-'
      else
        asign = '+'
      endif
*
      irh = rh
      irm = rm
      idd = dd
      idm = dm
      write (arh, '(I3)') 100 + irh
      write (arm, '(I3)') 100 + irm
      write (add, '(I3)') 100 + idd
      write (adm, '(I3)') 100 + idm
*
      write (16, 1000) arh(2 : 3), arm(2 : 3), asign, 
     +       add(2 : 3), adm(2 : 3), rd(1),
     +       arh(2 : 3), arm(2 : 3), asign, 
     +       add(2 : 3), adm(2 : 3)
 1000 format (
     + 'set title "Trajectory of an Object at ', 2A2, A1, 2A2, 
     + ' and ', F5.2, 'kpc away in Flat Rotation Model' /
     + 'set size 1.5, 0.725' /
     + 'set xrange [] reverse' /
     + 'set xlabel "Displacement in RA (mas)"'/
     + 'set ylabel "Displacement in Dec (mas)"'/
     + 'set terminal postscript portrait color' /
     + 'set output "frmodel', 2A2, A1, 2A2, 
     + '.ps"' /
     + 'plot \\'/
     + '"galrot.dat" title "Galact. Rot./year" with vector , \\'/
     + '"solmot.dat" title "Solar Motion/year" with vector , \\'/
     + '"galsol.dat" title "Sum of Above     " with vector , \\'/
     + '"paralx.dat" title "Annual Parallax  " with linespoints, \\'/
     + '"combmt.dat" title "Combined Motion  " with linespoints ')
*
      close (16)
*
C      write (*, *)
C      write (*, *) 'Do you have "gnuplot" (y/n)?'
C      read (*, *) ans
*
C      if (ans .eq. 'y' .or. ans .eq. 'Y') then
C        call system('gnuplot frmodel.gp') 
*
C        write (*, *) 'Do you have "gv" (y/n)?'
C        read (*, *) ans
*
C        if (ans .eq. 'y' .or. ans .eq. 'Y') then
C          call system('gv frmodel' //  arh(2 : 3) // arm(2 : 3) //
C     +                 asign // add(2 : 3) // adm(2 : 3) // '.ps &')
C        else
          write (*, *) 'PostScript file is stored in frmodel' //
     +                 arh(2 : 3) // arm(2 : 3) //
     +                 asign // add(2 : 3) // adm(2 : 3) // '.ps'
C        endif
*
C      else
C        write (*, *) 'gnuplot script file is stored in frmodel.gp'
C      endif
*

      stop
      end
