!GEM_fit: Gaussian Electrostatic Moment fitting
!Copyright (C) 2012  G. Andres Cisneros
!
!This program is free software: you can redistribute it and/or modify
!it under the terms of the GNU General Public License as published by
!the Free Software Foundation, either version 3 of the License, or
!(at your option) any later version.
!
!This program is distributed in the hope that it will be useful,
!but WITHOUT ANY WARRANTY; without even the implied warranty of
!MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!GNU General Public License for more details.
!
!You should have received a copy of the GNU General Public License
!along with this program.  If not, see <http://www.gnu.org/licenses/>.
!--------------------------------------------------------------
subroutine HCRD_read_control(controlfile,parmfile,auxfile,basfile,crdfile,&
                             densfile,promolfile,coeff_file,lhermitefile,&
                             mpole_file,mpole_file2,mpole_file3,&
                             constrain,readdens,readbas,debug,cartfit,&
                             inttype,beta,scale,cutoff,printcube,&
                             promolfit,twocentfit,cubetype,sphere,HLYfit)
use definition
  implicit none
  character(len=*) controlfile
  include "io.fh"

  integer controlunit,ios, ptr
  integer TRDPRM_get_next_line,lenword,inttype,l,cubetype
  double precision beta, scale, cutoff
  character(len=120) line,word,token
  character(len=80)parmfile,auxfile,crdfile,densfile,basfile,coeff_file,&
                   lhermitefile,mpole_file,mpole_file2,mpole_file3,&
                   filehead,promolfile
  character(len=1) tmp_type
  character(len=5) NAMEFMT
  logical constrain, readdens, readbas, debug, cartfit, printcube!,&
  logical promolfit,twocentfit,sphere,HLYfit,gemesp
  parameter (NAMEFMT='(A60)')

! NOTE: there are three types of integrals (int_type) available:
!       coulomb: int_type = 0 (default)
!       overlap: int_type = 1
!       damped coulomb (erfc): int_type = 2)
!
!       There are two parameters that can be read in the control file:
!       scale: determines the addition factor to the diagonal of the G matrix.
!       beta: determines the dampening factor for the damped coulomb (erfc).
! 
!       IF debug is set then unit 12 will be used to dump all debug info
!       (filename = GEMoutput.debug)
!
!       IF cart is set the fitting will be performed in cartesian gaussians
!       (hermite gaussians is the default)

  inttype = 0
  cubetype = 2
  beta = 0.0d0
  scale = 0.0d0
  cutoff = 0.0d0
  constrain = .false.
  readdens = .false.
  readbas = .false.
  debug = .false.
  cartfit = .false.
  sphere = .false.
  promolfit = .false.
  twocentfit = .false.
  HLYfit = .false.
  gemesp = .false.
  parmfile = ''
  auxfile = ''
  basfile = ''
  crdfile = ''
  densfile = ''
  promolfile = ''
  coeff_file = ''
  lhermitefile = ''
  mpole_file = ''
  mpole_file2 = ''
  mpole_file3 = ''
  filehead = ''

  controlunit = File_Open(controlfile,"r")
  if ( controlunit < 0 )then
    write(6,*)'AHCRD_read_control: failed to open control file ',&
               & controlfile(1:Len_Trim(controlfile))
    stop
  endif
 
  ios = 0
  do while (ios==0)
    line = ' '  ! to avoid junk in line after some reads
    token = ' '  ! to avoid junk in token after some reads
    ios = TRDPRM_get_next_line(controlunit,line)
    if ( ios == 0 )then
      ptr = 1 ! first call to str_next_token needs an initial value
      call str_next_token(line,ptr,word,lenword) !get 1st token
      if ( ptr > 0 )then !check if its 'crd'
        if (word(1:lenword) == 'crd' .or. word(1:lenword) == 'CRD' &
            .or. word(1:lenword) == 'Crd')then
           read(line(5:),NAMEFMT) token
           crdfile = trim(token)
        else if (word(1:lenword) == 'parm' .or. word(1:lenword) == 'PARM' &
                 .or. word(1:lenword) == 'Parm')then
           read(line(6:),NAMEFMT) token
           parmfile = trim(token)
        else if (word(1:lenword) == 'aux' .or. word(1:lenword) == 'AUX' &
                 .or. word(1:lenword) == 'Aux')then
           read(line(5:),NAMEFMT) token
           auxfile = trim(token)
        else if (word(1:lenword) == 'bas' .or. word(1:lenword) == 'BAS' &
                 .or. word(1:lenword) == 'Bas')then
           read(line(5:),NAMEFMT) token
           basfile = trim(token)
           readbas = .true.
        else if (word(1:lenword) == 'dens' .or. word(1:lenword) == 'DENS' &
                 .or. word(1:lenword) == 'Dens')then
           read(line(6:),NAMEFMT) token
           densfile = trim(token)
           readdens = .true.
        else if (word(1:lenword) == 'promol' .or. word(1:lenword) == 'PROMOL' &
                 .or. word(1:lenword) == 'Promol')then
           read(line(8:),NAMEFMT) token
           promolfile = trim(token)
           promolfit = .true.
           write(6,*)'HCRD_read_control: promol option found'
        else if (word(1:lenword) == '2cent' .or. word(1:lenword) == '2CENT' &
                 .or. word(1:lenword) == '2Cent'.or. &
                 word(1:lenword) == 'twocent'.or.word(1:lenword) == 'TWOCENT'&
                 )then
           write(6,*)'HCRD_read_control: Only two center part of density will&
                      & be fit'
           twocentfit = .true.
        else if (word(1:lenword) == 'head' .or. word(1:lenword) == 'HEAD' &
                 .or. word(1:lenword) == 'Head')then
           read(line(6:),NAMEFMT) token
           filehead = trim(token)
        else if (word(1:lenword) == 'type' .or. word(1:lenword) == 'Type' &
                 .or. word(1:lenword) == 'TYPE')then
           read(line(6:),NAMEFMT) token
           tmp_type = trim(token)
           if (tmp_type.eq.'S' .or. tmp_type.eq.'s' .or. &
               tmp_type.eq.'O' .or. tmp_type.eq.'o') then
              inttype = 2
              write(6,*)'HCRD_read_control: Overlap integrals will be used'
           else if (tmp_type.eq.'D' .or. tmp_type.eq.'d') then
              inttype = 1
              write(6,*)'HCRD_read_control: erfc integrals will be used'
           else
              write(6,*)'HCRD_read_control: Integral type for fitting not &
                         &specified, using default (Coulomb)' 
           endif
        else if (word(1:lenword) == 'cube' .or. word(1:lenword) == 'Cube' &
                 .or. word(1:lenword) == 'CUBE')then
           read(line(6:),NAMEFMT) token
           tmp_type = trim(token)
           if (tmp_type.eq.'dens' .or. tmp_type.eq.'DENS' .or. &
               tmp_type.eq.'D' .or. tmp_type.eq.'d') then
              cubetype = 1
              write(6,*)'HCRD_read_control: Only density cube will be fit'
           else if (tmp_type.eq.'ESP' .or. tmp_type.eq.'Esp' .or. &
                    tmp_type.eq.'E' .or. tmp_type.eq.'e') then
              cubetype = 2
              write(6,*)'HCRD_read_control: Only ESP cube will be fit'
           else if (tmp_type.eq.'FLD' .or. tmp_type.eq.'Fld' .or. &
                    tmp_type.eq.'F' .or. tmp_type.eq.'f') then
              cubetype = 3
              write(6,*)'HCRD_read_control: Only Field cubes will be fit'
           else
              write(6,*)'HCRD_read_control: All cubes (dens, esp, fld) will&
                         & be fit'
           endif
        else if (word(1:lenword) == 'constr' .or. word(1:lenword) == 'CONSTR' &
                 .or. word(1:lenword) == 'Constr')then
           constrain = .true.
        else if (word(1:lenword) == 'debug' .or. word(1:lenword) == 'DEBUG' &
                 .or. word(1:lenword) == 'Debug')then
           debug = .true.
           if (debug) open(12,file='GEMoutput.debug',status="unknown")
        else if (word(1:lenword) == 'cart' .or. word(1:lenword) == 'CART' &
                 .or. word(1:lenword) == 'Cart')then
           cartfit = .true.
           write(6,*)'HCRD_read_control: cart option found, fitting in &
                      &cartesian'
        else if (word(1:lenword) == 'print' .or. word(1:lenword) == 'PRINT' &
                 .or. word(1:lenword) == 'Print')then
           printcube = .true.
           write(6,*)'HCRD_read_control: print option found, cube files will &
                      &be printed'
        else if (word(1:lenword) == 'gemesp' .or. word(1:lenword) == 'GEMESP' &
                 .or. word(1:lenword) == 'GEMesp')then
           gemesp = .true.
           write(6,*)'HCRD_read_control: GEMesp option found, will calculate&
                      & ESP directly'
        else if (word(1:lenword) == 'sphere' .or. word(1:lenword) == 'SPHERE' &
                 .or. word(1:lenword) == 'Sphere')then
           sphere = .true.
           write(6,*)'HCRD_read_control: sphere option found, spherical grids&
                      & will be fit'
           write(6,*)'                   MAKE SURE sphere_file IS IN au'
        else if (word(1:lenword) == 'HLYfit' .or. word(1:lenword) == 'HLYFIT' &
                 .or. word(1:lenword) == 'hlyfit')then
           HLYfit = .true.
           write(6,*)'HCRD_read_control: HLYfit option found, smoothing at &
                      &cores and &
                      &long-range will be used'
        else if (word(1:lenword) == 'beta' .or. word(1:lenword) == 'BETA' &
                 .or. word(1:lenword) == 'Beta')then
           read(line(6:),*) beta
        else if (word(1:lenword) == 'lambda' .or. word(1:lenword) == 'LAMBDA' &
                 .or. word(1:lenword) == 'Lambda')then
           read(line(8:),*) beta
        else if (word(1:lenword) == 'cutoff' .or. word(1:lenword) == 'CUTOFF' &
                 .or. word(1:lenword) == 'CUTOFF')then
           read(line(8:),*) cutoff
           write(6,*)'HCRD_read_control: Will use cutoff for cube fit = ',cutoff
        else if (word(1:lenword) == 'scale' .or. word(1:lenword) == 'SCALE' &
                 .or. word(1:lenword) == 'SCALE')then
           read(line(7:),*) scale
        endif
      endif
    endif
  enddo !while ios==0
  call File_Close(controlunit)

  if (.not.readbas) then
     if ( (crdfile == '') .or. (parmfile == '') .or.  &
          (auxfile == ''))then
       write(6,*)'Could not find crdfile or parmfile or auxfile in control &
                  &file, exiting'
       stop
     endif
  else
     if ( (crdfile == '') .or. (parmfile == '') .or.  &
          (auxfile == '') .or. (basfile == '') .or. (densfile == ''))then
       write(6,*)'Could not find crdfile or parmfile or auxfile or basfile &
                  &or densfile in control file, exiting'
       stop
     endif
  endif

  if (filehead == '')then
     write(6,*)'HCRD_read_control: filehead not specified in control file, '
     write(6,*)'                   using default (GEMoutput.*)'
     filehead = 'GEMoutput'
  endif
  l = Len_Trim(filehead)
  coeff_file = filehead(1:l)//'.coeff'
  mpole_file = filehead(1:l)//'.mpoles'
  mpole_file2 = filehead(1:l)//'.mpoles_NEW'
  mpole_file3 = filehead(1:l)//'.mpoles_GLOBAL'
  lhermitefile = filehead(1:l)//'.lhermite'

  if (inttype == 1) then
     write (6,*)'HCRD_read_control: beta = ',beta
  endif
  write (6,*)'HCRD_read_control: scale = ',scale

  return
end subroutine HCRD_read_control
!--------------------------------------------------------------
subroutine HCRD_read_control2(controlfile,parmfile,auxfile,basfile,crdfile,&
                             densfile,promolfile,coeff_file,lhermitefile,&
                             mpole_file,mpole_file2,constrain,readdens,&
                             readbas,debug,cartfit,inttype,beta,scale,&
                             kexchqmgem,kexchgem,&
                             printcube,promolfit,parmfile2,crdfile2,&
                             lhermitefile2,lhermitefile3,densfile2)
use definition
  implicit none
  character(len=*) controlfile
  include "io.fh"

  integer controlunit,ios, ptr
  integer TRDPRM_get_next_line,lenword,inttype,l
  double precision beta, scale, kexchqmgem, kexchgem
  character(len=120) line,word,token
  character(len=80)parmfile,auxfile,crdfile,densfile,basfile,coeff_file,&
                   lhermitefile,mpole_file,mpole_file2,filehead,promolfile,&
                   parmfile2,crdfile2,lhermitefile2,lhermitefile3,densfile2
  character(len=1) tmp_type
  character(len=5) NAMEFMT
  logical constrain, readdens, readbas, debug, cartfit, printcube, promolfit
  parameter (NAMEFMT='(A60)')

! NOTE: there are three types of integrals (int_type) available:
!       coulomb: int_type = 0 (default)
!       overlap: int_type = 1
!       damped coulomb (erfc): int_type = 2)
!
!       There are two parameters that can be read in the control file:
!       scale: determines the addition factor to the diagonal of the G matrix.
!       beta: determines the dampening factor for the damped coulomb (erfc).
!  GAC, mod 11/06 for QMMM: added read in of K parameters for exchange
!                          (qmgem between qm and gem subsyst, kexchgem for gem)
! 
!       IF debug is set then unit 12 will be used to dump all debug info
!       (filename = GEMoutput.debug)
!
!       IF cart is set the fitting will be performed in cartesian gaussians
!       (hermite gaussians is the default)

  inttype = 0
  beta = 0.0d0
  scale = 0.0d0
  kexchqmgem = 1.0d0
  kexchgem = 1.0d0
  constrain = .false.
  readdens = .false.
  readbas = .false.
  debug = .false.
  cartfit = .false.
  printcube = .false.
  promolfit = .false.
  parmfile = ''
  parmfile2 = ''
  auxfile = ''
  basfile = ''
  crdfile = ''
  crdfile2 = ''
  densfile = ''
  densfile2 = ''
  promolfile = ''
  coeff_file = ''
  lhermitefile = ''
  lhermitefile2 = ''
  lhermitefile3 = ''
  mpole_file = ''
  mpole_file2 = ''
  filehead = ''

  controlunit = File_Open(controlfile,"r")
  if ( controlunit < 0 )then
    write(6,*)'AHCRD_read_control: failed to open control file ',&
               & controlfile(1:Len_Trim(controlfile))
    stop
  endif
 
  ios = 0
  do while (ios==0)
    line = ' '  ! to avoid junk in line after some reads
    token = ' '  ! to avoid junk in token after some reads
    ios = TRDPRM_get_next_line(controlunit,line)
    if ( ios == 0 )then
      ptr = 1 ! first call to str_next_token needs an initial value
      call str_next_token(line,ptr,word,lenword) !get 1st token
      if ( ptr > 0 )then !check if its 'crd'
        if (word(1:lenword) == 'crd' .or. word(1:lenword) == 'CRD' &
            .or. word(1:lenword) == 'Crd')then
           read(line(5:),NAMEFMT) token
           crdfile = trim(token)
        else if (word(1:lenword) == 'parm' .or. word(1:lenword) == 'PARM' &
                 .or. word(1:lenword) == 'Parm')then
           read(line(6:),NAMEFMT) token
           parmfile = trim(token)
        else if (word(1:lenword) == 'crd2' .or. word(1:lenword) == 'CRD2' &
            .or. word(1:lenword) == 'Crd2')then
           read(line(6:),NAMEFMT) token
           crdfile2 = trim(token)
        else if (word(1:lenword) == 'parm2' .or. word(1:lenword) == 'PARM2' &
                 .or. word(1:lenword) == 'Parm2')then
           read(line(7:),NAMEFMT) token
           parmfile2 = trim(token)
        else if (word(1:lenword) == 'lherm' .or. word(1:lenword) == 'LHERM' &
                 .or. word(1:lenword) == 'Lherm')then
           read(line(7:),NAMEFMT) token
           lhermitefile = trim(token)
        else if (word(1:lenword) == 'lherm2' .or. word(1:lenword) == 'LHERM2' &
                 .or. word(1:lenword) == 'Lherm2')then
           read(line(8:),NAMEFMT) token
           lhermitefile2 = trim(token)
        else if (word(1:lenword) == 'lherm3' .or. word(1:lenword) == 'LHERM3' &
                 .or. word(1:lenword) == 'Lherm3')then
           read(line(8:),NAMEFMT) token
           lhermitefile3 = trim(token)
        else if (word(1:lenword) == 'aux' .or. word(1:lenword) == 'AUX' &
                 .or. word(1:lenword) == 'Aux')then
           read(line(5:),NAMEFMT) token
           auxfile = trim(token)
        else if (word(1:lenword) == 'bas' .or. word(1:lenword) == 'BAS' &
                 .or. word(1:lenword) == 'Bas')then
           read(line(5:),NAMEFMT) token
           basfile = trim(token)
           readbas = .true.
        else if (word(1:lenword) == 'dens' .or. word(1:lenword) == 'DENS' &
                 .or. word(1:lenword) == 'Dens')then
           read(line(6:),NAMEFMT) token
           densfile = trim(token)
           readdens = .true.
        else if (word(1:lenword) == 'dens2' .or. word(1:lenword) == 'DENS2' &
                 .or. word(1:lenword) == 'Dens2')then
           read(line(7:),NAMEFMT) token
           densfile2 = trim(token)
        else if (word(1:lenword) == 'promol' .or. word(1:lenword) == 'PROMOL' &
                 .or. word(1:lenword) == 'Promol')then
           read(line(8:),NAMEFMT) token
           promolfile = trim(token)
           promolfit = .true.
        else if (word(1:lenword) == 'head' .or. word(1:lenword) == 'HEAD' &
                 .or. word(1:lenword) == 'Head')then
           read(line(6:),NAMEFMT) token
           filehead = trim(token)
        else if (word(1:lenword) == 'type' .or. word(1:lenword) == 'TYPE' &
                 .or. word(1:lenword) == 'TYPE')then
           read(line(6:),NAMEFMT) token
           tmp_type = trim(token)
           if (tmp_type.eq.'S' .or. tmp_type.eq.'s' .or. &
               tmp_type.eq.'O' .or. tmp_type.eq.'o') then
              inttype = 2
              write(6,*)'HCRD_read_control: Overlap integrals will be used'
           else if (tmp_type.eq.'D' .or. tmp_type.eq.'d') then
              inttype = 1
              write(6,*)'HCRD_read_control: erfc integrals will be used'
           else
              write(6,*)'HCRD_read_control: Integral type for fitting not &
                         &specified, using default (Coulomb)' 
           endif
        else if (word(1:lenword) == 'constr' .or. word(1:lenword) == 'CONSTR' &
                 .or. word(1:lenword) == 'Constr')then
           constrain = .true.
        else if (word(1:lenword) == 'debug' .or. word(1:lenword) == 'DEBUG' &
                 .or. word(1:lenword) == 'Debug')then
           debug = .true.
           if (debug) open(12,file='GEMoutput.debug',status="unknown")
        else if (word(1:lenword) == 'cart' .or. word(1:lenword) == 'CART' &
                 .or. word(1:lenword) == 'Cart')then
           cartfit = .true.
           write(6,*)'HCRD_read_control: cart option found, fitting in &
                      &cartesian'
        else if (word(1:lenword) == 'print' .or. word(1:lenword) == 'PRINT' &
                 .or. word(1:lenword) == 'Print')then
           printcube = .true.
           write(6,*)'HCRD_read_control: print option found, cube files will &
                      &be printed'
        else if (word(1:lenword) == 'beta' .or. word(1:lenword) == 'BETA' &
                 .or. word(1:lenword) == 'Beta')then
           read(line(6:),*) beta
        else if (word(1:lenword) == 'scale' .or. word(1:lenword) == 'SCALE' &
                 .or. word(1:lenword) == 'SCALE')then
           read(line(7:),*) scale
        else if (word(1:lenword) == 'qmk' .or. word(1:lenword) == 'QMK' &
                 .or. word(1:lenword) == 'qmK')then
           read(line(5:),*) kexchqmgem
           write(6,*)'HCRD_read_control: qmk option found, K for QM-GEM exch &
                      &will be ',kexchqmgem
        else if (word(1:lenword) == 'exchk' .or. word(1:lenword) == 'ExchK' &
                 .or. word(1:lenword) == 'exchK' &
                 .or. word(1:lenword) == 'EXCHK')then
           read(line(7:),*) kexchgem
           write(6,*)'HCRD_read_control: exchk option found, K for GEM exch &
                      &will be ',kexchgem
        endif
      endif
    endif
  enddo !while ios==0
  call File_Close(controlunit)

  if (.not.readbas) then
     if ( (crdfile == '') .or. (parmfile == '') .or.  &
          (auxfile == ''))then
       write(6,*)'Could not find crdfile or parmfile or auxfile in control &
                  &file, exiting'
       stop
     endif
  else
     if ( (crdfile == '') .or. (parmfile == '') .or.  &
          (auxfile == '') .or. (basfile == '') .or. (densfile == ''))then
       write(6,*)'Could not find crdfile or parmfile or auxfile or basfile &
                  &or densfile in control file, exiting'
       stop
     endif
  endif

  if (filehead == '')then
     write(6,*)'HCRD_read_control: filehead not specified in control file, '
     write(6,*)'                   using default (GEMoutput.*)'
     filehead = 'GEMoutput'
  endif
  l = Len_Trim(filehead)
  coeff_file = filehead(1:l)//'.coeff'
  mpole_file = filehead(1:l)//'.mpoles'
  mpole_file2 = filehead(1:l)//'.mpoles_NEW'
  lhermitefile = filehead(1:l)//'.lhermite'

  if (inttype == 1) then
     write (6,*)'HCRD_read_control: beta = ',beta
  endif
  write (6,*)'HCRD_read_control: scale = ',scale

  return
end subroutine HCRD_read_control2
!--------------------------------------------------------------
