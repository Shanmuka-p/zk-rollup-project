-- Up Migration
CREATE TABLE payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42) NOT NULL,
    amount_wei NUMERIC(78,0) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    batch_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE batches (
    id SERIAL PRIMARY KEY,
    batch_index INTEGER UNIQUE,
    old_state_root VARCHAR(66),
    new_state_root VARCHAR(66) NOT NULL,
    batch_hash VARCHAR(66) NOT NULL,
    tx_count INTEGER NOT NULL,
    relayer_address VARCHAR(42) NOT NULL,
    committed_at TIMESTAMPTZ,
    tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE deposits (
    id SERIAL PRIMARY KEY,
    user_address VARCHAR(42) NOT NULL,
    amount_wei NUMERIC(78,0) NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    block_number INTEGER NOT NULL,
    indexed_at TIMESTAMPTZ DEFAULT NOW()
);

---

-- Down Migration
DROP TABLE deposits;
DROP TABLE batches;
DROP TABLE payment_intents;