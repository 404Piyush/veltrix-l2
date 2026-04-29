// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL2CrossDomainMessenger {
    function sendMessage(address _target, bytes calldata _message, uint32 _minGasLimit) external;
}

contract MessengerTest {
    IL2CrossDomainMessenger public immutable messenger;
    event MessageSent(address target, bytes message);

    constructor(address _messenger) {
        messenger = IL2CrossDomainMessenger(_messenger);
    }

    function testSendMessage(address _target, bytes calldata _message, uint32 _gas) external {
        messenger.sendMessage(_target, _message, _gas);
        emit MessageSent(_target, _message);
    }
}
