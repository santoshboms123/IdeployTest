trigger roResourceAvailableHoursTrigger on Resource_Available_Hours__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    roTriggerDispatcher.run(roTriggerDispatcher.handlerClass.roResourceAvailableHoursTriggerHandler);
}