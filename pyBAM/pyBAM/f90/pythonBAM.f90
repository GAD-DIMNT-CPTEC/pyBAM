module pythonBAM
   use iso_c_binding
   use sigio_BAMMod, only: bamFile
   use typeKinds, only: Double
   Implicit None
   Private

   Public :: open
   Public :: close
   Public :: getDim
   Public :: getField
   Public :: getNLevels
   Public :: getVerticalLevels
   Public :: getNVars
   public :: getVarNames
   public :: readField
   public :: spec2grid
   
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
      else
         print*,level, minval(Array2D),maxval(Array2D)
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

   function getVerticalLevels(FNumber)result(nLevels)
      integer, intent(in) :: FNumber
      integer             :: nLevels

      real, parameter           :: ps  = 1000.0
      real(DOuble), allocatable :: ak(:), bk(:)
      integer                   :: i
      type(acc),        pointer :: d => null()
      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      nLevels = d%bam%getOneDim('kmax')
      allocate(array1d(nLevels))

      if (d%bam%isHybrid)then
         allocate(ak(nLevels+1))
         allocate(bk(nLevels+1))

         call d%bam%getVerticalCoord('ak',ak)
         call d%bam%getVerticalCoord('bk',bk)
 
         do i=1,nLevels
            array1d(i) = (ak(i)/100.0) + bk(i)*ps
         enddo

      else
 
         call d%bam%getVerticalCoord('sl',bk)
         do i=1,nLevels
            array1d(i) =  bk(i)*ps
         enddo

      endif

   end function

   function readField(FNumber, fieldName, level) result(iret)
      integer,          intent(in) :: FNumber
      character(len=*), intent(in) :: fieldName
      integer,          intent(in) :: level
      integer :: iret

      integer :: fldSize

      type(acc), pointer :: d => null()

      iret = 0
      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      fldSize = d%bam%getOFS(fieldName)
      allocate(Array1D(fldSize))
      call d%bam%getOField(fieldName, level, Array1D, istat=iret)
      if (iret .ne. 0)then
         deallocate(Array1D)
      endif
      
      return   
   end function

   function getNVars(FNumber) result(nVars)
      integer, intent(in) :: FNumber
      integer             :: nVars

      type(acc),        pointer :: d => null()

      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      nVars = d%bam%fcount

      return
     
   end function

   subroutine getVarNames(FNumber, nVars, varNames)
      integer, intent(in) :: FNumber
      integer, intent(in) :: nVars
      character*45, dimension(nVars), intent(out) :: varNames

      type(acc),        pointer :: d => null()
      character(len=45), allocatable :: vTable(:)

      integer :: i
      
      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      allocate(vTable(nVars))
      call  d%bam%getVarNames(vTable)

      do i=1,nVars
         varNames(i) = vTable(i)
      enddo
!      nVars = d%bam%fcount
!      allocate(charArray1D(nVars))
!      call  d%bam%getVarNames(charArray1D)
!      print*,nVars
!      do i =1, nVars
!         print*,i, charArray1D(i)
!      enddo
!

   end subroutine

   function spec2grid(FNumber, spec) result(iret)
      integer, intent(in) :: FNumber
      real,    intent(in) :: spec(:)
      integer :: iret

      real(Double), allocatable :: spec8(:)
      real(Double), allocatable :: grid8(:)
      integer :: imax
      integer :: jmax
      integer :: i, j, k
      type(acc), pointer :: d => null()

      d => accessFile%root
      do while(associated(d))
         if(FNumber.eq.d%FNumber) exit
         d => d%next
      enddo

      allocate(spec8(size(spec)))
      spec8 = real(spec,Double)

      imax = d%bam%getOneDim('imax')
      jmax = d%bam%getOneDim('jmax')
      
      allocate(grid8(imax*jmax))
      call d%bam%Spec2Grid(spec8,grid8)

      deallocate(spec8)
      allocate(Array2D(imax,jmax))

      k = 1
      do j=1,jMax
         do i=1,iMax
            array2D(i,j) = real(grid8(k),4)
            k = k + 1
         enddo
      enddo

      deallocate(grid8)
      
      iret = 0

      return

   end function
   
end module
