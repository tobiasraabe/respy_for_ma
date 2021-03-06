MODULE shared_containers

    ! This module declares all those variables that are required as part of the evaluation of the criterion function.
    USE shared_interfaces

    USE shared_constants

    USE shared_types

    !/* setup                   */

    IMPLICIT NONE

!******************************************************************************
!******************************************************************************

    ! Containers required for the evaluation of the criterion function
    INTEGER(our_int), ALLOCATABLE   :: mapping_state_idx(:, :, :, :, :, :)
    INTEGER(our_int), ALLOCATABLE   :: states_number_period(:)
    INTEGER(our_int), ALLOCATABLE   :: states_all(:, :, :)

    REAL(our_dble), ALLOCATABLE     :: periods_rewards_systematic(:, :, :)
    REAL(our_dble), ALLOCATABLE     :: periods_draws_prob(:, :, :)
    REAL(our_dble), ALLOCATABLE     :: periods_draws_emax(:, :, :)
    REAL(our_dble), ALLOCATABLE     :: periods_emax(:, :)
    REAL(our_dble), ALLOCATABLE     :: data_est(:, :)

    REAL(our_dble), ALLOCATABLE     :: precond_matrix(:, :)

    REAL(our_dble), ALLOCATABLE     :: x_all_start(:)

    REAL(our_dble)                  :: dfunc_eps
    REAL(our_dble)                  :: tau

    INTEGER(our_int), ALLOCATABLE   :: num_obs_agent(:)

    LOGICAL                         :: is_interpolated
    LOGICAL                         :: is_myopic
    LOGICAL                         :: is_debug

    LOGICAL                         :: crit_estimation = .False.

    ! Parameters for the optimization
    TYPE(OPTIMIZER_COLLECTION)      :: optimizer_options
    TYPE(OPTIMPARAS_DICT)           :: optim_paras
    TYPE(EDU_DICT)                  :: edu_spec

    INTEGER(our_int)                :: maxfun

    PROCEDURE(interface_func), POINTER  :: criterion_function => null ()

!******************************************************************************
!******************************************************************************
END MODULE
