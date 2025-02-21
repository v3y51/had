#[aztec]
pub contract HADBridge {
    use dep::aztec::prelude::*;
    
    #[storage]
    struct Storage<Context> {
        had_contract: PublicImmutable<AztecAddress, Context>,
        layerzero_endpoint: PublicImmutable<AztecAddress, Context>,
        trusted_remotes: Map<Field, PublicMutable<bool, Context>, Context>,
    }

    #[public]
    #[initializer]
    fn constructor(
        had_contract: AztecAddress,
        layerzero_endpoint: AztecAddress
    ) {
        storage.had_contract.initialize(had_contract);
        storage.layerzero_endpoint.initialize(layerzero_endpoint);
    }

    #[public]
    fn send_cross_chain(
        dest_chain_id: Field,
        to: AztecAddress,
        token_id: Field
    ) {
        // LayerZero mesaj gönderme mantığı
        assert(storage.trusted_remotes.at(dest_chain_id).read(), "untrusted remote");
        
        // NFT'yi yakma
        HAD::at(storage.had_contract.read())
            .burn(context.msg_sender(), token_id)
            .call(&mut context);

        // LayerZero üzerinden cross-chain mesaj gönderme
        let payload = encode_cross_chain_msg(to, token_id);
        send_layerzero_msg(dest_chain_id, payload);
    }

    #[public]
    fn receive_cross_chain(
        src_chain_id: Field,
        to: AztecAddress,
        token_id: Field
    ) {
        assert(storage.trusted_remotes.at(src_chain_id).read(), "untrusted remote");
        assert(context.msg_sender().eq(storage.layerzero_endpoint.read()), "invalid sender");

        // Hedef zincirde NFT mint etme
        HAD::at(storage.had_contract.read())
            .mint(to, token_id)
            .call(&mut context);
    }
} 