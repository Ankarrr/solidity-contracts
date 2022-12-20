pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol";
import "./interfaces/IERC4626ExtensionWithRound.sol";

/// @dev Data structure for a new registered deposit
struct DepositReceipt {
    // address of depositor
    address depositor;
    // amount of deposited assets
    uint256 assets;
}

/// @dev Data structure for a new registered redemption
struct RedeemReceipt {
    // address of withdrawer
    address withdrawer;
    // amount of shares
    uint256 shares;
}

/// @dev An extension of ERC4626 that provides more functions to support rounds.
contract ERC4626ExtensionWithRound is Initializable, ERC4626Upgradeable, IERC4626ExtensionWithRound {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The state of vault. It can be LOCKED or UNLOCKED
    VaultState public override state;

    /// @dev The current round of vault. It starts from 0, and will add 1 when start a new round
    uint256 public override round;

    /// @dev The recepts of every registered deposits
    mapping(address => DepositReceipt[]) public depositReceipts;

    /// @dev The recepts of every registered redemptions
    mapping(address => RedeemReceipt[]) public redeemReceipts;

    /// @dev Throw if the vault state is LOCKED
    modifier onlyUnlocked {
        require(state == VaultState.UNLOCKED, "Vault is locked");
        _;
    }

    /// @dev Throw if the vault state is UNLOCKED
    modifier onlyLocked {
        require(state == VaultState.LOCKED, "Vault is unlocked");
        _;
    }

    /// @dev Initialize this contract
    function __ERC4626ExtensionWithRound_init() internal onlyInitializing {
        state = VaultState.UNLOCKED;
        round = 0;
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function getScheduledDeposits(address _depositor) external view override returns (uint256 totalAssets) {
        for (uint256 i = 0; i < depositReceipts[_depositor].length; i++) {
            totalAssets += depositReceipts[_depositor][i].assets;
        }
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function getScheduledRedemptions(address _redeemer) external view override returns (uint256 totalShares) {
        for (uint256 i = 0; i < redeemReceipts[_redeemer].length; i++) {
            totalShares += redeemReceipts[_redeemer][i].shares;
        }
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function scheduleDeposit(uint256 _assets) external override onlyLocked {
        // Transfer _assets into vault
        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), _assets);

        // Create new deposit receipte and store it
        DepositReceipt memory newDeposit;
        newDeposit.assets = _assets;
        newDeposit.depositor = msg.sender;
        depositReceipts[msg.sender].push(newDeposit);

        emit ScheduleDeposit(msg.sender, _assets, round);
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function scheduleRedeem(uint256 _shares) external override onlyLocked {
        // Transfer _shares to this contract
        _transfer(msg.sender, address(this), _shares);

        // Create new redeem receipt and store it
        RedeemReceipt memory newRedemption;
        newRedemption.shares = _shares;
        newRedemption.withdrawer = msg.sender;
        redeemReceipts[msg.sender].push(newRedemption);

        emit ScheduleRedeem(msg.sender, _shares, round);
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function settleDeposits(address _depositor) external override onlyUnlocked returns (uint256 newShares) {
        for (uint256 i = 0; i < depositReceipts[_depositor].length; i++) {
            uint256 _shares = previewDeposit(depositReceipts[_depositor][i].assets);
            newShares += _shares;
        }
        // Mint new shares
        _mint(_depositor, newShares);

        delete depositReceipts[_depositor];

        emit SettleDeposits(_depositor, newShares, round);
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function settleRedemptions(address _redeemer) external override onlyUnlocked returns (uint256 burnShares, uint256 redeemAssets) {
        for (uint256 i = 0; i < redeemReceipts[_redeemer].length; i++) {
            uint256 assets = previewRedeem(redeemReceipts[_redeemer][i].shares);
            burnShares += redeemReceipts[_redeemer][i].shares;
            redeemAssets += assets;
        }
        // Burn shares and transfer assets to _redeemer
        _burn(address(this), burnShares);
        IERC20Upgradeable(asset()).safeTransfer(_redeemer, redeemAssets);

        delete redeemReceipts[_redeemer];

        emit SettleRedemptions(_redeemer, burnShares, redeemAssets, round);
    }
}
