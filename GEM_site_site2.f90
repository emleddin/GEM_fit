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
program GEM_site_site2

use definition

  implicit none

  include "io.fh"
  type(auxiliary_basis)::atom_auxis
  type(auxiliary_basis)::atom_auxis2
  type(sites_info)::site_info
  type(sites_info)::site_info2
  type(aux_orbitals),allocatable::auxis(:)
  integer argc,arg,l,allochk, i,iargc
  double precision tot_esp,tot_fld,ener
  character(len=PATH_MAX) argv
  character(len=80)parmfile,auxfile,crdfile,loc_hermcoeffs,&
                   parmfile2,crdfile2,loc_hermcoeffs2
  logical readdens, debug

  readdens = .false.
  debug = .false.
  parmfile = ''
  parmfile2 = ''
  auxfile = ''
  crdfile = ''
  loc_hermcoeffs = ''
  crdfile2 = ''
  loc_hermcoeffs2 = ''
  arg=1
  argc=IArgC()
  do while (arg <= argc)
    call GetArg(arg,argv)
    if(argv == '-crd') then
      arg=arg+1
      call GetArg(arg,crdfile)
    elseif(argv == '-crd2') then
      arg=arg+1
      call GetArg(arg,crdfile2)
    elseif ( argv == '-parm')then
      arg=arg+1
      call GetArg(arg,parmfile)
    elseif ( argv == '-parm2')then
      arg=arg+1
      call GetArg(arg,parmfile2)
    elseif ( argv == '-aux')then
      arg=arg+1
      call GetArg(arg,auxfile)
    elseif ( argv == '-lherm')then
      arg=arg+1
      call GetArg(arg,loc_hermcoeffs)
    elseif ( argv == '-lherm2')then
      arg=arg+1
      call GetArg(arg,loc_hermcoeffs2)
    elseif ( argv == '-debug')then
      arg=arg+1
      debug = .true.
      if (debug) open(12,file='GEMoutput.debug',status="unknown")
    endif
    arg = arg + 1
  enddo
  if ( (crdfile == '') .or. (parmfile == '') .or.  &
       (auxfile == '') .or. (loc_hermcoeffs == '') .or.&
       (crdfile2 == '') .or. (parmfile2 == '') .or. &
       (loc_hermcoeffs2 == ''))then
    write(6,*)'usage: ', &
      'GEM_site_site2 -crd crdfile -parm parmfile -aux auxfile -lherm &
       &lhermcoeffs -crd2 crdfile2 -parm2 parmfile2 -lherm2 lhermcoeffs2'
    stop
  endif
 
! read first monomer
  call AHCRD_read_file(site_info,crdfile)
  call AHBASE_load_auxnames(atom_auxis,parmfile)
  call AHBASE_load_auxbasis(atom_auxis,auxfile)
  call AHBASE_calcnorms(atom_auxis,' ') ! for esp & fld
  call AHTYPE_load_site_info_2(site_info,atom_auxis,parmfile)
  call AHCOEFF_copy_norms_from_basis(site_info,atom_auxis) ! for esp & fld
  call AHCOEFF_load_local_hermite(site_info,loc_hermcoeffs)
  call AHFRAME_load_deflist(site_info,parmfile,readdens,debug)
  call AHFRAME_build_frames(site_info)
  call AHFRAME_local_to_global(site_info)
! read second monomer
  call AHCRD_read_file(site_info2,crdfile2)
  call AHBASE_load_auxnames(atom_auxis2,parmfile2)
  call AHBASE_load_auxbasis(atom_auxis2,auxfile)
  !call AHBASE_calcnorms(atom_auxis2,' ')
  call AHTYPE_load_site_info_2(site_info2,atom_auxis2,parmfile2)
  call AHCOEFF_load_local_hermite(site_info2,loc_hermcoeffs2)
  call AHFRAME_load_deflist(site_info2,parmfile2,readdens,debug)
  call AHFRAME_build_frames(site_info2)
  call AHFRAME_local_to_global(site_info2)
! interact
  call AHSITESITE_interact2(site_info,site_info2,ener)
! exchange
  call H_exchange2(site_info,site_info2,1.0d0,ener) ! for regression

  if(debug)close(12)
end program GEM_site_site2
