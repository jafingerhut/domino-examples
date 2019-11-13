typedef bit<48> Timestamp_t;

#define NUM_FLOWLETS 8000
#define THRESHOLD    5
#define NUM_HOPS     10

#define LG2_NUM_FLOWLETS 13
typedef bit<LG2_NUM_FLOWLETS> FlowletId_t;
#define LG2_NUM_HOPS 4
typedef bit<LG2_NUM_HOPS> Hop_t;

control ingress () {
    register<Timestamp_t>(NUM_FLOWLETS) last_time_reg;
    register<Hop_t>(NUM_FLOWLETS) saved_hop_reg;

    action flowlet (
        in bit<16> sport,
        in bit<16> dport,
        in Timestamp_t arrival,
        out Hop_t next_hop)
    {
        FlowletId_t id;
        Hop_t new_hop, saved_hop;
        Timestamp_t last_time;
        @atomic {
            new_hop = hash3(sport, dport, arrival) % NUM_HOPS;
            id = hash2(sport, dport) % NUM_FLOWLETS;

            last_time_reg.read(last_time, (bit<32>) id);
            saved_hop_reg.read(saved_hop, (bit<32>) id);
            
            if (arrival - last_time > THRESHOLD) {
                saved_hop = new_hop;
            }
            last_time = arrival;
            next_hop = saved_hop;
            
            last_time_reg.write((bit<32>) id, last_time);
            saved_hop_reg.write((bit<32>) id, saved_hop);
        }
    }

    apply {
        // Some code here to parse/calculate sport, dport, and
        // arrival.
        flowlet(sport, dport, arrival, next_hop);
        // Some code here to use calculated value of next_hop written
        // as out parameter of action flowlet.
    }
}
