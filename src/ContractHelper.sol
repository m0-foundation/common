// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.23;

/**
 * @title A helper contract to get the address of a contract deployed by aan account with a given nonce.
 * @dev   See the following sources for very similar implementations:
 *          - https://github.com/foundry-rs/forge-std/blob/914702ae99c92fcc41db5128ae57d24a11be4a39/src/Script.sol
 *          - https://github.com/foundry-rs/forge-std/blob/578968243529db44acffcb802196ccab9b54db88/src/StdUtils.sol#L90
 *          - https://github.com/SoulWallet/soul-wallet-contract/blob/develop/script/DeployHelper.sol#L133
 *          - https://github.com/nomoixyz/vulcan/blob/f67740f8a9c846a543aebf29433ad69c3f0ff337/src/_internal/Accounts.sol#L118
 *          - https://github.com/chainlight-io/publications/blob/887d6fe1a4f53573de6b89dbecba0c91b091dba2/ctf-writeups/paradigm2023/dropper/Solve.s.sol#L29
 *          - https://github.com/HerodotusDev/herodotus-evm/blob/a0e9c8be1a17838633d3dcdd54b72682f7654abd/src/lib/CREATE.sol#L5
 *          - https://github.com/Polymarket/ctf-exchange/blob/2745c3017400dbc1925711005fe76b018b999155/src/dev/util/Predictor.sol#L9
 *          - https://github.com/delegatexyz/delegate-market/blob/2418182fe81491114370287412926b57c1ddbd94/script/ComputeAddress.s.sol#L5
 *        Note that this implementation, as do many others, assumes an account does not have a nonce greater than 0xffffffff.
 *        If this is not the case, the address of the contract deployed by the account with the given nonce will be incorrect.
 */
library ContractHelper {
    /**
     * @notice Returns the expected address of a contract deployed by `account_` with transaction count `nonce_`.
     * @param  account_  The address of the account deploying a contract.
     * @param  nonce_    The nonce used in the deployment transaction.
     * @return contract_ The expected address of the deployed contract.
     */
    function getContractFrom(address account_, uint256 nonce_) internal pure returns (address contract_) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            nonce_ == 0x00
                                ? abi.encodePacked(bytes1(0xd6), bytes1(0x94), account_, bytes1(0x80))
                                : nonce_ <= 0x7f
                                ? abi.encodePacked(bytes1(0xd6), bytes1(0x94), account_, uint8(nonce_))
                                : nonce_ <= 0xff
                                ? abi.encodePacked(bytes1(0xd7), bytes1(0x94), account_, bytes1(0x81), uint8(nonce_))
                                : nonce_ <= 0xffff
                                ? abi.encodePacked(bytes1(0xd8), bytes1(0x94), account_, bytes1(0x82), uint16(nonce_))
                                : nonce_ <= 0xffffff
                                ? abi.encodePacked(bytes1(0xd9), bytes1(0x94), account_, bytes1(0x83), uint24(nonce_))
                                : abi.encodePacked(bytes1(0xda), bytes1(0x94), account_, bytes1(0x84), uint32(nonce_))
                        )
                    )
                )
            );
    }
}
