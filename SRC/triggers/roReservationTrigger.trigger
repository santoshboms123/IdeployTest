trigger roReservationTrigger on Reservation__c (before insert,after update) {
    roTriggerDispatcher.run(roTriggerDispatcher.handlerClass.roReservationTriggerHandler);
}