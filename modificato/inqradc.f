                    subroutine inqradc(raline, decline, rh, rm, rs, 
     +                                 isign, dd, dm, ds, ras, dec)
*
*     reads right ascension HHMMSS.SSS and declination +/-DDMMSS.SSS
*     from the console and returns the values 'rh', 'rm', 'rs', 'isign',
*     'dd', 'dm' and 'ds', as well as 'ras' and 'dec' in degrees.
*
      implicit real * 8 (a - h, o - z)
*
      character raline * 70 , decline * 70
*
C      write (*, *) 'Enter right ascention in HH MM SS.SSS'
C      read (*, '(A70)') aline
*
         do 50 i = 1, 70
*
          if (raline(i : i) .eq. ':') then
           raline(i : i) = ' '
          endif
*
50      continue
*
      read (raline, *, iostat = istat) rh, rm, rs
*
      if (istat .ne. 0) then
        write (*, *) 'inqradc : read error! ', raline
        stop
      elseif (rh .lt. 0.0d0 .or. rh .gt. 24.0d0) then
        write (*, *) 'inqradc : RA hour out of range!  rh = ', 
     +               rh
        stop
      else if (rm .lt. 0.0d0 .or. rm .gt. 60.0d0) then
        write (*, *) 'inqradc : RA minutes out of range!  rm = ', 
     +               rm
        stop
      else if (rs .lt. 0.0d0 .or. rs .gt. 60.0d0) then
        write (*, *) 'inqradc : RA second out of range!   rs = ',
     +               rs
        stop
      endif
*
C      write (*, *) 'Enter declination in +/- DD MM SS.SSS'
*
C      read (*, '(A70)') aline

        do 60 i = 1, 70
*
         if (decline(i : i) .eq. ':') then
          decline(i : i) = ' '
         endif
*
60    continue
*
      do 100 i = 1, 70
*
        if (decline(i : i) .ne. ' ') then
          go to 200
        endif
*
 100  continue
*
      write (*, *) 'inqradc : Too many blanks in decline "', decline, 
     +             '"'
      stop
*
 200  continue
*
      if (decline(i : i) .eq. '-') then
        isign = -1
        i = i + 1
      else if (decline(i : i) .eq. '+') then
        isign = 1
        i = i + 1
      else
        isign = 1
      endif
*
**      write (*, *) 'sign = "', aline(i - 1 : i - 1), '"'
*
      read (decline(i : 70), *, iostat = istat) dd, dm, ds
*
      if (istat .ne. 0) then
        write (*, *) 'inqradc : read error! ', decline
        stop
      elseif (dd .lt. 0.0d0 .or. dd .gt. 90.0d0) then
        write (*, *) 'inqradc : DEC degree out of range!  dd = ', 
     +               dd
        stop
      else if (dm .lt. 0.0d0 .or. dm .gt. 60.0d0) then
        write (*, *) 'inqradc : DEC minutes out of range!  dm = ', 
     +               dm
        stop
      else if (ds .lt. 0.0d0 .or. ds .gt. 60.0d0) then
        write (*, *) 'inqradc : DEC second out of range!   ds = ',
     +               ds
        stop
      endif
*
      ras = 15.0d0 * (rh + rm / 60.0d0 + rs / 3600.0d0)
      dec = isign  * (dd + dm / 60.0d0 + ds / 3600.0d0)
*      
      return      
      end


