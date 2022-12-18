! FONCTIONS À INTÉGRER
function to_integrate(t, y) result(equation)

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: t
    real(dp) :: y
    real(dp) :: equation

    ! equation : y' = f(t, y)
    !equation = cos(y) + t

    equation = 2 * (-sqrt(y - sqrt(y)) - sqrt(y) + 1)
end function

function to_integrate2ndOrder(t, y, yP) result(equation)

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: t
    real(dp) :: y
    real(dp) :: yP
    real(dp) :: equation

    ! equation : y'' = f(t, y, y')
    !equation = cos(y + yP) + t
    equation = 2 * y**3

end function

function ndOrderDiff(t, y, yP) result(equation)

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: t
    real(dp) :: y
    real(dp) :: yP
    real(dp) :: equation

    ! equation : df / dy, avec f = to_integrate2ndOrder
    !equation = - sin(y + yP)
    equation = 6 * y**2
end function

function ndOrderDiffDiff(t, y, yP) result(equation)

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: t
    real(dp) :: y
    real(dp) :: yP
    real(dp) :: equation

    ! equation : df / dyP, avec f = to_integrate2ndOrder
    !equation = - sin(y + yP)
    equation = 0

end function




! SCHÉMAS NUMÉRIQUES
subroutine runge_kutta(initial_time_value, to_integrate, initial_time, final_time, dt)
    ! y' = f(t, y)
    !       f = to_integrate
    !       y(initial_time) = initial_time_value

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: dt 
    integer :: number_of_steps, step

    real(dp) :: initial_time_value

    real(dp) :: initial_time
    real(dp) :: final_time
    
    real(dp) :: time, tmp

    real(dp) :: to_integrate
    real(dp), allocatable, dimension(:) :: solution

    real(dp) :: rk1, rk2, rk3, rk4

    integer :: io

    step = 1
    time = 0
    !dt = 0.01

    !initial_time = 0
    !final_time = 10

    !initial_time_value = 1       

    number_of_steps = (final_time - initial_time) / dt
     
    allocate( solution(number_of_steps) )
    solution(1) = initial_time_value

    open(newunit=io, file="runge_kutta.txt", action="write")

    do while (time < final_time)
        time = initial_time + step * dt ! peut être opti : time += step * dt
                                        ! mais besoin de changer la définition de time
        tmp = dt / 2

        rk1 = to_integrate(time, solution(step))
        rk2 = to_integrate(time + tmp, solution(step) + rk1 * tmp)
        rk3 = to_integrate(time + tmp, solution(step) + rk2 * tmp)
        rk4 = to_integrate(time + dt, solution(step) + rk3 * dt)
        
        solution(step + 1) = solution(step) + (rk1 + 2 * rk2 + 2 * rk3 + rk4) * dt / 6
        
        time = time + dt
        step = step + 1

        write(io, *) time, ' ', solution(step)
        
        !print *, solution(step)
        !print *, step
    end do

    close(io)    
    deallocate(solution)
end subroutine

subroutine nonlinear_shooting(initial_time_valueA, final_time_valueB, to_integrate2ndOrder, &
    ndOrderDiff, ndOrderDiffDiff, initial_time, final_time, tolerance, maxNumStep, numSubInter)
    ! Approximate the solution of the nonlinear boundary-value problem
    ! y''  = f(t, y, y')
    !       f = to_integrate
    !       y(initial_time) = initial_time_valueA
    !       y(final_time) = final_time_valueB
    ! https://www.webpages.uidaho.edu/~barannyk/Teaching/shooting_nonlinear.pdf
    use, intrinsic :: iso_fortran_env, only: dp=>real64
    implicit none

    real(dp) :: tolerance 
    integer :: step, maxNumStep, numSubInter

    real(dp) :: initial_time_valueA
    real(dp) :: final_time_valueB

    real(dp) :: initial_time
    real(dp) :: final_time
    
    real(dp) :: time, h

    real(dp) :: to_integrate2ndOrder
    real(dp) :: ndOrderDiff
    real(dp) :: ndOrderDiffDiff

    real(dp), allocatable, dimension(:) :: solution
    real(dp), allocatable, dimension(:) :: solutionPrime

    real(dp) :: TK, u1, u2
    real(dp) :: k11, k12, k21, k22, k31, k32, k41, k42
    real(dp) :: kP11, kP12, kP21, kP22, kP31, kP32, kP41, kP42
    integer :: io, i

    step = 1

    h = (final_time - initial_time) / (numSubInter + 1)
    
    TK = (final_time_valueB - initial_time_valueA) / (final_time - initial_time)
     
    allocate( solution(numSubInter) )
    allocate( solutionPrime(numSubInter) )

    open(newunit=io, file="nonlinear_shooting.txt", action="write")

    solution(1) = initial_time_valueA
    solutionPrime(1) = TK

    u1 = 0
    u2 = 1
    print *, h
    do while (step <= maxNumStep)

        do i = 2, numSubInter + 1       ! attention index

            time = initial_time + (i - 1) * h       ! attention index etc...
            !print *, 'TIME : ', time
            k11 = h * solutionPrime(i - 1)
            k12 = h * to_integrate2ndOrder(time, solution(i - 1), solutionPrime(i - 1))

            k21 = h * (solutionPrime(i - 1) + k12 / 2)
            k22 = h * to_integrate2ndOrder(time + h / 2, solution(i - 1) + k11 / 2, &
                  solutionPrime(i - 1) + k12 / 2)

            k31 = h * (solutionPrime(i - 1) + k22 / 2)
            k32 = h * to_integrate2ndOrder(time + h / 2, solution(i - 1) + k21 / 2, &
                  solutionPrime(i - 1) + k22 / 2)

            k41 = h * (solutionPrime(i - 1) + k32)
            k42 = h * to_integrate2ndOrder(time + h, solution(i - 1) + k31, solutionPrime(i - 1) + k32)

            solution(i) = solution(i - 1) + (k11 + 2 * k21 + 2 * k31 + k41) / 6
            solutionPrime(i) = solution(i - 1) + (k12 + 2 * k22 + 2 * k32 + k42) / 6

            kP11 = h * u2
            kP12 = h * (ndOrderDiff(time, solution(i - 1), solutionPrime(i - 1)) * u1 &
                   + ndOrderDiffDiff(time, solution(i - 1), solutionPrime(i - 1)) * u2)

            kP21 = h * (u2 * kP12 / 2)
            kp22 = h * (ndOrderDiff(time + h / 2, solution(i - 1), solution(i - 2)) * (u1 + kP11 / 2) &
            + ndOrderDiffDiff(time + h / 2, solution(i - 1), solutionPrime(i - 1)) * (u2 + kP12 / 2))

            kP31 = h * (u2 + kP22 / 2)
            kp32 = h * (ndOrderDiff(time + h / 2, solution(i - 1), solutionPrime(i - 1)) * (u1 + kP21 / 2) &
            + ndOrderDiffDiff(time + h / 2, solution(i - 1), solutionPrime(i - 1)) * (u2 + kP22 / 2))

            kP41 = h * (u2 + kP32)
            kp42 = h * (ndOrderDiff(time + h, solution(i - 1), solutionPrime(i - 1)) * (u1 + kP31) &
            + ndOrderDiffDiff(time + h, solution(i - 1), solutionPrime(i - 1)) * (u2 + kP32))

            u1 = u1 + (kP11 + 2 * kP21 + 2 * kP31 + kP41) / 6
            u2 = u2 + (kP12 + 2 * kP22 + 2 * kP32 + kP42) / 6

        end do

        if (abs(solution(numSubInter + 1) - final_time_valueB) <= tolerance) then
            
            do i = 2, numSubInter + 1
                
                time = initial_time + i * h

                write(io, *) time, solution(i), solutionPrime(i)
                print *, 'FINI'
            
            end do
        endif

        TK = TK - (solution(numSubInter + 1) - final_time_valueB) / u1
        step = step + 1

        !print *, 'STEP : ', step
        
    end do
    do i = 2, numSubInter + 1
                
        time = initial_time + i * h

        !write(io, *) time, solution(i), solutionPrime(i)
        write(io, *) time, solution(i)
    
    end do

    close(io)    
    deallocate(solution)
end subroutine

subroutine newmark_beta()
    ! M y'' + C y' + K y + R(y, y') = f
    !       f = to_integrate
    !       y(initial_time) = initial_time_value

    ! http://mms2.mines-paristech.fr/ef_paris/technologie/archives/f_Methode_Resolution.pdf
    ! https://people.duke.edu/~hpgavin/StructuralDynamics/NumericalIntegration.pdf
    ! https://tripop.inrialpes.fr/people/acary/talks/Slides-LMASeminar-Acary.pdf 
    
end subroutine

! LISTE VALEURS m/Q
module MASSECHARGE
contains
    function masses_to_charge_UAU() result(mQ)

        use, intrinsic :: iso_fortran_env, only: dp=>real64
        implicit none

        real(dp), dimension(26) :: mQ
        integer :: it

        it = 1

        ! https://file.scirp.org/pdf/JMP20100500002_52151070.pdf
        ! MeV/c^2
        mQ(1)  = -0.511        ! ELECTRON-
        mQ(2)  = -105.66       ! MUON-
        mQ(3)  = -1776.99      ! TAU-
        mQ(4)  = 139.57        ! PION+
        mQ(5)  = -139.57       ! PION-
        mQ(6)  = 134.98        ! PION NEUTRAL
        mQ(7)  = 493.686       ! KAON+
        mQ(8)  = -493.68       ! KAON-
        mQ(9)  = 497.65        ! KAON NEUTRAL
        mQ(10)  = 547.75        ! ETA NEUTRAL
        mQ(11)  = 775.8         ! RHO NEUTRAL
        mQ(12) = 782.59        ! OMEGA NEUTRAL
        mQ(13) = 1869.4        ! D MESON+
        mQ(14) = -1869.4       ! D MESON-
        mQ(15) = 1968.3        ! DS MESON+
        mQ(16) = -1968.3       ! DS MESON-
        mQ(17) = 5279.0        ! B MESON+
        mQ(18) = -5279.0       ! B MESON-
        mQ(19) = 5279.4        ! B MESON NEUTRAL
        mQ(20) = 5369.6        ! BS MESON NEUTRAL
        mQ(21) = 938.27        ! NUCLEON+
        mQ(22) = 939.56        ! NUCLEON NEUTRAL
        mQ(23) = 1116.68       ! LAMBDA NEUTRAL
        mQ(24) = 1187.37       ! SIGMA+
        mQ(25) = 1197.45       ! SIGMA-
        MQ(26) = 1192.64       ! SIGMA NEUTRAL

        ! 1 MeV/c^2 ---> 0.0010735441 unified atomic mass units

        ! Conversion en unité de masse atomique :
        do while(it <= 26)
            mQ(it) = mQ(it) * 0.0010735441
            it = it + 1
        end do

    end function
end module



! MAIN
program odeint

    use, intrinsic :: iso_fortran_env, only: dp=>real64
    use :: MASSECHARGE
    implicit none
    
    real(dp), external :: to_integrate
    real(dp), external :: to_integrate2ndOrder, ndOrderDiff, ndOrderDiffDiff

    !call runge_kutta(real(1, 8), to_integrate, real(0, 8), real(10, 8), real(0.01, 8))
    !call nonlinear_shooting(real(0.25, 8), real(2, 8), to_integrate2ndOrder, ndOrderDiff, &
    !     ndOrderDiffDiff, real(1, 8), real(0.2, 8), real(0.01, 8), 1000, 1000)

    print *, masses_to_charge_UAU()

    call runge_kutta(real(1, 8), to_integrate, real(0.1, 8), real(10, 8), real(0.001, 8))

end program odeint

