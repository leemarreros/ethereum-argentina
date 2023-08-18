// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract StorageLayout {
    address private owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 private limit = 100;

    function getValueAtSlotUint(uint256 slot) public view returns (uint256) {
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    function getValueAtSlotAdd(uint256 slot) public view returns (address) {
        address value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
}
