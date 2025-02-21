mod types;
mod test;

use dep::aztec::macros::aztec;

#[aztec]
pub contract HAD {
    use crate::types::nft_note::NFTNote;
    use dep::authwit::auth::{
        assert_current_call_valid_authwit,
        assert_current_call_valid_authwit_public,
        compute_authwit_nullifier,
    };
    use dep::aztec::{
        note::constants::MAX_NOTES_PER_PAGE,
        oracle::random::random,
        prelude::*,
    };
    use dep::compressed_string::FieldCompressedString;

    // Storage yapısı
    #[storage]
    struct Storage<Context> {
        symbol: PublicImmutable<FieldCompressedString, Context>,
        name: PublicImmutable<FieldCompressedString, Context>,
        admin: PublicMutable<AztecAddress, Context>,
        minters: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
        private_nfts: Map<AztecAddress, PrivateSet<NFTNote, Context>, Context>,
        nft_exists: Map<Field, PublicMutable<bool, Context>, Context>,
        public_owners: Map<Field, PublicMutable<AztecAddress, Context>, Context>,
        total_supply: PublicMutable<Field, Context>,
        max_supply: PublicImmutable<Field, Context>,
        base_uri: PublicMutable<FieldCompressedString, Context>,
    }

    // Constructor
    #[public]
    #[initializer] 
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin");
        storage.admin.write(admin);
        storage.minters.at(admin).write(true);
        storage.name.initialize(FieldCompressedString::from_string("HAD"));
        storage.symbol.initialize(FieldCompressedString::from_string("HAD"));
        storage.max_supply.initialize(Field::from(7777u32));
        storage.total_supply.write(Field::from(0u32));
        storage.base_uri.write(FieldCompressedString::from_string("ipfs://bafybeigemu7wtpogtgsz2kzml6n5bgcrl6pbddfhgbatoatpgm5p7p6il4/"));
    }

    // Mint fonksiyonu
    #[public]
    fn mint(to: AztecAddress, token_id: Field) {
        assert(storage.minters.at(context.msg_sender()).read(), "caller is not a minter");
        assert(storage.nft_exists.at(token_id).read() == false, "token already exists");
        assert(token_id > 0 && token_id <= storage.max_supply.read(), "invalid token id");
        
        let current_supply = storage.total_supply.read();
        assert(current_supply < storage.max_supply.read(), "max supply reached");

        storage.nft_exists.at(token_id).write(true);
        storage.public_owners.at(token_id).write(to);
        storage.total_supply.write(current_supply + Field::from(1u32));
    }

    // Transfer fonksiyonu
    #[public]
    fn transfer_in_public(from: AztecAddress, to: AztecAddress, token_id: Field, nonce: Field) {
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit_public(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        let public_owners_storage = storage.public_owners.at(token_id);
        assert(public_owners_storage.read().eq(from), "invalid owner");

        public_owners_storage.write(to);
    }
} 