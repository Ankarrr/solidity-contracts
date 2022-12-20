pragma solidity ^0.8.0;

interface IERC4626ExtensionWithRound {
    enum VaultState {LOCKED, UNLOCKED}

    function state() external view returns (VaultState state);

    function round() external view returns (uint256 round);

    function scheduleDeposit(uint256 assets) external;

    function scheduleRedeem(uint256 shares) external;

    function settleDeposits(address depositor) external returns (uint256 newShares);

    function settleRedemptions(address redeemer) external returns (uint256 burnShares, uint256 redeemAssets);

    function getScheduledDeposits(address depositor) external view returns (uint256 totalAssets);

    function getScheduledRedemptions(address redeemer) external view returns (uint256 totalShares);

    event ScheduleDeposit(address indexed sender, uint256 assets, uint256 round);

    event ScheduleRedeem(address indexed sender, uint256 shares, uint256 round);

    event SettleDeposits(address indexed depositor, uint256 newShares, uint256 round);

    event SettleRedemptions(address indexed redeemer, uint256 burnShares, uint256 redeemAssets, uint256 round);
}
