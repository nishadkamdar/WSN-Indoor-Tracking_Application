#include <Timer.h>
#include "BlinkToRadio.h"
#include "printf.h"
module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {

  uint16_t counter;
  message_t pkt;
  bool busy = FALSE;
  uint16_t flag1 = 0;
  uint16_t rxnid;//sync node
  uint16_t rxcnt;
 uint16_t rxnid1;//nid of sensor node
  uint16_t rxcnt1;//cnt of sensor
  uint32_t rxtype1;
uint16_t rxtype;
uint16_t x;
  uint16_t y;
  uint16_t z;
uint8_t count2;
uint8_t cntry;

task void sendsyncbs();
task void sendsyncsens();	
task void sendfwdmsg();
//task void sendmsgbs();
task void sendfwdsens();
task void sendsensbs();
task void sendmsgdown();
task void sendmsgup();

 
  event void Boot.booted() {
    call Timer1.startPeriodic(100);
  }

event void Timer1.fired() 
		{	if (cntry <= 5)
			{

			call AMControl.start();
			cntry= cntry +1;
			}
			else if (cntry <=10) 
			{

			cntry= cntry +1;
			call AMControl.stop(); 	
			}	
			else 
			{
				cntry =0;
			}
		}


  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
x = TOS_NODE_ID / 10;
	y = TOS_NODE_ID % 10;
      call Timer0.startPeriodic(1000);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired() {
	if (flag1 == 0){    //checks whether it is the syncronization signal
    counter++;}
	else {counter = counter;}
     }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
	printf("nid is %u",TOS_NODE_ID);
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
                rxtype1 = btrpkt ->type;
		rxnid1 = btrpkt->nodeid;
                rxcnt1 = btrpkt -> counter;   
			
			if (rxtype1 == 600)
				{  
					printf("I SENSED THE MOBILE MOTE\n");
					if(TOS_NODE_ID == 40)
						{
						  	if(count2 < 10)
							{
								count2 = count2+1;	
								post sendmsgup();
								
								
							}
							else if(count2 > 10 && count2 < 20)
									{
										count2 = count2+1;
										post sendmsgdown();
										if (count2 >= 20)
											{count2 =0;
											}		
									}								
							
							    
						}  				
					else if (TOS_NODE_ID == 50){post sendsensbs();}//send directly sensed to bs

					else 
						{
								
							z = (x +1) * 10;
     								
 							post sendfwdsens();//fwd directly sensed to ch
						}
				}
		else if(rxtype1 == 5050 || 9090)
				{		
					z = (x +1) * 10;
						post sendfwdmsg();//fwd rxd msg from clusterhead




				}
		

				
			
   }
	else if (len == sizeof(syncstruct)){
		syncstruct* syncpkt = (syncstruct*)payload;
			rxtype = syncpkt->type;
			rxnid = syncpkt->nodeid;
		if (rxtype == 911){
			if (rxnid == 1234)
				{
				
			flag1 = 1;  //flag to stop the counter
		rxcnt = syncpkt->counter;
				if (rxcnt!= counter)
				{
					counter = rxcnt ;
					flag1 = 0;
				
				}			
				else {flag1 =0;
					}		
		
			
		post sendsyncbs();
		post sendsyncsens();				
		
				}	
			//else if(rxnid == )

				}
							
		}
    return msg;
  }


task void sendsyncbs()
{

	if (!busy) {
      syncstruct * syncpkt = 
	(syncstruct *)(call Packet.getPayload(&pkt, sizeof(syncstruct )));
      if (syncpkt == NULL) {
	return;
      }
      syncpkt->type = 911;
      syncpkt->nodeid = TOS_NODE_ID;
      syncpkt->counter = counter;
      if (call AMSend.send(1234, 
          &pkt, sizeof(syncstruct)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}

task void sendsyncsens()
{

	 if (!busy) {
      syncstruct * syncpkt = 
	(syncstruct *)(call Packet.getPayload(&pkt, sizeof(syncstruct )));
      if (syncpkt == NULL) {
	return;
      }
      syncpkt->type = 911;
      syncpkt->nodeid = TOS_NODE_ID;
      syncpkt->counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(syncstruct)) == SUCCESS) {
        busy = TRUE;
      }
    }		
  }
task void sendfwdtobs()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 5050;
      btrpkt->nodeid = rxnid1;
      btrpkt->counter = rxcnt1;
      if (call AMSend.send( 1234, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}
task void sendfwdmsg()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 5050;
      btrpkt->nodeid = rxnid1;
      btrpkt->counter = rxcnt1;
      if (call AMSend.send( z, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}
task void sendmsgup()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 555;
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter;
      if (call AMSend.send( 10, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}
task void sendmsgdown()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 555;
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter;
      if (call AMSend.send( 60, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}
task void sendsensbs()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 555;
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter;
      if (call AMSend.send( 1234, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}

task void sendfwdsens()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 555;
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter;
      if (call AMSend.send( z, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}

}
