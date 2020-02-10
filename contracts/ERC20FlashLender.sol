pragma solidity 0.6.0;


import "./IERC20FlashBorrower.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dev-v3.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dev-v3.0/contracts/token/ERC20/IERC20.sol";



// @notice Any contract that inherits this contract becomes a flash lender of any/all ERC20 tokens that it holds
// @dev DO NOT USE. This is has not been audited.
contract ERC20FlashLender {
    using SafeMath for uint256;

    uint256 internal _tokenBorrowFee; // e.g.: 0.003e18 means 0.3% fee

    uint256 constant internal ONE = 1e18;

    // @notice Borrow tokens via a flash loan. See ERC20FlashBorrower for example.
    // @audit Necessarily violates checks-effects-interactions pattern.
    // @audit This _shouldn't_ need a `nonReentrant` modifier. Please double check this.
    // Reentering via this function allows several different ERC20 flash loans in a single txn
    function ERC20FlashLoan(address token, uint256 amount) external {

        // record debt
        uint256 debt = amount.mul(ONE.add(_tokenBorrowFee)).div(ONE);

        // send borrower the tokens
        require(IERC20(token).transfer(msg.sender, amount), "borrow failed");

        // hand over control to borrower
        IERC20FlashBorrower(msg.sender).executeOnERC20FlashLoan(token, amount, debt);

        // repay the debt
        require(IERC20(token).transferFrom(msg.sender, address(this), debt), "repayment failed");
    }

    function tokenBorrowerFee() public view returns (uint256) {
        return _tokenBorrowFee;
    }
}
