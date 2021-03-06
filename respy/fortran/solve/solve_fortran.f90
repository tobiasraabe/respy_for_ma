!******************************************************************************
!******************************************************************************
MODULE solve_fortran

    !/*	external modules	*/

    USE recording_solution

    USE shared_interface

    USE solve_auxiliary

    !/*	setup	*/

    IMPLICIT NONE

    PUBLIC

 CONTAINS
!******************************************************************************
!******************************************************************************
SUBROUTINE fort_solve(periods_rewards_systematic, states_number_period, mapping_state_idx, periods_emax, states_all, is_interpolated, num_points_interp, num_draws_emax, num_periods, is_myopic, is_debug, periods_draws_emax, edu_spec, optim_paras, file_sim)

    !/* external objects        */

    INTEGER(our_int), ALLOCATABLE, INTENT(INOUT)    :: mapping_state_idx(:, :, :, :, :, :)
    INTEGER(our_int), ALLOCATABLE, INTENT(INOUT)    :: states_number_period(:)
    INTEGER(our_int), ALLOCATABLE, INTENT(INOUT)    :: states_all(:, :, :)

    TYPE(OPTIMPARAS_DICT), INTENT(IN)               :: optim_paras
    TYPE(EDU_DICT), INTENT(IN)                      :: edu_spec

    INTEGER(our_int), INTENT(IN)                    :: num_points_interp
    INTEGER(our_int), INTENT(IN)                    :: num_draws_emax
    INTEGER(our_int), INTENT(IN)                    :: num_periods

    REAL(our_dble), ALLOCATABLE, INTENT(INOUT)      :: periods_rewards_systematic(:, :, :)
    REAL(our_dble), ALLOCATABLE, INTENT(INOUT)      :: periods_emax(: ,:)

    REAL(our_dble), INTENT(IN)                      :: periods_draws_emax(num_periods, num_draws_emax, 4)

    LOGICAL, INTENT(IN)                             :: is_interpolated
    LOGICAL, INTENT(IN)                             :: is_myopic
    LOGICAL, INTENT(IN)                             :: is_debug

    CHARACTER(225), INTENT(IN)                      :: file_sim

    !/* internal objects    */


!------------------------------------------------------------------------------
! Algorithm
!------------------------------------------------------------------------------

    CALL record_solution(1, file_sim)

    CALL fort_create_state_space(states_all, states_number_period, mapping_state_idx, num_periods, num_types, edu_spec)

    CALL record_solution(-1, file_sim)

    CALL record_solution(2, file_sim)

    CALL fort_calculate_rewards_systematic(periods_rewards_systematic, num_periods, states_number_period, states_all, max_states_period, optim_paras)

    CALL record_solution(-1, file_sim)

    CALL record_solution(3, file_sim)

    CALL fort_backward_induction(periods_emax, num_periods, is_myopic, max_states_period, periods_draws_emax, num_draws_emax, states_number_period, periods_rewards_systematic, mapping_state_idx, states_all, is_debug, is_interpolated, num_points_interp, edu_spec, optim_paras, file_sim, .True.)

    IF (.NOT. is_myopic) THEN
        CALL record_solution(-1, file_sim)
    ELSE
        CALL record_solution(-2, file_sim)
    END IF

END SUBROUTINE
!******************************************************************************
!******************************************************************************
END MODULE
