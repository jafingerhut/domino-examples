#define MAX_ALLOWABLE_RTT 30

typedef bit<16> PacketLength_t;
typedef bit<32> PacketCount_t;
typedef bit<48> ByteCount_t;
typedef bit<16> RTT_t;
typedef bit<48> RTT_Sum_t;

control ingress () {
    register<ByteCount_t>(1) input_traffic_bytes_reg;
    register<RTT_Sum_t>(1) sum_rtt_Tr_reg;
    register<PacketCount_t>(1) num_pkts_with_rtt_reg;
    
    action func (
        in PacketLength_t size_bytes,
        in RTT_t rtt)
    {
        ByteCount_t input_traffic_bytes;
        RTT_Sum_t sum_rtt_Tr;
        PacketCount_t num_pkts_with_rtt;

        @atomic {
            input_traffic_bytes_reg.read(input_traffic_bytes, (bit<32>) 0);
            sum_rtt_Tr_reg.read(sum_rtt_Tr, (bit<32>) 0);
            num_pkts_with_rtt_reg.read(num_pkts_with_rtt, (bit<32>) 0);

            input_traffic_bytes = input_traffic_bytes + (ByteCount_t) size_bytes;
            if (rtt < MAX_ALLOWABLE_RTT) {
                sum_rtt_Tr = sum_rtt_Tr + (RTT_Sum_t) rtt;
                num_pkts_with_rtt = num_pkts_with_rtt + 1;
            }

            input_traffic_bytes_reg.write((bit<32>) 0, input_traffic_bytes);
            sum_rtt_Tr_reg.write((bit<32>) 0, sum_rtt_Tr);
            num_pkts_with_rtt_reg.write((bit<32>) 0, num_pkts_with_rtt);
        }
    }

    apply {
        // code to call func() with appropriate arguments here
    }
}
