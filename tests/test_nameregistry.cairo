use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use traits::Into;

use serde::Serde;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;

use forge_print::PrintTrait;
use cheatcodes::PreparedContract;

use test_contracts::name_registry::INameRegistrySafeDispatcher;
use test_contracts::name_registry::INameRegistrySafeDispatcherTrait;
use test_contracts::name_registry::NameRegistry::Person;

const OWNER_ADDRESS: felt252 = 333456747;
fn _get_owner() -> Person {
    Person { name: 'admin', address: OWNER_ADDRESS.try_into().unwrap() }
}

fn _deploy_contract() -> ContractAddress {
    let class_hash = declare('NameRegistry').unwrap();

    let mut constructor_calldata = ArrayTrait::new();
    _get_owner().serialize(ref constructor_calldata);

    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    let contract_address = deploy(prepared).unwrap();
    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

#[test]
fn test_get_owner() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let owner: Person = _get_owner();

    let expected = _get_owner().address;
    let out = safe_dispatcher.get_owner().unwrap();

    assert(out == expected, 'owners address is not correct')
}

#[test]
fn test_get_total_names() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let expected = 1; // only owner is set
    let out = safe_dispatcher.get_total_names().unwrap();

    assert(out == expected, 'total names is not correct')
}

#[test]
fn test_set_owner() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let random_address: felt252 = 27547869876870;
    let random_address: ContractAddress = random_address.try_into().unwrap();

    safe_dispatcher.set_owner(random_address);
}

#[test]
fn test_store_name() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };
    safe_dispatcher.store_name('something random');
}

#[test]
fn test_get_name() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let owner: Person = _get_owner();
    let expected = 'something';

    safe_dispatcher.store_name(expected);

    match safe_dispatcher.get_name(owner.address) {
        Result::Ok(out) => assert(out == expected, 'Invalid name from get_name()'),
        Result::Err(_) => panic_with_felt252('Failed to get name'),
    }
}

#[test]
fn test_get_name_owner() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let owner: Person = _get_owner();

    let expected = _get_owner().name;
    let out = safe_dispatcher.get_name(owner.address).unwrap();

    assert(out == expected, 'owners name is not correct')
}

#[test]
fn test_get_name_for_inexistant_address() {
    let contract_address = _deploy_contract();
    let safe_dispatcher = INameRegistrySafeDispatcher { contract_address };

    let random_address: felt252 = 27547869876870;
    let random_address: ContractAddress = random_address.try_into().unwrap();

    let expected = 0;
    let out = safe_dispatcher.get_name(random_address).unwrap();

    assert(out == expected, 'owners name is not correct')
}
