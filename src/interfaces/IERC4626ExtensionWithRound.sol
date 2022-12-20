pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC4626 extension with round
 */
interface IERC4626ExtensionWithRound {
    /**
     * @dev `VaultState` enum is a type that represents the current state of a vault.
     * It has two possible values:
     * 1. LOCKED: The vault is locked and the assets cannot be deposited/withdrew
     * 2. UNLOCKED: The vault is unlocked and the assets can be be deposited/withdrew
     */
    enum VaultState {LOCKED, UNLOCKED}

    /**
     * @dev Returns the current `state` of vault
     */
    function state() external view returns (VaultState state);

    /**
     * @dev Returns the current `round` number
     */
    function round() external view returns (uint256 round);

    /**
     * @dev Schedules a deposit with caller's `assets`
     *
     * @notice Should only be called when vault is LOCKED
     *
     * Emits a {ScheduleDeposit} event.
     */
    function scheduleDeposit(uint256 assets) external;

    /**
     * @dev Schedules a redemption with caller's `shares`
     *
     * @notice Should only be called when vault is LOCKED
     *
     * Emits a {ScheduleRedeem} event.
     */
    function scheduleRedeem(uint256 shares) external;

    /**
     * @dev Settles all scheduled deposits for `depositor`
     *
     * Returns the amount of `newShares` received by depositor
     *
     * @notice Should only be called when vault is UNLOCKED
     *
     * Emits a {SettleDeposits} event.
     */
    function settleDeposits(address depositor) external returns (uint256 newShares);

    /**
     * @dev Settles all scheduled redemptions for `redeemer`
     *
     * Returns the amount of `burnShares` and the amount of `redeemAssets` received by redeemer
     *
     * @notice Should only be called when vault is UNLOCKED
     *
     * Emits a {SettleRedemptions} event.
     */
    function settleRedemptions(address redeemer) external returns (uint256 burnShares, uint256 redeemAssets);

    /**
     * @dev Returns the `totalAssets` of scheduled deposits owned by `depositor`
     */
    function getScheduledDeposits(address depositor) external view returns (uint256 totalAssets);

    /**
     * @dev Returns the `totalShares` of scheduled redemptions owned by `redeemer`
     */
    function getScheduledRedemptions(address redeemer) external view returns (uint256 totalShares);

    /**
     * @dev Emitted when `sender` schedules a new deposit with `assets` in the `round`
     */
    event ScheduleDeposit(address indexed sender, uint256 assets, uint256 round);

    /**
     * @dev Emitted when `sender` schedules a new redemption with `shares` in the `round`
     */
    event ScheduleRedeem(address indexed sender, uint256 shares, uint256 round);

    /**
     * @dev Emitted when `depositor`'s scheduled deposits are settled,
     * and depositor received `newShares` when the `round` is end
     */
    event SettleDeposits(address indexed depositor, uint256 newShares, uint256 round);

    /**
     * @dev Emitted when `redeemer`'s scheduled redemptions are settled,
     * and `burnShares` are burned and redeemer received `redeemAssets` when the `round` is end
     */
    event SettleRedemptions(address indexed redeemer, uint256 burnShares, uint256 redeemAssets, uint256 round);
}
