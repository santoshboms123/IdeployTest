trigger roResourceUtilizationTrigger on Resource_Utilization__c (before insert, after insert, before update, after update, before delete, after delete, after unDelete) {
    roTriggerDispatcher.run(roTriggerDispatcher.handlerClass.roResourceUtilizationTriggerHandler);
}