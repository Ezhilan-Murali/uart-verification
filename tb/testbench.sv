class transaction;
  typedef enum bit{write=0, read=1}opr_type;
  
  bit rx, newd, tx, donetx, donerx;
 rand bit [7:0] dintx;
  randc opr_type opr;
  bit [7:0] doutrx;
  
  function transaction copy();
    copy = new();
    copy.rx = this.rx;
    copy.newd = this.newd;
    copy.tx = this.tx;
    copy.donetx = this.donetx;
    copy.donerx = this.donerx;
    copy.dintx = this.dintx;
    copy.doutrx = this.doutrx;
    copy.opr = this.opr;
  endfunction
  
endclass

class generator;
  transaction tr;
  mailbox #(transaction) mbx_gd;
  //mailbox #(transaction) mbx_gs;
  
  event next_drv;
  event next_sco;
  event done;
  
  int count = 0;
  
  function new(mailbox #(transaction) mbx_gd );
    
    this.mbx_gd = mbx_gd;
    tr = new();
    //this.mbx_gs = mbx_gs;
  endfunction
  
  task run();
    repeat(count) begin
      //tr = new();
      assert(tr.randomize) else $error("Randomization failed");
      mbx_gd.put(tr.copy);
      $display("[GEN]: operation: %0s, Dintx: %0b", tr.opr.name(), tr.dintx);
      @(next_drv);
      @(next_sco);
      
    end
    ->done;
  endtask
  
  
endclass

class driver;
  virtual uart_if vif;
  transaction tr_d;
  
    mailbox #(transaction) mbx_gd;
  mailbox #(bit [7:0] ) mbx_ds;
  
  event next_drv;
  
  bit [7:0] dout_drv;
  

  
  
  
  function new(  mailbox #(transaction) mbx_gd, mailbox #(bit [7:0] ) mbx_ds);
  this.mbx_gd = mbx_gd;
  this.mbx_ds=mbx_ds;
  endfunction
  
  task reset();
    	vif.rst<=1;
    	vif.rx<=1;
    	vif.newd<=0;;
    	vif.dintx<=0;
    repeat(5) @(posedge vif.uclktx);
    vif.rst<=0;
    $display("Reset done");
    $display("---------------------");

  endtask
  
  task run();
    forever begin
      mbx_gd.get(tr_d);
      
      if(tr_d.opr==0) begin  //write - transmission tx
        @(posedge vif.uclktx);
        vif.rst<=0;
        vif.newd<=1;
        vif.rx<=1;
        vif.dintx<=tr_d.dintx;
        //dout_drv<=vif.dintx;
        @(posedge vif.uclktx);
        vif.newd<=0;
        mbx_ds.put(tr_d.dintx);
        $display("[Drv]: operation: %0s, Dintx: %0b", tr_d.opr.name(), tr_d.dintx);
        wait(vif.donetx==1);
        
        ->next_drv;
        
      end
      
      else if(tr_d.opr==1) begin //read - recieve rx
        @(posedge vif.uclkrx);
        vif.rst<=0;
        vif.rx<=0;
        vif.newd<=0;
        for(int i = 0; i<=7; i++) begin
          @(posedge vif.uclkrx);
          vif.rx=$urandom;
          dout_drv[i]=vif.rx;
        end
        
        mbx_ds.put(dout_drv);
        
        $display("[Drv]: operation: %0s, rxdata: %0b", tr_d.opr.name(), dout_drv);
        //@(posedge vif.uclk);
        
        //@(posedge vif.uclk);
        wait(vif.donerx==1);
        vif.rx <= 1;
        ->next_drv;
      end
        
    end
    
  endtask
 
endclass

class monitor;
  
  transaction tr_mon;
  mailbox #(bit [7:0] ) mbx_ms;
  
  bit [7:0] dout_mon;
  bit [7:0] rrx;
  
  virtual uart_if vif;
  
  
  function new(mailbox #(bit [7:0]) mbx_ms);
    tr_mon = new();
    this.mbx_ms=mbx_ms;
  endfunction
  
  
  task run();
    forever begin
      @(posedge vif.uclktx);
      //repeat(1) @(posedge vif.uclk);
      if((vif.newd== 1'b1) && (vif.rx == 1'b1)) begin
        //wait(vif.cb.donetx);
        @(posedge vif.uclktx);
        for(int i=0; i<=7; i++) begin
        @(posedge vif.uclktx);
          dout_mon[i]<=vif.tx;
        end
        $display("[MON]: TX detected. Data: %b", dout_mon);
        
        @(posedge vif.uclktx);
        
        mbx_ms.put(dout_mon);
      end
      
      else if((vif.newd==0)&&(vif.rx==0)) begin
        wait(vif.donerx==1);
        //@(posedge vif.uclk);
        //wait(vif.donerx==1);
        rrx<=vif.doutrx;
        //@(posedge vif.uclk);
        $display("[MON_rx]: rx: %0b", rrx);
        @(posedge vif.uclktx);
        mbx_ms.put(rrx);
      end
      //mbx_ms.put(dout_mon);
    end
  endtask
endclass
      

      
class scoreboard;
  
  //transaction tr_sco;
  
  bit [7:0] dout_drv;
  bit [7:0] dout_mon;
  
  event next_sco;
  
  mailbox #(bit [7:0]) mbx_ms;
  mailbox #(bit [7:0]) mbx_ds;
  
  function new(  mailbox #(bit [7:0]) mbx_ms, mailbox #(bit [7:0]) mbx_ds);
    this.mbx_ms=mbx_ms;
    this.mbx_ds=mbx_ds;
  endfunction
  
  task run();
    forever begin
      mbx_ms.get(dout_mon);
      mbx_ds.get(dout_drv);
      if(dout_mon == dout_drv) begin
        $display("[SCO]: Drv: %0b, Mon: %0b", dout_drv, dout_mon);
        $display("[SCO]: PASSED");
        $display("----------------------------");
      end
      else begin
        $display("[SCO]: Drv: %0b, Mon: %0b", dout_drv, dout_mon);
        $display("[SCO]: FAILED");
        
      end
      $display("----------------------------");
      ->next_sco;
    end
  endtask
endclass

//////////////////////////- from here     
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  event next_sco, next_drv;
  event done;
  
  mailbox #(bit [7:0]) mbx_ms;
  mailbox #(bit [7:0]) mbx_ds;
  mailbox #(transaction) mbx_gd;
  
  virtual uart_if vif;
  
  function new(virtual uart_if vif);
    mbx_ms=new();
    mbx_ds=new();
    mbx_gd=new();
    
    gen=new(mbx_gd);
    drv=new(mbx_gd, mbx_ds);
    mon=new(mbx_ms);
    sco=new(mbx_ms, mbx_ds);
    
    gen.next_drv=next_drv;
    drv.next_drv=next_drv;
    
    gen.next_sco=next_sco;
    sco.next_sco=next_sco;
    
    this.vif=vif;
    drv.vif=this.vif;
    mon.vif=this.vif;
    
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask
  
  
  task post_test();
    wait(gen.done.triggered);
    //#50;
    $display("Test Completed");
    $finish();
  endtask
  
  task run();
    pre_test();
    
      test();
      post_test();
    
  endtask
endclass

module tb;
  uart_if vif();
  top #(1000000, 9600) dut(vif.clk, vif.rst, vif.rx, vif.newd, vif.dintx, vif.donerx, vif.doutrx, vif.donetx, vif.tx);
  
  initial begin
    vif.clk<=0;
  end
  
  always #10 vif.clk<=~vif.clk;
  
  environment env;
  
  initial begin
    env=new(vif);
    env.gen.count=5;
    env.run();
  end
  
  initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
  end
  
  assign vif.uclktx = dut.utx.uclk;
  assign vif.uclkrx = dut.urx.uclk;
  
endmodule