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
    // amount of deposit asset
    uint256 assets;
}

/// @dev Data structure for a new registered redemption
struct RedeemReceipts {
    // address of withdrawer
    address withdrawer;
    // amount of _shares
    uint256 _shares;
}

/// @dev An extension of ERC4626 that provides more functions to support rounds.
contract ERC4626ExtensionWithRound is Initializable, ERC4626Upgradeable, IERC4626ExtensionWithRound {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The state of vault. It can be LOCKED or UNLOCKED
    VaultState public override state;

    /// @dev The current round of vault. It starts from 0, and will add 1 when start a new round
    uint256 public override round;

    /// @dev The recepts of every registered deposits
    DepositReceipt[] public depositReceipts;

    /// @dev The recepts of every registered redemptions
    RedeemReceipts[] public redeemReceipts;

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
    function registerDeposit(uint256 _assets) external override onlyLocked returns (bool) {
        // Transfer _assets into vault
        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), _assets);

        // Create new deposit receipte and store it
        DepositReceipt memory newDeposit;
        newDeposit.assets = _assets;
        newDeposit.depositor = msg.sender;
        depositReceipts.push(newDeposit);

        emit RegisterDeposit(msg.sender, _assets, round);
        return true;
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function registerRedeem(uint256 _shares) external override onlyLocked returns (bool) {
        require(balanceOf(msg.sender) >= _shares, "_Shares are not enough");

        // Transfer _shares to this contract
        _transfer(msg.sender, address(this), _shares);

        // Create new redeem receipt and store it
        RedeemReceipts memory newRedemption;
        newRedemption._shares = _shares;
        newRedemption.withdrawer = msg.sender;
        redeemReceipts.push(newRedemption);

        emit RegisterRedeem(msg.sender, _shares, round);
        return true;
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function start() external override onlyLocked returns (bool) {
        require(depositReceipts.length == 0 && redeemReceipts.length == 0, "Unhandled receipts");

        round = round + 1;
        state = VaultState.LOCKED;

        emit Start(
            round,
            IERC20Upgradeable(asset()).balanceOf(address(this)),
            totalSupply()
        );

        return true;
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function end() external override onlyLocked returns (bool) {
        state = VaultState.UNLOCKED;

        emit End(
            round,
            IERC20Upgradeable(asset()).balanceOf(address(this)),
            totalSupply()
        );

        return true;
    }

    /// @dev See {IERC4626ExtensionWithRound}
    function settle() external override onlyUnlocked returns (bool) {
        uint256 newShares = _handleDepositReceipts();
        (uint256 burnShares, uint256 redeemAssets) = _handleRedeemReceipts();

        emit Settle(round, newShares, burnShares, redeemAssets);
        return true;
    }

    /// @dev Mint new _shares for every deposit receipts
    function _handleDepositReceipts() private onlyUnlocked returns (uint256 newShares) {
        // Issue new _shares
        for (uint256 i = 0; i < depositReceipts.length; i++) {
            uint256 _shares = previewDeposit(depositReceipts[i].assets);

            _mint(depositReceipts[i].depositor, _shares);

            newShares += _shares;
        }
    
        // Delete all receipts
        delete depositReceipts;
    }

    /// @dev Burn _shares and transfer assets for every redeem receipts
    function _handleRedeemReceipts() private onlyUnlocked returns (uint256 burnShares, uint256 redeemAssets) {
        // Burn _shares & transfer asset to withdrawer
        for (uint256 i = 0; i < redeemReceipts.length; i++) {
            uint256 assets = previewRedeem(redeemReceipts[i]._shares);

            _burn(address(this), redeemReceipts[i]._shares);

            IERC20Upgradeable(asset()).safeTransfer(redeemReceipts[i].withdrawer, assets);

            burnShares += redeemReceipts[i]._shares;
            redeemAssets += assets;
        }

        // Delete all receipts
        delete redeemReceipts;
    }
}
