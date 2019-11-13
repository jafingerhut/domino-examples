// This example is an exercise I set for myself in creating a P4_16
// extern that limits itself to what the P4_16 language spec allows
// (i.e. externs methods may not access the contents of any P4 program
// variables, other than those explicitly given as parameters to the
// methods, and then only via the copy-in/copy-out semantics), and
// uses the proposed "pure function of its parameters" restriction on
// abstract methods, that together can implement the behavior of one
// of the Domino example programs.

// I can't say I am terribly proud of this code.  I consider it more
// like solving a puzzle with weird constraints, just to see if there
// is a solution.

// The intent is that this program would behave identically to the one
// in flowlet.p4 in this same directory.

// First, let me define the behavior of the new extern
// 'like_a_register' used here.

// Basically it is similar to a P4_16 v1model register extern, in that
// it maintains internal state that is an array of identical data
// values.  It has many differences in how it is accessed.  Instead of
// read() and write() methods, it has the methods described below.

// Method 'copy_to_update_input' copies data from the user's P4
// program, given as parameters to this method, into the internal
// state of the extern.  That data is associated with the current
// packet being processed by the caller.  The storage inside the
// extern remembers that this data was associated with the packet that
// called this method, and is allowed to forget the data when the
// packet is done executing its current top-level control.

// The 'copy_to_update_input' method is basically a work-around for the
// restriction that neither the extern nor its
// pure-function-restricted abstract method can read values of
// variables from its lexical environment.  Instead, we call the
// 'copy_to_update_input' explicitly to get the data from the P4 program
// into the extern's internal state.

// Instead of 'read' and 'write' methods, the extern behavior is
// defined to call the user-provided abstract method 'update'.  The
// typical sequence of calls made by a user of this extern will look
// like this:

//    // initialize my_input_values here
//    my_reg.copy_to_update_input(my_input_values);
//    my_reg.set_update_index(my_index);

//    // perform_update() causes the abstract method 'update' to be
//    // called with 'input' parameter equal to 'my_input_values',
//    // 'state' parameter equal to the value read from index
//    // 'my_index' of the register array.
//    my_reg.perform_udpate();

//    // perform_update() also causes the inout 'state' parameter's
//    // final value (after the 'update' method is finished executing)
//    // to be written back into the register array at the same index
//    // 'my_index', and the 'output' parameter value to be stored in
//    // internal state of the extern, read to be copied on the next
//    // call to method 'copy_from_update_output'.

//    my_reg.copy_from_update_output(my_output_values);

// After the 'update' method returns, the extern will take the final
// value of the 'state' parameter, and write it back to the same index
// of the register array that it was read from.

// Also after the 'update' method returns, it will keep a copy of the
// value of the 'out' parameter 'outputs', in a place dedicated to the
// packet that called the 'update' method.  If the P4 programmer wants
// to use that value, they must call the 'copy_from_update_output'
// method after the 'update' method completes its execution.

// I is the type for parameter 'inputs' of the 'update' method.

// X is the type for the index, restricted to be bit<W> for some W

// D is the type of data stored in every element of the register
// array, and also of the 'state' parameter of the 'update' method.

// O is the type for parameter 'outputs' of the 'update' method.

// Any or all of I, D, and O may be a struct with multiple fields.
// Targets may of course impose restrictions on what subset of types
// they support for all of these types, e.g. "D is restricted to 4
// fields, each with type bit<W> where W <= 64".

extern like_a_register<I, X, D, O> {
    like_a_register(bit<32> size);
    void copy_to_update_input(in I input);
    void set_update_index(in X index);
    abstract void update(in I input, inout D state, out O output);
    void perform_update();
    void copy_from_update_output(out O output);
}


typedef bit<48> Timestamp_t;

#define NUM_FLOWLETS 8000
#define THRESHOLD    5
#define NUM_HOPS     10

#define LG2_NUM_FLOWLETS 13
typedef bit<LG2_NUM_FLOWLETS> FlowletId_t;
#define LG2_NUM_HOPS 4
typedef bit<LG2_NUM_HOPS> Hop_t;

struct FlowletState_t {
    Timestamp_t last_time;
    Hop_t saved_hop;
}

struct FlowletUpdateInput_t {
    bit<16> sport;
    bit<16> dport;
    Hop_t new_hop;
    Timestamp_t arrival;
}

struct FlowletUpdateOutput_t {
    Hop_t next_hop;
}

control ingress () {
    like_a_register<FlowletUpdateInput_t, FlowletId_t, FlowletState_t, FlowletUpdateOutput_t>(NUM_FLOWLETS) flowlet_reg = {
        void udpate (
            in FlowletUpdateInput_t input,
            inout FlowletState_t state,
            out FlowletUpdateOutput_t output)
        {
            if (input.arrival - state.last_time > THRESHOLD) {
                state.saved_hop = input.new_hop;
            }
            state.last_time = input.arrival;
            output.next_hop = state.saved_hop;
        }
    }

    apply {
        bit<16> sport;
        bit<16> dport;
        Timestamp_t arrival;

        FlowletId_t id;
        FlowletUpdateInput_t my_input;
        FlowletUpdateOutput_t my_output;

        // Some code here to parse/calculate sport, dport, and
        // arrival.

        id = hash2(sport, dport) % NUM_FLOWLETS;
        flowlet_reg.set_update_index(id);

        my_input.arrival = arrival;
        my_input.sport = sport;
        my_input.dport = dport;
        my_input.new_hop = hash3(sport, dport, arrival) % NUM_HOPS;
        flowlet_reg.copy_to_update_input(my_input);
        // After the call to copy_to_update_input(), the next time
        // that flowlet_reg.update() is called by this packet, its
        // 'input' parameter will contain the value of my_input, at
        // the last time the copy_to_update_input() method was called
        // by this packet.
    
        flowlet_reg.perform_update();

        flowlet_reg.copy_from_update_output(my_output);
        // Some code here may use calculated value of
        // my_output.next_hop, whose value came (indirectly) from out
        // parameter of flowlet_reg's update method.
    }
}
