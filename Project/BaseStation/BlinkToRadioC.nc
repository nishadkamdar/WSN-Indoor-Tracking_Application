
#include <Timer.h>
#include "BlinkToRadio.h"
#include "printf.h"
module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
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
  task void sendsync();
  task void sendquery();	
  uint8_t flag1;
  uint8_t flag2;
  uint8_t flag3;
  uint8_t flag4;
  uint16_t rxchid;
  uint16_t synccnt;
uint16_t rxcnt1;
uint16_t rxnid1;
uint32_t rxtype1;

  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer0.startPeriodic(synctimer);
      call Timer1.startPeriodic(1000);
      call Timer2.startPeriodic(15000);
      
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired() {
    post sendsync();
    
  }
event void Timer1.fired() {
//if(flag1 == flag2 == flag3 == flag4 == 0;)
    counter++;
//else
  //  counter	
  }
  event void Timer2.fired() {
    post sendquery();
    
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
		rxcnt1 = btrpkt->counter;
		rxnid1 = btrpkt->nodeid;
 		rxtype1 = btrpkt->type;
			

printf("message type: %ld\t Nodeid : %u\t Counter : %u\n", rxtype1, rxnid1, rxcnt1);
    }
 else if(len == sizeof(syncstruct)){
	syncstruct* syncpkt = (syncstruct*)payload;
		rxchid = syncpkt->nodeid;
		synccnt = syncpkt->counter;
	/*if(rxchid == 100)
		{
		if((synccnt - counter) > 2)
			sendsync();
		else
			flag1 = 0;
		}
	if(rxchid == 200)
		{
		if((synccnt - counter) > 2)
			sendsync();
		else
			flag2 = 0;
		}
	if(rxchid == 300)
		{
		if((synccnt - counter) > 2)
			sendsync();
		else
			flag3 = 0;
		}
	if(rxchid == 400)
		{
		if((synccnt - counter) > 2)
			sendsync();
		else
			flag4 = 0;
		}*/
	printf("  nodeid is %u  counter is %u mycnt is%u\n", rxchid,synccnt,counter);
	}

    return msg;
  }
	
task void sendsync()
{

	flag1 = 1;
        flag2 = 1;
        flag3 = 1;
        flag4 = 1;
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

task void sendquery()
{

	if (!busy) {
      BlinkToRadioMsg* btrpkt  = 
	(BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
	return;
      }
      btrpkt->type = 9090;
      btrpkt->nodeid = TOS_NODE_ID;
      btrpkt->counter = counter + 100;
      if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        busy = TRUE;
	      }
	    }		
			
	}

}
