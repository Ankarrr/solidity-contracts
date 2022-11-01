pragma solidity ^0.8.0;

interface IERC4626ExtensionWithRound {
    enum VaultState {LOCKED, UNLOCKED}

    function state() external view returns (VaultState state);

    function round() external view returns (uint256 round);

    function registerDeposit(uint256 assets) external returns (bool);

    function registerRedeem(uint256 shares) external returns (bool);

    function start() external returns (bool);

    function end() external returns (bool);

    function settle() external returns (bool);

    event RegisterDeposit(address indexed sender, uint256 assets, uint256 round);

    event RegisterRedeem(address indexed sender, uint256 shares, uint256 round);

    event Start(uint256 indexed round, uint256 assets, uint256 shares);

    event End(uint256 indexed round, uint256 assets, uint256 shares);

    event Settle(uint256 indexed round, uint256 newShares, uint256 burnShares, uint256 redeemAssets);

    event StateUpdate(VaultState indexed state);
}
