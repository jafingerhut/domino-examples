#define NUM_RECORDS 10000

typedef bit<14> RData_t;
typedef bit<32> PacketCount_t;

control ingress () {
    register< bit<1> >(NUM_RECORDS) seen_reg;
    register< bit<8> >(NUM_RECORDS) last_ttl_reg;
    register< PacketCount_t >(NUM_RECORDS) ttl_change_reg;

    action func (
        in RData_t rdata,
        in bit<8> ttl)
    {
        RData_t id;
        bit<1> seen;
        bit<8> last_ttl;
        PacketCount_t ttl_change;
        @atomic {
            seen_reg.read(seen, (bit<32>) id);
            last_ttl_reg.read(last_ttl, (bit<32>) id);
            ttl_change_reg.read(ttl_change, (bit<32>) id);

            id = rdata;
            if (seen == 0) {
                seen = 1;
                last_ttl = ttl;
                ttl_change = 0;
            } else {
                if (last_ttl != ttl) {
                    last_ttl = ttl;
                    ttl_change = ttl_change + 1;
                }
            }

            seen_reg.write((bit<32>) id, seen);
            last_ttl_reg.write((bit<32>) id, last_ttl);
            ttl_change_reg.write((bit<32>) id, ttl_change);
        }
    }

    apply {
    }
}
