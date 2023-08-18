// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Logica {
    address public owner;

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }
}

contract Proxy {
    // 1. owner == 0x0000000000000000000000000000000000000000
    // 3. owner == 0xAddressDiferenteAZero0000000000000000000
    address public owner;

    // 2. llamandoALogica(addressLogica)
    function llamandoALogica(address _target) public {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );

        // success == true si la llamada no hizo revert
        require(success);
    }
}
