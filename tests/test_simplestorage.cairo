use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use cheatcodes::PreparedContract;

use test_contracts::simple_storage::ISimpleStorageSafeDispatcher;
use test_contracts::simple_storage::ISimpleStorageSafeDispatcherTrait;

fn deploy_simple_storage() -> ContractAddress {
    let class_hash = declare('SimpleStorage').unwrap();
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let contract_address = deploy(prepared).unwrap();

    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

#[test]
fn test_set() {
    let contract_address = deploy_simple_storage();

    let safe_dispatcher = ISimpleStorageSafeDispatcher { contract_address };

    let value_before: u128 = safe_dispatcher.get().unwrap();
    assert(value_before == 0, 'Invalid value');

    safe_dispatcher.set(42).unwrap();

    let value_after: u128 = safe_dispatcher.get().unwrap();
    assert(value_after == 42, 'Invalid value');
}

#[test]
fn test_get() {
    let contract_address = deploy_simple_storage();
    let safe_dispatcher = ISimpleStorageSafeDispatcher { contract_address };
    let value: u128 = safe_dispatcher.get().unwrap();
    assert(value == 0, 'Invalid value');
}
