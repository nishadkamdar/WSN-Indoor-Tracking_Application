
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
uint16_t flagcnt;
uint16_t futurecnt;
uint8_t cntry;
task void sendsyncbs();
task void sendsyncsens();	
task void sendfwdmsg();
task void sendmsgbs();
task void sendfwdmsgquery();
task void sendmsgbsquery();
  
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
	
 printf("sending\n");
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
printf("i have stopped my radio\n");
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
		if(flagcnt == 1)
			{
				if (counter == futurecnt)
					{ 
						flagcnt = 0 ;
					if (rxtype1 == 555 || rxtype1 == 5050)
						{
					if(TOS_NODE_ID == 30 || TOS_NODE_ID == 80)
							{
								post sendmsgbsquery();
							    
							}  				
					else 
							{
								
							z = (x +1) * 10;
     								
 							post sendfwdmsgquery();
							}
						}
					}
			}
	else
		{	
			if (rxtype1 == 555 || rxtype1 == 5050)
				{
					printf("mobile detected");
					if(TOS_NODE_ID == 30 || TOS_NODE_ID == 80)
						{
								post sendmsgbs();
							    
						}  				
					else 
						{
								
							z = (x +1) * 10;
     								
 							post sendfwdmsg();
						}
				}
		
			else if (rxtype1 == 9090)
				{
					if (TOS_NODE_ID == 1234)
							{
								flagcnt = 1;
								futurecnt = rxcnt1;	
								
								
							}
				}
		}	
   }
	else if (len == sizeof(syncstruct)){
		syncstruct* syncpkt = (syncstruct*)payload;
			rxtype = syncpkt->type;
			rxnid = syncpkt->nodeid;
			rxcnt = syncpkt->counter;
		if (rxtype == 911){
			if (rxnid == 1234)
				{
				
			flag1 = 1;  //flag to stop the counter
		
				if (rxcnt!= counter)
				{
					counter = rxcnt;
					flag1 = 0;
					//post sendsyncbs();
				
				}			
				else {flag1 =0;
					//post sendsyncbs();
					}		
		
			
		
		post sendsyncsens();	
							
		
				}	
			else {printf("sensor count : %u and my cnt: %u\n", rxcnt, counter);}

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

printf("i m sending sync msg to sensor");
      syncpkt->type = 911;
      syncpkt->nodeid = TOS_NODE_ID;
      syncpkt->counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(syncstruct)) == SUCCESS) {
        busy = TRUE;
      }
    }		
  }
task void sendmsgbs()
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
task void sendmsgbsquery()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 9090;
      btrpkt->nodeid = rxnid1;
      btrpkt->counter = rxcnt1;
      if (call AMSend.send( 1234, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}
task void sendfwdmsgquery()
{

	if (!busy) {
      BlinkToRadioMsg * btrpkt = 
	(BlinkToRadioMsg *)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg )));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 9090;
      btrpkt->nodeid = rxnid1;
      btrpkt->counter = rxcnt1;
      if (call AMSend.send( z, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}


}
