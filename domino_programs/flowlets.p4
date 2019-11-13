// It seems to me that, given an architecture that has a register
// extern like the v1model API for registers used below, there is a
// straightforward and general way to translate the Domino examples
// from the "Packet Transactions" paper into P4_16.

// In some ways, the P4_16 translation is clearer than the Domino
// code, because the resulting P4_16 action can have directions like
// in/out on its parameters, making their use in the function even
// clearer to a reader than the Domino language enables.

// The steps I followed are these:

// Make the Domino 'global variables' into P4_16 register arrays.  If
// the Domino global variable is not an array, but a single value,
// make it into a P4_16 register array with 1 element, and always
// read/write the only index of 0 in later code.

// Make the Domino function into an action.

// Read and understand the use of variables in the Domino code to see
// which can be local variables of the action, which should be in
// parameters, and which should be out parameters.

// Put the entire body of the action inside of a block annotated with
// @atomic.

// Calculate the indexes at which to read any register arrays.

// Perform the read operations on all register arrays, into local
// variables.  This is called creating a "read flank" in Section 4.1
// of the Packet Transactions paper.

// Perform the body of the Domino function code.

// Perform the write operations on all register arrays, from the local
// variables read above, and back into the same indexes that were
// read.  This is an explicit restriction in the Domino language, that
// the indexes written must be the same as the ones read, and matches
// what is cheapest to implement in a high speed P4 target.  This is
// called creating a "write flank" in Section 4.1 of the Packet
// Transactions paper.

// As you can see in the skeleton control apply body, calling the
// action requires first calculating the desired values of all 'in'
// parameters, either directly from packet headers, or values derived
// from executing arbitrary earlier P4_16 code.

// Similarly, after calling the action, P4_16 code executed later now
// has the value of any 'out' parameters available for its use.

// I do not see how the proposed addition of abstract methods to the
// P4_16 language enables a translation from Domino into P4_16 that is
// any better than this, but I could be lacking imagination on that
// point.

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
