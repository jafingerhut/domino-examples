#define low_th 100
#define hi_th  1000
#define NUM_ENTRIES 4096

#define LG2_NUM_ENTRIES 12
typedef bit<LG2_NUM_ENTRIES> EntryIdx_t;

control ingress () {
    register<SketchCount_t>(NUM_ENTRIES) sketch1_reg;
    register<SketchCount_t>(NUM_ENTRIES) sketch2_reg;
    register<SketchCount_t>(NUM_ENTRIES) sketch3_reg;

    action func (
        in bit<16> sport,
        in bit<16> dport,
        out bit<1> is_not_heavy_hitter)
    {
        EntryIdx_t sketch1_idx;
        EntryIdx_t sketch2_idx;
        EntryIdx_t sketch3_idx;
        @atomic {
            sketch1_idx = hash2a(sport, dport) % NUM_ENTRIES;
            sketch2_idx = hash2b(sport, dport) % NUM_ENTRIES;
            sketch3_idx = hash2c(sport, dport) % NUM_ENTRIES;

            sketch1_reg.read(sketch_cnt_1, (bit<32>) sketch1_idx);
            sketch2_reg.read(sketch_cnt_2, (bit<32>) sketch2_idx);
            sketch3_reg.read(sketch_cnt_3, (bit<32>) sketch3_idx);

            if (sketch_cnt_1 > low_th && sketch_cnt_1 < hi_th &&
	        sketch_cnt_2 > low_th && sketch_cnt_2 < hi_th &&
	        sketch_cnt_3 > low_th && sketch_cnt_3 < hi_th)
            {
		is_not_heavy_hitter = 0;
            } else {
		is_not_heavy_hitter = 1;
            }
	    sketch_cnt_1 = sketch_cnt_1 + 1;
	    sketch_cnt_2 = sketch_cnt_2 + 1;
	    sketch_cnt_3 = sketch_cnt_3 + 1;

            sketch1_reg.write((bit<32>) sketch1_idx, sketch_cnt_1);
            sketch2_reg.write((bit<32>) sketch2_idx, sketch_cnt_2);
            sketch3_reg.write((bit<32>) sketch3_idx, sketch_cnt_3);
        }
    }

    apply {
        // Some code here to parse/calculate sport and dport.
        func(sport, dport, is_not_heavy_hitter);
        // Some code here to use calculated value of
        // is_not_heavy_hitter written as out parameter of action
        // func.
    }
}
