    instruction = 32'h00000013; // Default to NOP
    curr_PC     = 32'h00000000;
    mispredict  = 1'b0;

    // --- Optional: Incorporate some of the user's initial sequence ---
    #5; // Wait 5 time units
    curr_PC     = 32'h00000000;
    instruction = 32'h0000000F; // FENCE instruction at PC = 0x00

    #10; // Wait 10 time units
    curr_PC     = 32'h00000004; // PC is now 0x00 + 4 = 0x04
    instruction = 32'h0000006F; // JAL x0, 0 (NOP) at PC = 0x04

    // Example of the JAL with an immediate as per your snippet context
    // (assuming 'immediate = -10' was meant for a specific JAL)
    #10;
    curr_PC     = 32'h00000020; // Jump to an arbitrary PC for this instruction
    instruction = 32'hFEDFF06F; // JAL x0, -10 (Target: 0x20 - 10 = 0x16)
                                // Next PC after this jump will be 0x16.

    // --- Main Loop Sequence for Loop Stream Detector Test ---
    // We'll start the loop at a fresh address, e.g., 0x100, to keep it distinct.
    // This loop consists of 3 NOPs and 1 backward branch (4 instructions total).
    // Loop addresses: 0x100, 0x104, 0x108, 0x10C (branch back to 0x100).
    // The branch BEQ x0, x0, -12 (32'hFC000AE3) at 0x10C jumps to 0x10C - 12 = 0x100.

    #10; // Settle from previous instruction, PC is notionally at 0x16 after the JAL

    // Iteration 1 of the test loop
    $display("[%0t] Starting loop iteration 1", $time);
    #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP at 0x100
    #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP at 0x104
    #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP at 0x108
    #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; // BEQ x0,x0,-12 (branch to 0x100)

    // Iteration 2
    $display("[%0t] Starting loop iteration 2", $time);
    #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; // BEQ (branch to 0x100)

    // Iteration 3 (Loop detector should be learning or have learned the loop)
    $display("[%0t] Starting loop iteration 3", $time);
    #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; // BEQ (branch to 0x100)

    // Iteration 4 (Loop detector might be streaming instructions now)
    $display("[%0t] Starting loop iteration 4 - expecting detector to be active", $time);
    #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
    #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; // BEQ (branch to 0x100)
                                                        // Assume DUT predicts this branch as TAKEN.

    // --- Simulate a Misprediction ---
    // The branch at 0x10C was just "fetched" (or provided by the loop detector).
    // Let's say after a few cycles (simulating pipeline depth for branch resolution),
    // it's determined that the prediction "taken" was wrong.
    // The branch should have actually fallen through to 0x10C + 4 = 0x110.
    $display("[%0t] Branch at 0x10C fetched/issued. Simulating misprediction scenario.", $time);

    // Wait for a duration that represents branch resolution latency in your DUT
    // The user's snippet had '#50 mispredict = 1'b1;'. Let's use a similar delay
    // from the point the branch instruction was presented.
    // If each instruction step is #10, 2-3 cycles later might be #20 or #30.
    // Let's use a delay that makes sense for your DUT's pipeline.
    #30; // Example: 3 cycles after branch fetch, misprediction is known.
    $display("[%0t] Asserting mispredict. Expected next PC was 0x100 (taken), actual should be 0x110 (not taken).", $time);
    mispredict = 1'b1; // Assert mispredict signal

    #5; // Hold mispredict for one cycle (or an appropriate duration for your DUT)
    mispredict = 1'b0; // De-assert mispredict

    // The DUT should now have flushed its pipeline and corrected its PC to the fall-through path (0x110).
    // Provide the instruction from the corrected PC.
    #5; // Allow time for PC correction and new fetch to begin
    $display("[%0t] Misprediction processed. Fetching from corrected PC.", $time);
    curr_PC     = 32'h00000110; // Corrected PC after mispredict (0x10C + 4)
    instruction = 32'h00100093; // ADDI x1, x0, 1 (example instruction after loop)

    #10;
    curr_PC     = 32'h00000114; // Next sequential instruction
    instruction = 32'h00200113; // ADDI x2, x0, 2

    #20; // Wait for a bit more
    $display("[%0t] Test sequence finished.", $time);
    $finish;