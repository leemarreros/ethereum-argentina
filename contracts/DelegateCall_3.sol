// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Logica {
    address public owner;

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }
}

contract Proxy {
    function newOwner(address _target) public {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );
        require(success);
    }

    function getValueAtSlotAdd(uint256 slot) public view returns (address) {
        address value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
}
