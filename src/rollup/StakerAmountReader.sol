// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/access/Ownable.sol";
import "../libraries/utils/EnumerableSet.sol";

contract StakeAmountReader is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet operators;

    uint256 public defaultMinStakeAmount = 0;
    mapping(address => uint256) public minStakeAmount;
    mapping(address => uint256) public stakeAmount;

    constructor() {}

    modifier onlyAuth() {
        require(operators.contains(msg.sender), "no auth");
        _;
    }

    event SetOperator(address _operator, bool isAdd);

    function setOperator(address _operator, bool isAdd) external onlyOwner {
        if (isAdd) {
            operators.add(_operator);
        } else {
            operators.remove(_operator);
        }

        emit SetOperator(_operator, isAdd);
    }

    function getOperatorsLength() external view returns (uint256) {
        return operators.length();
    }

    function getOperator(uint256 index) external view returns (address) {
        return operators.at(index);
    }

    function getOperatorsContains(address account)
        external
        view
        returns (bool)
    {
        return operators.contains(account);
    }

    function SetAmount(uint256 _amount) external {
        if (minStakeAmount[msg.sender] > _amount) {
            revert("minStakeAmount > amount set err");
        } 
        if (defaultMinStakeAmount > _amount) {
            revert("defaultMinStakeAmount > amount set err");
        }
       
        stakeAmount[msg.sender] = _amount;
        return;
    }

    function setMinStakeAmount(address _address, uint256 _amount)
        external
        onlyAuth
    {
        minStakeAmount[msg.sender] = _amount;
    }

    function setDefaultMinStakeAmount(uint256 _amount) external onlyAuth {
        defaultMinStakeAmount = _amount;
    }

    function getStakeAmount()external
        view
        returns (uint256)
    {
        return  stakeAmount[msg.sender];
    }
}
