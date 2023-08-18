// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IFallback {
    function noExiste() external;
}

contract Llamante {
    // Ambos métodos producen los mismos efectos
    function llamandoFallback(address _target) external {
        IFallback(_target).noExiste();
    }

    function llamandoFallback2(address _target) external {
        (bool success, ) = _target.call(abi.encodeWithSignature("noExiste()"));
        require(success);
    }
}

contract Fallback {
    uint256 public counter;

    fallback() external {
        counter++;
    }
}
