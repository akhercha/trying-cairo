use starknet::ContractAddress;

#[starknet::interface]
trait INameRegistry<TContractState> {
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_total_names(self: @TContractState) -> u128;
    fn get_name(self: @TContractState, address: ContractAddress) -> felt252;
    fn set_owner(ref self: TContractState, address: ContractAddress);
    fn store_name(ref self: TContractState, name: felt252);
}

#[starknet::contract]
mod NameRegistry {
    use starknet::{ContractAddress, get_caller_address};

    use super::INameRegistry;

    #[storage]
    struct Storage {
        names: LegacyMap::<ContractAddress, felt252>,
        total_names: u128,
        owner: Person
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName: StoredName
    }

    #[derive(Drop, starknet::Event)]
    struct StoredName {
        #[key]
        address: ContractAddress,
        name: felt252
    }

    #[derive(Copy, Drop, Serde, storage_access::StorageAccess)]
    struct Person {
        name: felt252,
        address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.names.write(owner.address, owner.name);
        self.total_names.write(1);
        self.owner.write(owner);
    }

    #[external(v0)]
    impl NameRegistryImpl of INameRegistry<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read().address
        }
        fn get_total_names(self: @ContractState) -> u128 {
            self.total_names.read()
        }
        fn get_name(self: @ContractState, address: ContractAddress) -> felt252 {
            self.names.read(address)
        }
        fn set_owner(ref self: ContractState, address: ContractAddress) {
            self._only_owner();
        }
        fn store_name(ref self: ContractState, name: felt252) {
            let caller: ContractAddress = get_caller_address();
            self._store_name(caller, name);
        }
    }

    #[generate_trait]
    impl EventsEmitterImpl of IEventsEmitter {
        fn emit_stored_name(ref self: ContractState, address: ContractAddress, name: felt252) {
            self.emit(Event::StoredName(StoredName { address, name }))
        }
    }

    #[generate_trait]
    impl InternalFunctionsImpl of IInternalFunctions {
        fn _increment_total_names(ref self: ContractState) {
            let mut total_names = self.total_names.read();
            self.total_names.write(total_names + 1);
        }

        fn _store_name(ref self: ContractState, address: ContractAddress, name: felt252) {
            self._increment_total_names();
            self.names.write(address, name);
            self.emit_stored_name(address, name);
        }

        fn _only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read().address, 'Caller is not the owner');
        }

        fn _get_contract_name() -> felt252 {
            'Name Registry'
        }
    }
}
