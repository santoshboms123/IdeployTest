trigger roResourceOptimizerSecurityTrigger on Resource_Optimizer_Security__c (Before insert,After insert,Before update, Before delete) {
    roTriggerDispatcher.run(roTriggerDispatcher.handlerClass.roResourceOptimizeSecurityTriggerHandler);
}