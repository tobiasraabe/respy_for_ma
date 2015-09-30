!*******************************************************************************
!*******************************************************************************
!
!   Interface to ROBUPY library. This is the front-end to all functionality. 
!   Subroutines and functions for the case of risk-only case are in the 
!   robufort_risk module. Building on the risk-only functionality, the module
!   robufort_ambugity provided the required subroutines and functions for the 
!   case of ambiguity.
!
!*******************************************************************************
!*******************************************************************************
MODULE robufort_library

	!/*	external modules	*/

    USE robufort_constants

    USE robufort_auxiliary

    USE robufort_ambiguity

    USE robufort_emax

    USE robufort_risk

	!/*	setup	*/

	IMPLICIT NONE

    PUBLIC
    
 CONTAINS
!*******************************************************************************
!*******************************************************************************
SUBROUTINE simulate_sample(dataset, num_agents, states_all, num_periods, &
                mapping_state_idx, periods_payoffs_ex_ante, &
                periods_eps_relevant, edu_max, edu_start, periods_emax, delta)

    !/* external objects    */

    REAL(our_dble), INTENT(OUT)     :: dataset(num_agents*num_periods, 8)

    REAL(our_dble), INTENT(IN)      :: periods_emax(:, :)
    REAL(our_dble), INTENT(IN)      :: periods_payoffs_ex_ante(:, :, :)
    REAL(our_dble), INTENT(IN)      :: periods_eps_relevant(:, :, :)
    REAL(our_dble), INTENT(IN)      :: delta

    INTEGER(our_int), INTENT(IN)    :: num_periods
    INTEGER(our_int), INTENT(IN)    :: edu_start

    INTEGER(our_int), INTENT(IN)    :: edu_max
    INTEGER(our_int), INTENT(IN)    :: num_agents
    INTEGER(our_int), INTENT(IN)    :: mapping_state_idx(:, :, :, :, :)
    INTEGER(our_int), INTENT(IN)    :: states_all(:, :, :)

    !/* internal objects    */

    INTEGER(our_int)                :: i   
    INTEGER(our_int)                :: k
    INTEGER(our_int)                :: period
    INTEGER(our_int)                :: exp_A
    INTEGER(our_int)                :: exp_B
    INTEGER(our_int)                :: edu
    INTEGER(our_int)                :: edu_lagged
    INTEGER(our_int)                :: choice(1)
    INTEGER(our_int)                :: count
    INTEGER(our_int)                :: current_state(4)

    REAL(our_dble)                  :: payoffs_ex_post(4)
    REAL(our_dble)                  :: payoffs_ex_ante(4)
    REAL(our_dble)                  :: disturbances(4)
    REAL(our_dble)                  :: future_payoffs(4)
    REAL(our_dble)                  :: total_payoffs(4)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    ! Initialize containers
    dataset = missing_dble

    ! Iterate over agents and periods
    count = 0

    DO i = 0, (num_agents - 1)

        ! Baseline state
        current_state = states_all(1, 1, :)
        
        DO period = 0, (num_periods - 1)
            
            ! Distribute state space
            exp_A = current_state(1)
            exp_B = current_state(2)
            edu = current_state(3)
            edu_lagged = current_state(4)
            
            ! Getting state index
            k = mapping_state_idx(period + 1, exp_A + 1, exp_B + 1, edu + 1, edu_lagged + 1)

            ! Write agent identifier and current period to data frame
            dataset(count + 1, 1) = DBLE(i)
            dataset(count + 1, 2) = DBLE(period)

            ! Calculate ex post payoffs
            payoffs_ex_ante = periods_payoffs_ex_ante(period + 1, k + 1, :)
            disturbances = periods_eps_relevant(period + 1, i + 1, :)

            ! Calculate total utilities
            CALL get_total_value(total_payoffs, payoffs_ex_post, & 
                    future_payoffs, period, num_periods, delta, &
                    payoffs_ex_ante, disturbances, edu_max, edu_start, & 
                    mapping_state_idx, periods_emax, k, states_all)

            ! Write relevant state space for period to data frame
            dataset(count + 1, 5:8) = current_state

            ! Special treatment for education
            dataset(count + 1, 7) = dataset(count + 1, 7) + edu_start

            ! Determine and record optimal choice
            choice = MAXLOC(total_payoffs) 

            dataset(count + 1, 3) = DBLE(choice(1)) 

            !# Update work experiences and education
            IF (choice(1) .EQ. one_int) THEN 
                current_state(1) = current_state(1) + 1
            END IF

            IF (choice(1) .EQ. two_int) THEN 
                current_state(2) = current_state(2) + 1
            END IF

            IF (choice(1) .EQ. three_int) THEN 
                current_state(3) = current_state(3) + 1
            END IF
            
            IF (choice(1) .EQ. three_int) THEN 
                current_state(4) = one_int
            ELSE
                current_state(4) = zero_int
            END IF

            ! Record earnings
            IF (choice(1) .EQ. one_int) THEN
                dataset(count + 1, 4) = payoffs_ex_post(1)
            END IF

            IF (choice(1) .EQ. two_int) THEN
                dataset(count + 1, 4) = payoffs_ex_post(2)
            END IF

            ! Update row indicator
            count = count + 1

        END DO

    END DO

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE calculate_payoffs_ex_ante(periods_payoffs_ex_ante, num_periods, &
              states_number_period, states_all, edu_start, coeffs_A, coeffs_B, & 
              coeffs_edu, coeffs_home, max_states_period)

    !/* external objects    */

    REAL(our_dble), INTENT(OUT)     :: periods_payoffs_ex_ante(num_periods, max_states_period, 4)

    REAL(our_dble), INTENT(IN)      :: coeffs_A(:)
    REAL(our_dble), INTENT(IN)      :: coeffs_B(:)
    REAL(our_dble), INTENT(IN)      :: coeffs_edu(:)
    REAL(our_dble), INTENT(IN)      :: coeffs_home(:)

    INTEGER(our_int), INTENT(IN)    :: num_periods
    INTEGER(our_int), INTENT(IN)    :: states_number_period(:)
    INTEGER(our_int), INTENT(IN)    :: states_all(:,:,:)
    INTEGER(our_int), INTENT(IN)    :: edu_start
    INTEGER(our_int), INTENT(IN)    :: max_states_period

    !/* internals objects    */

    INTEGER(our_int)                :: period
    INTEGER(our_int)                :: k
    INTEGER(our_int)                :: exp_A
    INTEGER(our_int)                :: exp_B
    INTEGER(our_int)                :: edu
    INTEGER(our_int)                :: edu_lagged
    INTEGER(our_int)                :: covars(6)

    REAL(our_dble)                  :: payoff

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    ! Logging
    CALL logging_solution(2)

    ! Initialize missing value
    periods_payoffs_ex_ante = missing_dble

    ! Calculate systematic instantaneous payoffs
    DO period = num_periods, 1, -1

        ! Loop over all possible states
        DO k = 1, states_number_period(period)

            ! Distribute state space
            exp_A = states_all(period, k, 1)
            exp_B = states_all(period, k, 2)
            edu = states_all(period, k, 3)
            edu_lagged = states_all(period, k, 4)

            ! Auxiliary objects
            covars(1) = one_int
            covars(2) = edu + edu_start
            covars(3) = exp_A
            covars(4) = exp_A ** 2
            covars(5) = exp_B
            covars(6) = exp_B ** 2

            ! Calculate systematic part of payoff in occupation A
            periods_payoffs_ex_ante(period, k, 1) =  &
                EXP(DOT_PRODUCT(covars, coeffs_A))

            ! Calculate systematic part of payoff in occupation B
            periods_payoffs_ex_ante(period, k, 2) = &
                EXP(DOT_PRODUCT(covars, coeffs_B))

            ! Calculate systematic part of schooling utility
            payoff = coeffs_edu(1)

            ! Tuition cost for higher education if agents move
            ! beyond high school.
            IF(edu + edu_start >= 12) THEN

                payoff = payoff + coeffs_edu(2)
            
            END IF

            ! Psychic cost of going back to school
            IF(edu_lagged == 0) THEN
            
                payoff = payoff + coeffs_edu(3)
            
            END IF
            periods_payoffs_ex_ante(period, k, 3) = payoff

            ! Calculate systematic part of payoff in home production
            periods_payoffs_ex_ante(period, k, 4) = coeffs_home(1)

        END DO

    END DO

    ! Logging
    CALL logging_solution(-1)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE backward_induction(periods_emax, periods_payoffs_ex_post, &
                periods_future_payoffs, num_periods, max_states_period, &
                periods_eps_relevant, num_draws, states_number_period, & 
                periods_payoffs_ex_ante, edu_max, edu_start, &
                mapping_state_idx, states_all, delta, is_debug, shocks, &
                level)

    !/* external objects    */

    REAL(our_dble), INTENT(OUT)     :: periods_emax(num_periods, max_states_period)
    REAL(our_dble), INTENT(OUT)     :: periods_payoffs_ex_post(num_periods, max_states_period, 4)
    REAL(our_dble), INTENT(OUT)     :: periods_future_payoffs(num_periods, max_states_period, 4)

    REAL(our_dble), INTENT(IN)      :: periods_eps_relevant(:, :, :)
    REAL(our_dble), INTENT(IN)      :: periods_payoffs_ex_ante(:, :, :   )
    REAL(our_dble), INTENT(IN)      :: delta
    REAL(our_dble), INTENT(IN)      :: level
    REAL(our_dble), INTENT(IN)      :: shocks(:, :)

    INTEGER(our_int), INTENT(IN)    :: mapping_state_idx(:, :, :, :, :)    
    INTEGER(our_int), INTENT(IN)    :: num_periods
    INTEGER(our_int), INTENT(IN)    :: edu_start
    INTEGER(our_int), INTENT(IN)    :: edu_max
    INTEGER(our_int), INTENT(IN)    :: states_number_period(:)
    INTEGER(our_int), INTENT(IN)    :: num_draws
    INTEGER(our_int), INTENT(IN)    :: max_states_period
    INTEGER(our_int), INTENT(IN)    :: states_all(:, :, :)

    LOGICAL, INTENT(IN)             :: is_debug

    !/* internals objects    */

    INTEGER(our_int)                :: period
    INTEGER(our_int)                :: k

    REAL(our_dble)                  :: eps_relevant(num_draws, 4)
    REAL(our_dble)                  :: payoffs_ex_ante(4)
    REAL(our_dble)                  :: payoffs_ex_post(4)
    REAL(our_dble)                  :: future_payoffs(4)
    REAL(our_dble)                  :: emax_simulated

    LOGICAL                         :: is_ambiguous

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    ! Auxiliary objects
    is_ambiguous = level .GT. zero_dble

    ! Set to missing value
    periods_emax = missing_dble
    periods_future_payoffs = missing_dble
    periods_payoffs_ex_post = missing_dble
    
    ! Logging
    CALL logging_solution(3)

    ! Backward induction
    DO period = (num_periods - 1), 0, -1
    
        ! Logging
        CALL logging_solution(4, period)

        ! Extract disturbances
        eps_relevant = periods_eps_relevant(period + 1, :, :)

        ! Loop over all possible states
        DO k = 0, (states_number_period(period + 1) - 1)

            ! Extract payoffs
            payoffs_ex_ante = periods_payoffs_ex_ante(period + 1, k + 1, :)

            ! BEGIN VECTORIZATION SPLIT
            IF (is_ambiguous) THEN
                CALL get_payoffs_ambiguity(emax_simulated, payoffs_ex_post, &
                        future_payoffs, num_draws, eps_relevant, period, k, & 
                        payoffs_ex_ante, edu_max, edu_start, &
                        mapping_state_idx, states_all, num_periods, &
                        periods_emax, delta, is_debug, shocks, level)
            ELSE

                CALL get_payoffs_risk(emax_simulated, payoffs_ex_post, & 
                        future_payoffs, num_draws, eps_relevant, period, k, & 
                        payoffs_ex_ante, edu_max, edu_start, & 
                        mapping_state_idx, states_all, num_periods, &
                        periods_emax, delta)
            END IF
            ! END VECTORIZATION SPLIT
            
            
            ! Collect information            
            periods_payoffs_ex_post(period + 1, k + 1, :) = payoffs_ex_post
            periods_future_payoffs(period + 1, k + 1, :) = future_payoffs
            periods_emax(period + 1, k + 1) = emax_simulated

        END DO

    END DO

    ! Logging
    CALL logging_solution(-1)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE create_state_space(states_all, states_number_period, &
                mapping_state_idx, num_periods, edu_start, edu_max, min_idx)

    !/* external objects    */

    INTEGER(our_int), INTENT(OUT)   :: states_all(num_periods, 100000, 4)
    INTEGER(our_int), INTENT(OUT)   :: states_number_period(num_periods)
    INTEGER(our_int), INTENT(OUT)   :: mapping_state_idx(num_periods, & 
                                        num_periods, num_periods, min_idx, 2)

    INTEGER(our_int), INTENT(IN)    :: num_periods
    INTEGER(our_int), INTENT(IN)    :: edu_start
    INTEGER(our_int), INTENT(IN)    :: edu_max
    INTEGER(our_int), INTENT(IN)    :: min_idx

    !/* internals objects    */

    INTEGER(our_int)                :: edu_lagged
    INTEGER(our_int)                :: period
    INTEGER(our_int)                :: total
    INTEGER(our_int)                :: exp_A
    INTEGER(our_int)                :: exp_B
    INTEGER(our_int)                :: edu
    INTEGER(our_int)                :: k
 
!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    ! Initialize output 
    states_number_period = missing_int
    mapping_state_idx    = missing_int
    states_all           = missing_int

    ! Logging
    CALL logging_solution(1)

    ! Construct state space by periods
    DO period = 0, (num_periods - 1)

        ! Count admissible realizations of state space by period
        k = 0

        ! Loop over all admissible work experiences for occupation A
        DO exp_A = 0, num_periods

            ! Loop over all admissible work experience for occupation B
            DO exp_B = 0, num_periods
                
                ! Loop over all admissible additional education levels
                DO edu = 0, num_periods

                    ! Agent cannot attain more additional education
                    ! than (EDU_MAX - EDU_START).
                    IF (edu .GT. edu_max - edu_start) THEN
                        CYCLE
                    END IF

                    ! Loop over all admissible values for leisure. Note that
                    ! the leisure variable takes only zero/value. The time path
                    ! does not matter.
                    DO edu_lagged = 0, 1

                        ! Check if lagged education admissible. (1) In the
                        ! first period all agents have lagged schooling equal
                        ! to one.
                        IF (edu_lagged .EQ. zero_int) THEN
                            IF (period .EQ. zero_int) THEN
                                CYCLE
                            END IF
                        END IF
                        
                        ! (2) Whenever an agent has not acquired any additional
                        ! education and we are not in the first period,
                        ! then this cannot be the case.
                        IF (edu_lagged .EQ. one_int) THEN
                            IF (edu .EQ. zero_int) THEN
                                IF (period .GT. zero_int) THEN
                                    CYCLE
                                END IF
                            END IF
                        END IF

                        ! (3) Whenever an agent has only acquired additional
                        ! education, then edu_lagged cannot be zero.
                        IF (edu_lagged .EQ. zero_int) THEN
                            IF (edu .EQ. period) THEN
                                CYCLE
                            END IF
                        END IF

                        ! Check if admissible for time constraints
                        total = edu + exp_A + exp_B

                        ! Note that the total number of activities does not
                        ! have is less or equal to the total possible number of
                        ! activities as the rest is implicitly filled with
                        ! leisure.
                        IF (total .GT. period) THEN
                            CYCLE
                        END IF
                        
                        ! Collect all possible realizations of state space
                        states_all(period + 1, k + 1, 1) = exp_A
                        states_all(period + 1, k + 1, 2) = exp_B
                        states_all(period + 1, k + 1, 3) = edu
                        states_all(period + 1, k + 1, 4) = edu_lagged

                        ! Collect mapping of state space to array index.
                        mapping_state_idx(period + 1, exp_A + 1, exp_B + 1, & 
                            edu + 1 , edu_lagged + 1) = k

                        ! Update count
                        k = k + 1

                     END DO

                 END DO

             END DO

         END DO
        
        ! Record maximum number of state space realizations by time period
        states_number_period(period + 1) = k

      END DO

      ! Logging
      CALL logging_solution(-1)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
END MODULE  