module pythonBAM
   use iso_c_binding
   use sigio_BAMMod, only: bamFile
   Implicit None
   Private

   Public :: open
   Public :: close
   Public :: getDim
   Public :: getField
   Public :: getNLevels

   character(len=*),parameter :: myname = 'pythonBAM'

   Real, Public, Allocatable :: Array1D(    :)
   Real, Public, Allocatable :: Array2D(  :,:)
   Real, Public, Allocatable :: Array3D(:,:,:)

   Character(len=32), Public, Allocatable :: CharArray1D(  :)
   Character(len=32), Public, Allocatable :: CharArray2D(:,:)

   type acc
      integer                :: FNumber
      character(len=512)     :: header
      character(len=512)     :: binary
      integer                :: iret
      type(bamFile), pointer :: bam => null()
      type(acc), pointer     :: next => null()
   end type

   type files
      integer             :: fCount
      type(acc),  pointer :: tail => null()
      type(acc),  pointer :: root => null()
   end type files
   type(files) :: accessFile


   contains

   function open(header, binary, mode, ftype, initSpec) result(FNumber)

      Character(len=*), intent(in   ) :: header
      Character(len=*), intent(in   ) :: binary
      character(len=*), intent(in   ) :: mode
      character(len=*), intent(in   ) :: ftype
      logical         , intent(in   ) :: initSpec
      Integer                         :: FNumber

      integer            :: bufr0, bufr1
      logical            :: existe
      integer            :: FileCount
      integer            :: iret
      logical            :: F2_existe
      character(len=1024):: N1, N2
      type(acc), pointer :: d => null()
      type(acc), pointer :: tmp => null()

      character(len=*), parameter :: myname_=myname//' :: open()'

      print*,trim(myname_),' :: header: ',trim(header)
      print*,trim(myname_),' :: binary: ',trim(binary)

      !
      ! First open file
      !
      if(.not.associated(accessFile%root))then

         ! define data file type
   
         accessFile%fCount = 0

         allocate(accessFile%root)
         accessFile%tail => accessFile%root
         d => accessFile%tail
         
      else

         !
         ! Verify if file is already open
         !
         
         N1 = trim(adjustl(header))

         d => accessFile%root
         do while(associated(d))

            N2 = trim(adjustl(d%header))

            if(trim(N1).eq.trim(N2))then
               write(*,'(2(A,1x),A)')trim(myname_),'File already open:',trim(N1)
               FNumber = d%FNumber
               return
            endif

            tmp => d
            d   => d%next

         enddo

         !
         ! It's not open
         !
         allocate(tmp%next)
         d=> tmp%next

      endif

      allocate(d%bam)

      call d%bam%open(header, binary, mode, ftype, initSpec, iret)
      if(iret .eq. 0 )then
         accessFile%fCount = accessFile%fCount + 1

         d%FNumber = accessFile%fCount
         d%header  = trim(adjustl(header))
         d%binary  = trim(adjustl(binary))

         FNumber   = accessFile%fCount
      else
      
         FNumber = iret
         
      endif

   end function


   function close(FNumber) result(iret)
      Integer, intent(in) :: FNumber
      Integer             :: iret
      Type(acc), pointer  :: curr => null()
      Type(acc), pointer  :: prev => null()

      iret = 0

      prev => accessFile%root
      curr => accessFile%root%next

      if (prev%FNumber .eq. FNumber)then

         call prev%bam%close(iret)
         
         deallocate(prev)
         accessFile%root => curr
         return

      endif

      do while(associated(curr))

         if(curr%FNumber .eq. FNumber) then
            
            prev%next => curr%next

            call curr%bam%close(iret)

            deallocate(curr)

            exit
            
         endif

         prev => curr
         curr => curr%next
      enddo
   end function

   function getDim(FNumber, dimName) result(npts)
      integer,          intent(in   ) :: FNumber
      character(len=*), intent(in   ) :: dimName
      integer                         :: npts

      type(acc), pointer :: d => null()
      integer :: iret
      !
      ! Find by file opened
      !

      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      npts = d%bam%getOneDim(dimName)
      if (npts < 0) return

      allocate(Array1D(npts),stat=iret)
      if (iret.ne.0)return

      call d%bam%getWCoord(dimName, Array1D, iret)
      if (iret .ne. 0)then
         print*,'some was wrong ....'
         npts = iret
         deallocate(Array1D)
      endif
      
      return
   end function

   function getField(FNumber, fieldName, level) result(iret)
      integer,          intent(in) :: FNumber
      character(len=*), intent(in) :: fieldName
      integer,          intent(in) :: level
      integer :: iret

      integer :: imax
      integer :: jmax
      integer :: nlevs

      type(acc), pointer :: d => null()

      iret = 0
      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo
      
      ! sanity check
      !
      nlevs = d%bam%getNLevels(fieldName)
      if (level .gt. nlevs)then
         print*,'Variable:',trim(fieldName)
         print*,'Wrong level requested:', level
         print*,trim(FieldName),'has only', nlevs
         iret = -1
         return
      endif
      !-------------------------------!

      imax = d%bam%getOneDim('imax')
      jmax = d%bam%getOneDim('jmax')

      
      allocate(Array2D(imax,jmax))
      call d%bam%getField(fieldName, level, Array2D, istat=iret)

      if (iret .ne. 0)then
         deallocate(Array2D)
      endif
      
      return
   end function getField

   function getNLevels(FNumber, fieldName) result(nLevels)
      integer,          intent(in) :: FNumber
      character(len=*), intent(in) :: fieldName
      integer                      :: nLevels
      
      type(acc), pointer :: d => null()

      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo
      
      nLevels = d%bam%getNLevels(fieldName)

      return

   end function



!   subroutine GetVarInfo(FNumber, VarName, nKx)
!      integer,          intent(in   ) :: FNumber
!      character(len=*), intent(in   ) :: VarName
!      integer,          intent(  out) :: nKx
!
!      type(CObsInfo), pointer :: ObsNow => null()
!      type(ObsType), pointer :: oType => null()
!
!      type(RObsInfo), pointer :: SensorNow => null()
!      type(SatPlat), pointer :: oSat => null()
!
!      type(acc), pointer :: d => null()
!
!      character(len=10) :: v1, v2
!
!      integer :: i
!
!      !
!      ! Release array2d if allocated
!      !
!
!      if(allocated(Array2D)) deallocate(Array2D)
!
!      !
!      ! Find by file opened
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!
!
!      select case(d%FileType)
!         case(1)
!
!            !
!            ! Get first variable
!            !
!      
!            call d%conv%GetFirstVar(ObsNow)
!      
!            !
!            ! Find by VarName
!            !
!            v1 = trim(adjustl(VarName))
!            do while(associated(ObsNow))
!      
!               v2 = trim(adjustl(ObsNow%VarName))
!      
!               !now find by ObsType (kx)
!               if(v1 .eq. v2) then
!      
!                 oType => ObsNow%OT%FirstKX
!                 nKx = ObsNow%nKx
!                 allocate(Array2D(ObsNow%nKx,2))
!                 do i=1,ObsNow%nKx
!                    Array2D(i,1) = oType%kx
!                    Array2D(i,2) = oType%nobs
!                    oType => oType%nextKX
!                 enddo
!                
!               endif
!      
!               ObsNow => ObsNow%NextVar
!            enddo
!
!         case(2)
!            !
!            ! Get first variable
!            !
!      
!            call d%rad%GetFirstSensor(SensorNow)
!      
!            !
!            ! Find by VarName
!            !
!            v1 = trim(adjustl(VarName))
!            do while(associated(SensorNow))
!      
!               v2 = trim(adjustl(SensorNow%Sensor))
!      
!               !now find by ObsType (kx)
!               if(v1 .eq. v2) then
!      
!                 oSat => SensorNow%oSat%First
!                 nKx = SensorNow%nSatID
!                 allocate(Array2D(nKx,2))
!                 do i = 1,nKx
!                    Array2D(i,1) = i
!                    Array2D(i,2) = oSat%nobs
!                    oSat => oSat%Next
!                 enddo
!                
!               endif
!      
!               SensorNow => SensorNow%Next
!            enddo
!
!      end select
!
!   end subroutine
!
!   function getnvars(FNumber) result(nVars)
!      integer, intent(in   ) :: FNumber
!      integer                :: nVars
!
!      type(acc), pointer :: d => null()
!
!
!      !
!      ! Find by file opened
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!
!      !
!      ! Get number of variables
!      !
!
!      select case(d%Filetype)
!         case(1); nVars = d%conv%nVars
!         case(2); nVars = d%rad%nType
!      end select
!
!   end function
!
!   subroutine getConvVarInfo(FNumber, nVars, vNames, nTypes)
!      integer,                       intent(in   ) :: FNumber
!      integer,                       intent(in   ) :: nVars
!      character*4, dimension(nVars), intent(  out) :: vNames
!      integer,     dimension(nVars), intent(  out) :: nTypes
!
!
!      type(acc),      pointer :: d => null()
!      type(CObsInfo), pointer :: CObsRoot => null()
!      type(CObsInfo), pointer :: CtmpObs => null()
!
!        integer :: i
!
!      
!      !
!      ! Find by file opened
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!      
!      !
!      ! sanity check
!      !
!
!      if (d%fileType .ne. 1)then
!         write(*,*)'File is not conventional type'
!         return
!      endif
!
!
!      !
!      ! Get first variable
!      !
!      call d%conv%GetFirstVar(CObsRoot)
!      CtmpObs => CObsRoot
!      do i = 1, nVars
!         vNames(i) = trim(CtmpObs%VarName)
!         nTypes(i) = cTmpObs%nKx
!         CtmpObs   => CtmpObs%NextVar
!      enddo
!
!   end subroutine
!
!   subroutine getConvVarTypes(FNumber, vName, nTypes, vTypes)
!      integer,                    intent(in   ) :: FNumber
!      character*4,                intent(in   ) :: vName
!      integer,                    intent(in   ) :: nTypes
!      integer, dimension(nTypes), intent(  out) :: vTypes
!
!      integer :: i
!      type(acc),      pointer :: d => null()
!      type(CObsInfo), pointer :: CObsRoot => null()
!      type(CObsInfo), pointer :: CtmpObs => null()
!
!      type(ObsType), pointer :: ObType => null()
!
!      !
!      ! Find by file opened
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!
!      !
!      ! sanity check
!      !
!
!      if (d%fileType .ne. 1)then
!         write(*,*)'File is not conventional type'
!         return
!      endif
!
!      !
!      ! Get first variable
!      !
!      call d%conv%getFirstVar(cTmpObs)
!      do while(associated(cTmpObs))
!         if (trim(vName) .eq. trim(adjustl(cTmpObs%varName)))then
!            ObType => cTmpObs%OT%FirstKX
!            i=1
!            do while(associated(ObType))
!              vTypes(i) = ObType%kx
!              i=i+1
!              ObType => ObType%nextKX
!            enddo
!
!         endif
!         CtmpObs     => CtmpObs%NextVar
!      enddo
!
!   end subroutine
!
!
!   subroutine GetVarNames(FNumber, nVars, VarNames)
!      integer, intent(in) :: FNumber
!      integer, intent(in) :: nVars
!      character*4, dimension(nVars), intent(out) :: VarNames
!
!
!      type(acc),      pointer :: d => null()
!      type(CObsInfo), pointer :: CObsRoot => null()
!      type(CObsInfo), pointer :: CtmpObs => null()
!      type(RObsInfo), pointer :: RObsRoot => null()
!      type(RObsInfo), pointer :: RtmpObs => null()
!
!      integer :: i
!
!      
!      !
!      ! Find by file opened
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!      select case (d%FileType)
!         case(1)
!
!            !
!            ! Get first variable
!            !
!            call d%conv%GetFirstVar(CObsRoot)
!            CtmpObs => CObsRoot
!            do i = 1, nVars
!               VarNames(i) = trim(CtmpObs%VarName)
!               CtmpObs     => CtmpObs%NextVar
!            enddo
!
!         case(2)
!
!            !
!            ! Get first Sensor
!            !
!            call d%rad%GetFirstSensor(RObsRoot)
!            RtmpObs => RObsRoot
!            do i = 1, nVars
!               VarNames(i) = trim(RtmpObs%Sensor)
!               RtmpObs     => RtmpObs%Next
!            enddo
!
!      end select
!
!   end subroutine
!
!   subroutine GetObsConv  (FNumber, oName, oType, zlevs, n, NObs)
!      integer,          intent(in   ) :: FNumber
!      character(len=*), intent(in   ) :: oName
!      integer,          intent(in   ) :: oType
!      integer,          intent(in   ) :: n
!      real,             intent(in   ) :: zlevs(n)
!      integer,          intent(  out) :: NObs
!
!
!      type(acc), pointer :: d => null()
!
!
!      !
!      ! Release array2d if allocated
!      !
!
!      if(allocated(Array2D)) deallocate(Array2D)
!
!      !
!      ! Find File Number
!      !
!
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!
!      if(.not.associated(d)) then
!         print*, 'No file open ... ', FNumber
!         return
!      endif
!
!      Array2D = d%conv%GetObsInfo(oName, oType, zlevs)
!      nObs    = size(Array2D,1)
!  
!   end subroutine
!   
!   subroutine GetObsRad(FNumber, Sensor, SatId, NObs)
!      integer,          intent(in   ) :: FNumber
!      character(len=*), intent(in   ) :: Sensor
!      character(len=*), intent(in   ) :: SatId
!      integer,          intent(  out) :: NObs
!
!      type(acc), pointer :: d => null()
!      integer :: ierr
!      
!      !
!      ! Release array2d if allocated
!      !
!
!      if(allocated(Array2D)) deallocate(Array2D)
!
!      !
!      ! Find File Number
!      !
!      d => diagFile%root
!      do while(associated(d))
!         if(FNumber.eq.d%FNumber) exit
!         d => d%next
!      enddo
!
!      if(.not.associated(d)) then
!         print*, 'No file open ... ', FNumber
!         return
!      endif
!      
!      call d%rad%GetObsInfo(Sensor, SatId, Array2D, ierr)
!      if(ierr .ne. 0)then
!         nObs = -1
!         write(*,*)'Error to get Sensor:', trim(Sensor), ' or SatPlat:', trim(SatId)
!         return
!      else
!         nObs = size(Array2D,1)
!      endif
!      return
!
!
!   end subroutine
!
!   function getFileType(FNumber)result(fileType) 
!      integer             :: FNumber
!      integer             :: fileType
!
!      type(acc), pointer :: f => null()
!
!      f => diagFile%root
!      do while(associated(f))
!         if (f%FNumber .eq. FNumber)then
!            fileType = f%fileType
!            return
!         endif
!         f => f%next
!      enddo
!      write(*,*)'error: File number does not exist:', FNumber
!      fileType = -1
!   end function

end module
