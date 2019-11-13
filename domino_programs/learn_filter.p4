#define NUM_ENTRIES 256

#define LG2_NUM_ENTRIES 8
typedef bit<LG2_NUM_ENTRIES> FilterIdx_t;

control ingress () {
    register< bit<1> >(NUM_ENTRIES) filter1_reg;
    register< bit<1> >(NUM_ENTRIES) filter2_reg;
    register< bit<1> >(NUM_ENTRIES) filter3_reg;

    action func (
        in bit<16> sport,
        in bit<16> dport,
        out bit<1> member)
    {
        FilterIdx_t filter1_idx, filter2_idx, filter3_idx;
        bit<1> filter1_bit, filter2_bit, filter3_bit;
        @atomic {
            filter1_idx = hash2a(sport, dport) % NUM_ENTRIES;
            filter2_idx = hash2b(sport, dport) % NUM_ENTRIES;
            filter3_idx = hash2c(sport, dport) % NUM_ENTRIES;

            filter1_reg.read(filter1_bit, (bit<32>) filter1_idx);
            filter2_reg.read(filter2_bit, (bit<32>) filter2_idx);
            filter3_reg.read(filter3_bit, (bit<32>) filter3_idx);

            member = filter1_bit & filter2_bit & filter3_bit;

            filter1_reg.write((bit<32>) filter1_idx, 1);
            filter2_reg.write((bit<32>) filter2_idx, 1);
            filter3_reg.write((bit<32>) filter3_idx, 1);
        }
    }

    apply {
        // Some code here to parse/calculate sport and dport.
        func(sport, dport, member);
        // Some code here to use calculated value of member written as
        // out parameter of action func.
    }
}
