// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title HashedTimelock
 * @dev Professional HTLC implementation for trustless token swaps.
 */
contract HashedTimelock {
    struct Swap {
        address sender;
        address receiver;
        address token;
        uint256 amount;
        bytes32 hashLock;
        uint256 expiration;
        bool withdrawn;
        bool refunded;
        bytes32 secret;
    }

    mapping(bytes32 => Swap) public swaps;

    event Funded(bytes32 indexed id, address indexed sender, address indexed receiver, uint256 amount, bytes32 hashLock, uint256 expiration);
    event Withdrawn(bytes32 indexed id, bytes32 secret);
    event Refunded(bytes32 indexed id);

    /**
     * @notice Locks tokens into the contract for a swap.
     * @param _id Unique swap ID.
     * @param _receiver The address allowed to claim the tokens.
     * @param _token The ERC20 token address.
     * @param _amount Amount of tokens to lock.
     * @param _hashLock The SHA-256 hash of the secret.
     * @param _timelock Duration (in seconds) before the sender can refund.
     */
    function fund(
        bytes32 _id,
        address _receiver,
        address _token,
        uint256 _amount,
        bytes32 _hashLock,
        uint256 _timelock
    ) external {
        require(swaps[_id].sender == address(0), "Swap ID already exists");
        require(_amount > 0, "Amount must be > 0");
        require(_timelock > block.timestamp, "Expiration must be in future");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        swaps[_id] = Swap({
            sender: msg.sender,
            receiver: _receiver,
            token: _token,
            amount: _amount,
            hashLock: _hashLock,
            expiration: _timelock,
            withdrawn: false,
            refunded: false,
            secret: 0x0
        });

        emit Funded(_id, msg.sender, _receiver, _amount, _hashLock, _timelock);
    }

    /**
     * @notice Receiver claims tokens by providing the secret preimage.
     */
    function withdraw(bytes32 _id, bytes32 _secret) external {
        Swap storage swap = swaps[_id];

        require(sha256(abi.encodePacked(_secret)) == swap.hashLock, "Invalid secret");
        require(!swap.withdrawn, "Already withdrawn");
        require(!swap.refunded, "Already refunded");

        swap.secret = _secret;
        swap.withdrawn = true;

        IERC20(swap.token).transfer(swap.receiver, swap.amount);

        emit Withdrawn(_id, _secret);
    }

    /**
     * @notice Sender reclaims tokens if the timelock has expired.
     */
    function refund(bytes32 _id) external {
        Swap storage swap = swaps[_id];

        require(swap.sender == msg.sender, "Not the sender");
        require(block.timestamp >= swap.expiration, "Not expired yet");
        require(!swap.withdrawn, "Already withdrawn");
        require(!swap.refunded, "Already refunded");

        swap.refunded = true;

        IERC20(swap.token).transfer(swap.sender, swap.amount);

        emit Refunded(_id);
    }
}
