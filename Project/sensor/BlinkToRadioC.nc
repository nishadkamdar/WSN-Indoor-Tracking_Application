
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
  uint16_t rxnid;
  uint16_t rxcnt;
 uint16_t rxtype;
uint16_t rxnid1;
uint8_t cntry;
  
 uint16_t rxtype1;
  
  uint16_t x;
  uint16_t y;
uint16_t z;
task void sendsyncch();
task void sendsigch();	
 
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
	z = x * 10;
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
    counter++;
	printf("cnt is %u\n", counter);		}
	else {counter = counter;}
     }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
	//printf("nid is %u",TOS_NODE_ID);
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
			rxtype1 = btrpkt->type;
			rxnid1 = btrpkt->nodeid;
	                
		if (rxtype1 == 600)
			{
				post sendsigch();
  				
			}


   }
	else if (len == sizeof(syncstruct)){
		syncstruct* syncpkt = (syncstruct*)payload;
			rxtype = syncpkt->type;
			rxnid = syncpkt->nodeid;
		if (rxtype == 911){
			if (rxnid == z)
				{
				
			flag1 = 1;  //flag to stop the counter
		rxcnt = syncpkt->counter;
				if (rxcnt!= counter)
				{
					counter = rxcnt;
					flag1 = 0;
					printf("i rxd sync msg cnt is %u\n", rxcnt);
					
				}			
				else {flag1 =0;
					}		
		
			
		post sendsyncch();
					
		
				}	
			
				}
							
		}
    return msg;
  }


task void sendsyncch()
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
      if (call AMSend.send( z, 
          &pkt, sizeof(syncstruct)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}

task void sendsigch()
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
