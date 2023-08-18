# Desmitificando los Contratos Actualizables y Actualizaciones Decentralizadas

**Separamos lógica de estado**

En la técnica de contratos actualizables logramos separar la lógica de negocio del almacenamiento. Es decir, vamos a utizliar un contrato para guardar la información y otro contrato para definiar la lógica y los algoritmos.

Por lo general, el contrato donde se guarda la información (state) se denomina Proxy y aquel donde se define la lógica es denominado Implementación.

> Un proxy también puede ser entendido como una entidad para representar a otra. En el contexto de contratos, el Proxy representa al contrato de Implementación.

![image-20230817234819741](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230817234819741.png)

**Proxy guarda referencia de Implementación**

Dentro del contrato Proxy se guarda una referencia al address del contrato de Implementación. Es decir, el Proxy sabe en todo momento cuál es el address del contrato donde se encuentra definida la lógica que tiene que usar.

**Nuevas Implementaciones**

Esta separación nos permite crear sucesivos contratos de Implementación con una nueva lógica. Cada vez que creamos un nuevo contrato de Implementación, le decimos al contrato Proxy que actualice la referencia del contrato lógica. De este modo logramos que el Proxy use nuevos métodos para modificar sus variables o estados. Allí habremos logrado una actualización.

![image-20230817235607686](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230817235607686.png)

**Se actualiza la referencia**

Cabe notar aquí que no se actualiza el código de un contrato inteligente. Eso en principio eso es inmutable. Cuando hablamos de la actualización hacemos referencia a que hay nuevo contrato de lógica al cual el Proxy se debe referir para usar la lógica.

Detras de técnica hay varios componentes a tener en cuenta. Vamos a estudiar lo que sucede detrás de una actualización de un contrato.

**`delegatecall`**

![image-20230818005056847](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818005056847.png)

Tenemos dos contratos: Proxy e Implementación. Vamos a hacer que el `delegatecall` sea definido dentro del contrato Proxy. Cada vez que el contrato Proxy hace uso del `delegatecall`, se logra ejecutar un método del contrato de Implementación dentro del contexto del Proxy.

Es como si el contrato Proxy se prestara el código del contrato Implementación para ejecutarlo con las variables y estados del contrato Proxy. El contrato de Implementación posee el control total sobre los estados del Proxy.

Veamos el ejemplo:

`DelegateCall_1.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
        (bool success, ) = _target.delegatecall(            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );

        // success == true si la llamada no hizo revert
        require(success);
    }

}
```

1. Inicialmente el `owner` en el contrato Proxy es `0x0000000000000000000000000000000000000000`
2. Ejecutamos el método `llamandoALogica` usando como `_target` el address de Logica
3. Verificamos `owner` en Proxy y este ha cambiado de valor a través del `delegatecall`

**Calldata**

`encodeWithSignature` codifica la firma del método (4 primeros bytes) con los argumentos de dicho método. En este ejemplo, `abi.encodeWithSignature("changeOwner(address)", msg.sender)` sería el equivalente a `0xa6f9dae10000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4`. Cuando se ejecuta un método en Solidity, dentro de dicho método podemos acceder al `calldata` que representaría lo mismo que `encodeWithSignature`.

**Storage layout**

![image-20230818063228896](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818063228896.png)

El layout se refiere a cómo las variables de un contrato son guardadas en la memoria permanente del contrato. Un contrato inteligente posee ranuras en donde se guardan las variables. Cada ranura (slot) puede guardar hasta 32 bytes (word) de información.

Un contrato puede acceder a las ranuras en donde se guardan las variables. Esto a pesar de que dichas variables fueron guardadas como `private`. No existe manera de esconder información en un contrato.

`StorageLayout.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
```

**Mismo storage layout: Proxy e Implementación**

Cuando se usa `delegatecall`, el storage layout de ambos contratos debe ser preservado. Es decir, el orden de las variables definidas en el contrato `Logica` debe ser la misma que el contrato `Proxy`.

![image-20230818034209318](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818034209318.png)

Esta preservación del storage layout tiene **dos consecuencias**:

1. Los nuevos contratos de `Logica` del futuro, **no podrán quitar variables** que ya no se usan: ello rompería el storage layout del contrato `Proxy`.
2. Un nuevo contrato de `Logica` solo podrá **añadir nuevas variables sin quitar las anteriores**. Ello ayudará a mantener el storage layout con el `Proxy`.

Cuando el storage layout de ambos contratos no coinciden, el problema surge cuando se trata de leer información del storage.

`DelegateCall_2.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Logica {
    address public owner;
    uint256 public limit;

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }

    function changeLimit(uint256 _limit) public {
        limit = _limit;
    }
}

contract Proxy {
    uint256 public limit; // slot 1 en Logica. ERROR
    address public owner; // slot 0 en Logica. ERROR

    function newOwner(address _target) public {
        (bool success, ) = _target.delegatecall(            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );
        require(success);
    }

    function newLimit(address _target) public {
        (bool success, ) = _target.delegatecall(       abi.encodeWithSignature("changeLimit(uint256)", 1000)
        );
        require(success);
    }

}
```

Aquí notamos que hay una incongruencia a la hora de leer la información en el Proxy luego de utilizar los `delegatecall` para actualizar sus variables.

Al leer `limit` obtendremos `520786028573371803640530888255888666801131675076` y al leer `owner` nos devuelve `0x00000000000000000000000000000000000003e8`, información errónea.

**`delegatecall` opera a nivel de EVM**

![image-20230818102724842](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818102724842.png)

Cuando ejecutamos cambios usando `delegatecall`, en realidad no se tiene que duplicar las mismas variables en el contrato Proxy e Implementación. `delegatecall` seguirá el layout storage del contrato de Implementación. Bajo esa guía actualizará los slots del contrato Proxy.

Ahora vamos a eliminar las variables del contrato Proxy. Ello no quiere decir que los slots del contrato Proxy dejen de actualizarse. Tampoco quiere decir que debemos dejar mantener el layout storage compatible entre Proxy e Implementación.

Al remover las variables no podemos crear getters para leer dichas variables. Sin embargo, nada nos impide acceder a los slots directamente:

`DelegateCall_3.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Logica {
    address public owner;

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }
}

contract Proxy {
    function newOwner(address _target) public {
        (bool success, ) = _target.delegatecall(            abi.encodeWithSignature("changeOwner(address)", msg.sender)
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
```

En este ejemplo, luego de ejecutar el método `newOwner` y usar el `delegatecall`, en el slot 0 del contrato Proxy, se ha actualizado la información. Ello porque se sigue el layout del contrato de Implementación.

Una manera de verificar aquello es usando el método `getValueAtSlotAdd` con el argumento 0. Nos devuelve otro valor diferente al address 0.

**fallback**

El método `fallback` te permite manejar llamadas inesperadas a un contrato. Es decir, atrapa aquellas llamadas a métodos que no coinciden con los que el contrato posee. Cuando se llama a un método, se hace una búsqueda con usando su identificador. Si este no se encuentra, cae en el `fallback`.

Veamos un ejemplo:

`Fallback.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFallback {
    function noExiste() external;
}

contract Llamante {
    // Ambos métodos producen los mismos efectos
    function llamandoFallback(address _target) external {
       IFallback(_target).noExiste();
    }

    function llamandoFallback2(address _target) external {
        (bool success, ) = _target.call(
            abi.encodeWithSignature("noExiste()")
        );
        require(success);
    }
}

contract Fallback {
    uint256 public counter;
    fallback() external {
    	counter++;
    }
}
```

**Hackeando con delegatecall y fallback**

![image-20230818030202391](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818030202391.png)

Delegate call permite usar el código de otro lugar dentro de un contrato. Aunque proporciona mucha flexibilidad, también abre la puerta a otras vulnerabilidades. En el año 2017 [un hacker fue capaz de extraer 150,000 ETH usando `delegatecall`](https://blog.openzeppelin.com/on-the-parity-wallet-multisig-hack-405a8c12e8f7). 

Vamos a ver una versión simplificada de dicho ataque:

`HackeandoDCF.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Libreria {
    address[256] public owners;
    address libreria;

    function initWallet(address[] memory _owners) public {
        for (uint256 i; i < _owners.length; i++) {
            owners[i] = _owners[i];
        }
    }
    // otros métodos
}

contract Wallet {
    address[256] public owners;
    address libreria;

    constructor(
        address[] memory _owners, 
        address _libreria
    ) {
        libreria = _libreria;
        (bool success, ) = _libreria.delegatecall(
            abi.encodeWithSignature(
                "initWallet(address[])", _owners
            )
        );
        require(success);
    }

    fallback() external {
        // ...
        libreria.delegatecall(msg.data);
    }

    function execute() public {}
}

contract CalculateCalldata {

    function calculateEncoding(
        address[] memory _owners
    ) public pure returns(bytes memory) {
        return abi.encodeWithSignature(
            "initWallet(address[])", _owners
        );
    }

}
```

1. En el constructor de `Wallet` utilizaron código de la `Libreria` usando `delegatecall`. El método `initWallet` guarda los owners iniciales.
2. El `fallback` de `Wallet` delega todas las llamadas a métodos de la `Libreria`. Sin embargo, no ofrece protección ni controles de acceso para dichos métodos.
3. El atacante volvió a llamar `initWallet` para convertirse en el nuevo dueño del contrato y extraer los fondos. Para calcular el `calldata` se puede usar el método `calculateEncoding` y luego ejecutar `TRANSACT` en el contrato `Wallet`.

A modo de conclusión podemos decir que hacer `delegatecall` dentro del método `fallback` es muy peligroso dado abre la puerta para poder enviar cualquier tipo de `calldata`. Además, no se protegió un método de inicialización. Se hubiera evitado este problema si dicho método de inicialización se hubiera llamado una sola vez.

**Construyendo un contrato actualizable**

![image-20230818104349396](/Users/steveleec/Documents/Blockchain Bites/ethereum-argentina/README.assets/image-20230818104349396.png)

Ahora vamos a ver cómo construir un contracto actualizable desde cero:

Algunas consideraciones:

* Dado que no podemos guardar el address de la implementación en una variable que ocupe uno de los slots iniciales (por el layout storage), vamos a usar un storage sin estructura.
* Este `unstructured storage` o storage sin estructura es parte del EIP1967 que justamente busca evitar colisiones entre los layout storage de Proxy e Implementación
* De acuerdo al EIP1967, vamos a calcular un slot random del contrato para poder guardar el address de la implementación.
* Usando assembly, seremos capaces de manipular los slots directamente. Es decir, no usaremos un típico setter de Solidity sino `ssload` y `sstore` que son funciones de assembly para interactuar con slots

`UpgradeableSC.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Proxy {
    // No es parte del storage layout
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    fallback() external {
        address imp = getImplementation();
        (bool success,) = imp.delegatecall(msg.data);
        require(success);
    }

    // assembly para leer el slot
    function getValueAtSlot(uint256 slot) public view returns (uint256) {
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
    
    //////////////////////////////////////////////////////////////////////
    // assembly para guardar el address de la implementation sin colisión
    function setImplementation(address impAddress) public {
        assembly {
            sstore(IMPLEMENTATION_SLOT, impAddress)
        }
    }

    function getImplementation() public view returns (address impAddress) {
        assembly {
            impAddress := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Logica1 {
    uint256 amount;
    
    function operate() public {
        amount += 10;
    }

    function calculateEncoding() public pure returns(bytes memory) {
        return abi.encodeWithSignature("operate()");
    }
}

contract Logica2 {
    uint256 amount;
    uint256 amount2;

    function operate() public {
        amount *= 2;
    }

    function setAmount2() public {
        amount2 = 2023;
    }

    function calculateEncoding() public pure returns(bytes memory) {
        return abi.encodeWithSignature("setAmount2()");
    }
}
```

