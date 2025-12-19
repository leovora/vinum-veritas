// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint public value;

    event ValueChanged(address indexed sender, uint newValue);

    function setValue(uint _value) public {
        value = _value;
        emit ValueChanged(msg.sender, _value);
    }

    function getValue() public view returns (uint) {
        return value;
    }
}
