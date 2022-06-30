pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    using SafeMath for uint;

    /*
        @dev: Event to tell client allowance changes
    */
    event AllowanceChangeEvent(
        address indexed _forWho, 
        address indexed _fromWho, 
        uint _oldAmount, 
        uint _newAmount
    );

    /*
        @dev: Stores withdraw amount allowed per address
    */
    mapping(address => uint) public allowance;

    /* 
        @dev: Verifies if sender is the wallet owner. If not, verifies if sender is allowed to perform the transaction
    */
    modifier ownerOrAllowed(uint _amount) {
        require(owner() == msg.sender || allowance[msg.sender] >= _amount, "Forbbiden: Not allowed to perform this action.");
        _;
    }
    
    /* 
        @dev: Function to add a new address as allowed to withdraw certain amount
        @dev: Only for owner calls
    */
    function addAllowance(address _who, uint _amount) public onlyOwner {
        allowance[_who] = _amount;
        emit AllowanceChangeEvent(_who, msg.sender, _amount, allowance[msg.sender]);
    }
    
    /*
        @dev: Function to reduce the allowed amount to withdraw
        @dev: Only for internal calls
    */
    function reduceAllowance(address _who, uint _amount) internal {
        allowance[_who] = allowance[_who].sub(_amount);
        emit AllowanceChangeEvent(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
    }
}

contract SimpleWallet is Ownable, Allowance {
    event DepositEvent(address indexed _who, uint _amount);
    event WithdrawEvent(address indexed _who, uint _amount);
    
    /*
        @dev: Function to withdraw funds
    */ 
    function withdraw(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "There is not enough balance.");
        
        if (owner() == msg.sender) {
            reduceAllowance(msg.sender, _amount);
        }

        _to.transfer(_amount);
        emit WithdrawEvent(msg.sender, _amount);
    }

    /*
        @dev: Receive function to deposit funds
    */
    receive () external payable {
        emit DepositEvent(msg.sender, msg.value);
    }

    function renounceOwnership() override public onlyOwner {
        revert("It's not possible to renounce the ownership.");
    }
}
